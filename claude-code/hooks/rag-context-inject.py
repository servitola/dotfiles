#!/usr/bin/env python3
"""UserPromptSubmit hook: auto-retrieve local RAG context for lookup prompts.

Companion to the manual `rag context` rule in ~/.claude/CLAUDE.md. That rule
relies on the model remembering to query the `dotfiles` collection. This hook
makes retrieval automatic AND multi-collection: it routes by cwd to the right
Qdrant collection and injects retrieved chunks as additionalContext.

Design — cheap, dependency-light (stdlib only), and FAILS OPEN ALWAYS:
- Lightweight heuristic decides if the prompt is a knowledge/lookup question.
  Pure coding-action prompts, greetings, and short/ambiguous prompts are
  skipped (err toward NOT injecting to avoid noise).
- cwd -> collection: ~/projects/<X> maps to the matching collection;
  ~/projects/Spotware -> spotware-code; home / dotfiles -> dotfiles.
- Runs `rag context` with a short timeout and small top-k.
- On ANY problem (rag/LiteLLM/Qdrant down, timeout, error, no matches,
  disabled via env) -> exit 0, inject nothing. Never blocks or delays
  meaningfully, never emits a disruptive error.

Disable with: RAG_INJECT_DISABLE=1
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

RAG_BIN = os.path.expanduser("~/projects/dotfiles/zsh/bin/rag")
PROJECTS = os.path.expanduser("~/projects")
TIMEOUT_S = 6        # hard cap on the rag call
TOP_K = "4"
MIN_WORDS = 4        # below this -> too short/ambiguous, skip
MAX_PROMPT_CHARS = 600   # very long prompts are usually pasted code/logs, skip

# Relevance gate. We query in `vector` mode so the printed `score=` is a real
# cosine similarity (hybrid mode prints RRF rank scores ~0.5 that DON'T
# discriminate relevance). Calibrated on real queries: genuine env/project
# lookups score ~0.34-0.56, irrelevant/chatty prompts ~0.17-0.24. 0.30 sits in
# the gap with margin on both sides. If the TOP source is below this -> skip.
MIN_SCORE = 0.30
SCORE_RE = re.compile(r"\bscore=([0-9]*\.?[0-9]+)")

# cwd basename under ~/projects -> collection. Anything not listed and not a
# known project falls back to `dotfiles` (home-level / personal env questions).
DIR_TO_COLLECTION = {
    "dotfiles": "dotfiles",
    "services": "services",
    "serho": "serho",
    "sphere": "sphere",
    "glasswings": "glasswings",
    "workbot2": "workbot2",
    "spotwarevpn": "spotwarevpn",
    "workbot-docs": "spotware-dev-docs",
    "Spotware": "spotware-code",
}

# Interrogative openers: a genuine question typically STARTS with one of
# these (any language). Used as the primary lookup signal alongside a trailing
# "?". Deliberately narrower than a bag-of-words match anywhere in the text —
# conversational prompts often contain "what/how/где" mid-sentence without
# being a knowledge question.
INTERROGATIVE_START_RE = re.compile(
    r"^\s*(how|what|what's|whats|where|where's|wheres|why|which|when|who|"
    r"whose|whom|"
    r"does|do|did|is|are|can|could|should|would|will|has|have|"
    r"explain|describe|tell\s+me|remind\s+me|"
    r"как|что|чем|где|куда|откуда|почему|зачем|какой|какая|какие|какое|"
    r"каким|когда|кто|чей|чья|чьи|"
    r"объясни|расскажи|напомни|подскажи)\b",
    re.IGNORECASE,
)

# Phrases that mark a knowledge/lookup question about how something is set up.
# Matched anywhere, but only as a SECONDARY gate (the prompt must still be a
# single-clause non-imperative — see should_retrieve).
LOOKUP_PHRASE_RE = re.compile(
    r"\b(configured|configure[d]?|set\s*up|setup|wired|"
    r"how\s+(?:does|do|is|are)|where\s+(?:is|are|does)|"
    r"где\s+настро|как\s+настро|настроен[оаы]?|"
    r"что\s+делает|что\s+такое)\b",
    re.IGNORECASE,
)

# Pure coding-action / imperative prompts that don't benefit from retrieval.
# If the prompt STARTS with one of these verbs, skip (unless it also clearly
# asks a question, handled below).
ACTION_PREFIX_RE = re.compile(
    r"^\s*(rename|refactor|fix|add|remove|delete|create|implement|write|"
    r"update|change|edit|move|rebase|merge|commit|push|run|build|test|"
    r"install|deploy|format|lint|optimi[sz]e|replace|insert|append|"
    r"generate|make\s+a|build\s+a|"
    r"переименуй|отрефактори|исправь|добавь|удали|создай|реализуй|напиши|"
    r"обнови|измени|поправь|перенеси|закоммить|запусти|собери|"
    r"задеплой|отформатируй|замени)\b",
    re.IGNORECASE,
)

# Greetings / chit-chat / acks — never retrieve.
TRIVIAL_RE = re.compile(
    r"^\s*(hi|hey|hello|yo|thanks|thank\s+you|thx|ok|okay|yes|no|yep|nope|"
    r"sure|cool|nice|good|great|continue|go\s+on|next|stop|"
    r"привет|спасибо|спс|ок|окей|да|нет|ага|давай|продолжай|дальше|стоп)"
    r"[\s!.,]*$",
    re.IGNORECASE,
)


def collection_for_cwd(cwd):
    """Map cwd to a collection. Returns None if outside ~/projects and not home."""
    if not cwd:
        return "dotfiles"
    cwd = os.path.realpath(os.path.expanduser(cwd))
    projects = os.path.realpath(PROJECTS)
    home = os.path.realpath(os.path.expanduser("~"))

    if cwd == projects or cwd.startswith(projects + os.sep):
        rel = os.path.relpath(cwd, projects)
        top = rel.split(os.sep)[0]
        return DIR_TO_COLLECTION.get(top, "dotfiles")
    # Home directory or anything else -> personal-env questions -> dotfiles.
    if cwd == home or cwd.startswith(home + os.sep):
        return "dotfiles"
    return "dotfiles"


def _sentences(p):
    """Split into rough sentence/clause units for multi-clause detection."""
    return [s for s in re.split(r"[.!?\n]+", p) if s.strip()]


def should_retrieve(prompt):
    """Lightweight heuristic. Err HARD toward NOT injecting.

    A prompt qualifies only if it reads like a genuine knowledge question:
      - ends with '?', OR
      - starts with an interrogative word, OR
      - is a single clause containing an explicit lookup phrase.
    Multi-sentence prompts and imperatives (even if they contain a lookup-ish
    word somewhere) are treated as conversational/instructional -> skip.
    """
    p = prompt.strip()
    if not p:
        return False
    if len(p) > MAX_PROMPT_CHARS:
        return False
    if TRIVIAL_RE.match(p):
        return False
    if len(p.split()) < MIN_WORDS:
        return False

    ends_q = p.rstrip().endswith("?")
    starts_interrogative = bool(INTERROGATIVE_START_RE.match(p))

    # A trailing '?' is the strongest single signal — but a multi-sentence
    # blob that merely happens to end in '?' (e.g. an imperative followed by a
    # rhetorical "ok?") is conversational. Require it to ALSO look like a
    # question (interrogative opener) when there are multiple clauses.
    sents = _sentences(p)
    multi_clause = len(sents) > 1

    # Imperative coding/action prompts never retrieve, regardless of a stray
    # lookup word or trailing '?'.
    if ACTION_PREFIX_RE.match(p):
        return False

    if ends_q and not multi_clause:
        return True
    if starts_interrogative:
        return True
    if ends_q and multi_clause:
        # Multi-sentence and ends with '?': only if the LAST clause itself is a
        # question (starts interrogative or the question is the standalone tail).
        last = sents[-1].strip()
        if INTERROGATIVE_START_RE.match(last) or LOOKUP_PHRASE_RE.search(last):
            return True
        return False

    # No question mark, no interrogative opener: require a single-clause prompt
    # with an explicit lookup phrase. Multi-clause -> conversational -> skip.
    if multi_clause:
        return False
    return bool(LOOKUP_PHRASE_RE.search(p))


def run_rag(collection, prompt):
    # `--mode vector` so the printed score= is a real cosine similarity we can
    # gate on (hybrid mode emits non-discriminating RRF rank scores).
    try:
        proc = subprocess.run(
            [RAG_BIN, "context", "--collection", collection,
             "--mode", "vector", "--top-k", TOP_K, prompt],
            capture_output=True, text=True, timeout=TIMEOUT_S,
        )
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    out = (proc.stdout or "").strip()
    # `rag context` prints `[Source N] path=...` lines on a hit. No hit -> empty
    # or no Source markers -> inject nothing.
    if not out or "[Source" not in out:
        return None
    # Relevance gate: the TOP source's score must clear MIN_SCORE. If we can't
    # find any score (format change), fail open by NOT injecting (the score is
    # our only relevance signal here, and we err toward silence).
    m = SCORE_RE.search(out)
    if not m:
        return None
    try:
        top_score = float(m.group(1))
    except ValueError:
        return None
    if top_score < MIN_SCORE:
        return None
    return out


def _session_id(data):
    sid = data.get("session_id") or data.get("sessionId") or ""
    return re.sub(r"[^A-Za-z0-9_.-]", "", str(sid))[:64]


def _dedup_paths(out):
    """Stable fingerprint of the injected source paths."""
    paths = re.findall(r"\bpath=(\S+)", out)
    return hashlib.sha256("\n".join(paths).encode()).hexdigest() if paths else ""


def already_injected(session_id, fingerprint):
    """Per-session dedup: True if the SAME paths were injected last time.

    Fail-open: any filesystem error -> treat as not-a-duplicate (inject).
    Keyed by session id; no-op (returns False) if no session id available.
    """
    if not session_id or not fingerprint:
        return False
    path = os.path.join(tempfile.gettempdir(),
                        f"rag-inject-last-{session_id}")
    try:
        with open(path) as fh:
            last = fh.read().strip()
    except Exception:
        last = ""
    if last == fingerprint:
        return True
    try:
        with open(path, "w") as fh:
            fh.write(fingerprint)
    except Exception:
        pass
    return False


def main():
    if os.environ.get("RAG_INJECT_DISABLE"):
        return
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    prompt = data.get("prompt") or ""
    if not isinstance(prompt, str) or not should_retrieve(prompt):
        return

    cwd = data.get("cwd") or os.getcwd()
    collection = collection_for_cwd(cwd)
    if not collection:
        return

    if not os.path.isfile(RAG_BIN):
        return

    context = run_rag(collection, prompt)
    if not context:
        return

    # Per-session dedup: skip if these exact source paths were just injected.
    if already_injected(_session_id(data), _dedup_paths(context)):
        return

    header = (
        f"Auto-retrieved local knowledge from the `{collection}` RAG collection "
        f"(Qdrant) for this prompt. Treat as a starting point; each chunk lists "
        f"its `path=` — cite or open the file for full detail. Ignore if "
        f"irrelevant.\n\n"
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": header + context,
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
