#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "google-api-python-client>=2.100",
#   "google-auth>=2.23",
#   "google-auth-oauthlib>=1.1",
#   "markdown>=3.5",
# ]
# ///
"""
gdoc — thin CLI over Google Docs + Drive for the comment-driven editing loop.

Auth model: the user's own Google account via an existing OAuth *desktop* client
(GOOGLE_CLIENT_ID / GOOGLE_API_SECRET from ~/.config/openai_key.sh). Docs are
created in the user's Drive; the user comments naturally; the agent reads the
comments (with their quoted anchor text) and edits the doc in place.

Scopes (minimal): documents + drive.file (only files this app creates/opens).

Commands:
  auth                                     one-time browser consent, saves token
  create <file> [--title T] [--share EMAIL]  convert file -> native Google Doc
  share <doc_id> --email E [--role writer|commenter|reader]  grant access
  comments <doc_id> [--all] [--raw]        list comments (+ quoted anchor text)
  get <doc_id> [--json]                    dump current doc text
  replace <doc_id> --find F --replace R    replaceAllText batchUpdate
  resolve <doc_id> --comment-id ID [--reply TEXT]   reply + resolve a comment
  export <doc_id> --format docx|md|txt|pdf|html|odt|rtf [-o PATH]

All commands print JSON on stdout (except `get` default and `export`).
"""
import argparse
import json
import os
import sys
from io import BytesIO
from pathlib import Path

TOKEN_PATH = Path(os.path.expanduser("~/.config/gdoc-review/token.json"))
SCOPES = [
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/drive.file",
]
GDOC_MIME = "application/vnd.google-apps.document"

# ext -> mimetype we upload the source AS (Drive converts to a native Doc)
UPLOAD_MIME = {
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".doc": "application/msword",
    ".odt": "application/vnd.oasis.opendocument.text",
    ".rtf": "application/rtf",
    ".html": "text/html",
    ".htm": "text/html",
    ".txt": "text/plain",
    ".pdf": "application/pdf",  # Drive OCR-converts to an editable Doc
}
# --format -> Drive export mimetype
EXPORT_MIME = {
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "odt": "application/vnd.oasis.opendocument.text",
    "pdf": "application/pdf",
    "txt": "text/plain",
    "html": "text/html",
    "md": "text/markdown",
    "rtf": "application/rtf",
}


def die(msg, code=1):
    print(json.dumps({"error": msg}), file=sys.stderr)
    sys.exit(code)


def client_config():
    cid = os.environ.get("GOOGLE_CLIENT_ID")
    secret = os.environ.get("GOOGLE_API_SECRET")
    if not cid or not secret:
        die("GOOGLE_CLIENT_ID / GOOGLE_API_SECRET not set. "
            "Run: source ~/.config/openai_key.sh")
    return {
        "installed": {
            "client_id": cid,
            "client_secret": secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost"],
        }
    }


def do_auth():
    from google_auth_oauthlib.flow import InstalledAppFlow

    flow = InstalledAppFlow.from_client_config(client_config(), SCOPES)
    creds = flow.run_local_server(port=0, open_browser=True,
                                  authorization_prompt_message=
                                  "Открой ссылку и разреши доступ:\n{url}")
    TOKEN_PATH.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_PATH.write_text(creds.to_json())
    os.chmod(TOKEN_PATH, 0o600)
    print(json.dumps({"ok": True, "token": str(TOKEN_PATH),
                      "scopes": list(creds.scopes or SCOPES)}))


def load_creds():
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request

    if not TOKEN_PATH.exists():
        die("Not authenticated. Run:  gdoc auth   (one-time browser consent)")
    creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)
    if not creds.valid:
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            TOKEN_PATH.write_text(creds.to_json())
        else:
            die("Token invalid/expired without refresh. Re-run: gdoc auth")
    return creds


def services():
    from googleapiclient.discovery import build

    creds = load_creds()
    docs = build("docs", "v1", credentials=creds, cache_discovery=False)
    drive = build("drive", "v3", credentials=creds, cache_discovery=False)
    return docs, drive


# ---------------------------------------------------------------- share
def _share(drive, doc_id, email, role, notify):
    perm = {"type": "user", "role": role, "emailAddress": email}
    r = drive.permissions().create(
        fileId=doc_id, body=perm, sendNotificationEmail=notify,
        fields="id,role,emailAddress").execute()
    return {"permissionId": r["id"], "role": r.get("role", role),
            "email": r.get("emailAddress", email)}


def _share_anyone(drive, doc_id, role):
    # link sharing: anyone with the link. Lets non-Google-account reviewers
    # (e.g. a Yandex email) comment anonymously — no sign-in required.
    r = drive.permissions().create(
        fileId=doc_id, body={"type": "anyone", "role": role},
        fields="id,role").execute()
    return {"permissionId": r["id"], "role": r.get("role", role),
            "type": "anyone"}


def do_share(doc_id, email, role, notify, anyone):
    _, drive = services()
    res = {"ok": True}
    if email:
        res["user"] = _share(drive, doc_id, email, role, notify)
    if anyone:
        res["link"] = _share_anyone(drive, doc_id, anyone)
    if not email and not anyone:
        die("share: pass --email and/or --anyone")
    print(json.dumps(res, ensure_ascii=False))


# ---------------------------------------------------------------- create
def do_create(path, title, share, role, notify, anyone):
    from googleapiclient.http import MediaIoBaseUpload, MediaFileUpload

    p = Path(path).expanduser()
    if not p.exists():
        die(f"File not found: {p}")
    ext = p.suffix.lower()
    _, drive = services()
    # auto-share: explicit flags win, else env (GDOC_SHARE_EMAIL / GDOC_SHARE_ANYONE)
    share = share or os.environ.get("GDOC_SHARE_EMAIL")
    anyone = anyone or os.environ.get("GDOC_SHARE_ANYONE")

    body = {"name": title or p.stem, "mimeType": GDOC_MIME}

    if ext in (".md", ".markdown"):
        import markdown
        html = markdown.markdown(p.read_text(encoding="utf-8"),
                                 extensions=["extra", "sane_lists", "nl2br"])
        html = f"<html><body>{html}</body></html>"
        media = MediaIoBaseUpload(BytesIO(html.encode("utf-8")),
                                  mimetype="text/html", resumable=False)
    elif ext in UPLOAD_MIME:
        media = MediaFileUpload(str(p), mimetype=UPLOAD_MIME[ext],
                                resumable=False)
    else:
        # unknown -> treat as plain text
        media = MediaIoBaseUpload(BytesIO(p.read_bytes()),
                                  mimetype="text/plain", resumable=False)

    f = drive.files().create(body=body, media_body=media,
                             fields="id,name").execute()
    doc_id = f["id"]
    out = {
        "id": doc_id,
        "name": f["name"],
        "link": f"https://docs.google.com/document/d/{doc_id}/edit",
    }
    if share:
        out["shared"] = _share(drive, doc_id, share, role, notify)
    if anyone:
        out["shared_link"] = _share_anyone(drive, doc_id, anyone)
    print(json.dumps(out, ensure_ascii=False))


# ---------------------------------------------------------------- comments
def do_comments(doc_id, show_all, raw):
    _, drive = services()
    fields = ("comments(id,content,quotedFileContent/value,resolved,"
              "author/displayName,createdTime,"
              "replies(content,author/displayName,action)),nextPageToken")
    items, token = [], None
    while True:
        resp = drive.comments().list(
            fileId=doc_id, fields=fields, pageSize=100,
            includeDeleted=False, pageToken=token).execute()
        items.extend(resp.get("comments", []))
        token = resp.get("nextPageToken")
        if not token:
            break

    if raw:
        print(json.dumps(items, ensure_ascii=False, indent=2))
        return

    out = []
    for c in items:
        if not show_all and c.get("resolved"):
            continue
        out.append({
            "id": c["id"],
            "author": c.get("author", {}).get("displayName", "?"),
            "quote": (c.get("quotedFileContent") or {}).get("value", ""),
            "comment": c.get("content", ""),
            "resolved": bool(c.get("resolved")),
            "replies": [{"author": r.get("author", {}).get("displayName", "?"),
                         "text": r.get("content", ""),
                         "action": r.get("action")}
                        for r in c.get("replies", [])],
        })
    print(json.dumps({"count": len(out), "comments": out},
                     ensure_ascii=False, indent=2))


# ---------------------------------------------------------------- get
def _doc_text(docs, doc_id):
    doc = docs.documents().get(documentId=doc_id).execute()
    chunks = []
    for el in doc.get("body", {}).get("content", []):
        para = el.get("paragraph")
        if not para:
            continue
        for pe in para.get("elements", []):
            tr = pe.get("textRun")
            if tr:
                chunks.append(tr.get("content", ""))
    return doc, "".join(chunks)


def do_get(doc_id, as_json):
    docs, _ = services()
    doc, text = _doc_text(docs, doc_id)
    if as_json:
        print(json.dumps({"id": doc_id, "title": doc.get("title"),
                          "text": text}, ensure_ascii=False))
    else:
        sys.stdout.write(text)


# ---------------------------------------------------------------- replace
def do_replace(doc_id, find, replace, match_case):
    docs, _ = services()
    req = [{"replaceAllText": {
        "containsText": {"text": find, "matchCase": match_case},
        "replaceText": replace,
    }}]
    res = docs.documents().batchUpdate(
        documentId=doc_id, body={"requests": req}).execute()
    changed = 0
    for r in res.get("replies", []):
        changed += r.get("replaceAllText", {}).get("occurrencesChanged", 0)
    print(json.dumps({"occurrencesChanged": changed}))
    if changed == 0:
        sys.exit(2)  # signal "anchor text not found" to the caller


# ---------------------------------------------------------------- resolve
def do_resolve(doc_id, comment_id, reply):
    _, drive = services()
    body = {"content": reply or "Готово ✅", "action": "resolve"}
    r = drive.replies().create(
        fileId=doc_id, commentId=comment_id, body=body,
        fields="id,action,content").execute()
    print(json.dumps({"ok": True, "commentId": comment_id,
                      "action": r.get("action")}, ensure_ascii=False))


# ---------------------------------------------------------------- export
def do_export(doc_id, fmt, out):
    from googleapiclient.http import MediaIoBaseDownload

    if fmt not in EXPORT_MIME:
        die(f"Unknown format '{fmt}'. Use: {', '.join(EXPORT_MIME)}")
    _, drive = services()
    req = drive.files().export_media(fileId=doc_id, mimeType=EXPORT_MIME[fmt])
    buf = BytesIO()
    dl = MediaIoBaseDownload(buf, req)
    done = False
    while not done:
        _, done = dl.next_chunk()
    out_path = Path(out).expanduser() if out else Path(f"{doc_id}.{fmt}")
    out_path.write_bytes(buf.getvalue())
    print(json.dumps({"ok": True, "path": str(out_path),
                      "bytes": out_path.stat().st_size}))


def main():
    ap = argparse.ArgumentParser(prog="gdoc")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("auth")

    c = sub.add_parser("create")
    c.add_argument("file")
    c.add_argument("--title")
    c.add_argument("--share", help="email to share with (or set GDOC_SHARE_EMAIL)")
    c.add_argument("--anyone", nargs="?", const="commenter",
                   choices=["writer", "commenter", "reader"],
                   help="link-share: anyone with the link (default commenter). "
                        "Use for reviewers without a Google account. "
                        "Env: GDOC_SHARE_ANYONE")
    c.add_argument("--role", default="writer",
                   choices=["writer", "commenter", "reader"],
                   help="role for --share (email invite)")
    c.add_argument("--notify", action="store_true",
                   help="send Google's share-notification email")

    c = sub.add_parser("share")
    c.add_argument("doc_id")
    c.add_argument("--email")
    c.add_argument("--anyone", nargs="?", const="commenter",
                   choices=["writer", "commenter", "reader"])
    c.add_argument("--role", default="writer",
                   choices=["writer", "commenter", "reader"])
    c.add_argument("--notify", action="store_true")

    c = sub.add_parser("comments")
    c.add_argument("doc_id")
    c.add_argument("--all", action="store_true", help="include resolved")
    c.add_argument("--raw", action="store_true", help="raw API JSON")

    c = sub.add_parser("get")
    c.add_argument("doc_id")
    c.add_argument("--json", action="store_true")

    c = sub.add_parser("replace")
    c.add_argument("doc_id")
    c.add_argument("--find", required=True)
    c.add_argument("--replace", required=True)
    c.add_argument("--match-case", action="store_true")

    c = sub.add_parser("resolve")
    c.add_argument("doc_id")
    c.add_argument("--comment-id", required=True)
    c.add_argument("--reply")

    c = sub.add_parser("export")
    c.add_argument("doc_id")
    c.add_argument("--format", required=True)
    c.add_argument("-o", "--out")

    a = ap.parse_args()
    if a.cmd == "auth":
        do_auth()
    elif a.cmd == "create":
        do_create(a.file, a.title, a.share, a.role, a.notify, a.anyone)
    elif a.cmd == "share":
        do_share(a.doc_id, a.email, a.role, a.notify, a.anyone)
    elif a.cmd == "comments":
        do_comments(a.doc_id, a.all, a.raw)
    elif a.cmd == "get":
        do_get(a.doc_id, a.json)
    elif a.cmd == "replace":
        do_replace(a.doc_id, a.find, a.replace, a.match_case)
    elif a.cmd == "resolve":
        do_resolve(a.doc_id, a.comment_id, a.reply)
    elif a.cmd == "export":
        do_export(a.doc_id, a.format, a.out)


if __name__ == "__main__":
    main()
