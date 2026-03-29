-- Text Expansion Dictionary
-- Abbreviations for text_expansion.lua engine
-- Value: string (literal) or function (dynamic, called on each expansion)
-- Prefix convention: ; + category letter + keyword
--   ;d = date/time, ;g = git, ;r = review, ;c = commit, ;y = youtrack
--   ;s = standup, ;m = meeting, ;a = architecture, ;e = email/communication
--   ;cs = C#, ;ts = TypeScript, ;md = markdown, ;sym = symbols, ;u = utility

return {

    ---------------------------------------------------------------------------
    -- Date / Time                                                        ;d*
    ---------------------------------------------------------------------------
    [";date"]     = function() return os.date("%Y-%m-%d") end,
    [";time"]     = function() return os.date("%H:%M") end,
    [";now"]      = function() return os.date("%Y-%m-%d %H:%M") end,
    [";ts"]       = function() return tostring(os.time()) end,
    [";week"]     = function() return "W" .. os.date("%V") end,
    [";ymd"]      = function() return os.date("%Y%m%d") end,
    [";iso"]      = function() return os.date("%Y-%m-%dT%H:%M:%S%z") end,
    [";yesterday"]= function() return os.date("%Y-%m-%d", os.time() - 86400) end,
    [";tomorrow"] = function() return os.date("%Y-%m-%d", os.time() + 86400) end,
    [";monday"]   = function()
        local t = os.time()
        local wday = tonumber(os.date("%w", t))
        local diff = (wday == 0) and -6 or (1 - wday)
        return os.date("%Y-%m-%d", t + diff * 86400)
    end,
    [";friday"]   = function()
        local t = os.time()
        local wday = tonumber(os.date("%w", t))
        local diff = (wday == 0) and -2 or (5 - wday)
        return os.date("%Y-%m-%d", t + diff * 86400)
    end,

    ---------------------------------------------------------------------------
    -- Git                                                                ;g*
    ---------------------------------------------------------------------------
    [";branch"]   = function()
        local out = hs.execute("cd ~/projects/Spotware/cTraderDev && git branch --show-current 2>/dev/null")
        return out and out:gsub("%s+$", "") or "unknown"
    end,
    [";hash"]     = function()
        local out = hs.execute("cd ~/projects/Spotware/cTraderDev && git rev-parse --short HEAD 2>/dev/null")
        return out and out:gsub("%s+$", "") or ""
    end,
    [";lastmsg"]  = function()
        local out = hs.execute("cd ~/projects/Spotware/cTraderDev && git log -1 --format=%s 2>/dev/null")
        return out and out:gsub("%s+$", "") or ""
    end,

    ---------------------------------------------------------------------------
    -- Code Review                                                        ;r*
    ---------------------------------------------------------------------------
    [";suggest"]  = "Suggestion (non-blocking): ",
    [";question"] = "Question: ",
    [";ood"]      = "Out of scope for this PR, but worth tracking as a follow-up.",
    [";cleanup"]  = "Could we clean this up in a follow-up PR?",
    [";perf"]     = "Performance concern: ",
    [";sec"]      = "Security concern: ",
    [";test"]     = "Could we add a test for this case?",
    [";notest"]   = "Missing test coverage for this change.",
    [";dup"]      = "This looks like it duplicates logic in ",
    [";naming"]   = "Consider a more descriptive name — ",
    [";magic"]    = "Magic number — consider extracting to a named constant.",
    [";race"]     = "Potential race condition here: ",
    [";null"]     = "This could be null/undefined here — needs a guard.",
    [";solid"]    = "This violates the Single Responsibility Principle.",
    [";yagni"]    = "YAGNI — let's not add this until we actually need it.",
    [";dry"]      = "DRY — this is already implemented in ",
    [";revert"]   = "Let's revert this and discuss the approach first.",
    [";wip"]      = "This looks like WIP — should it be in this PR?",

    ---------------------------------------------------------------------------
    -- PR / Commit Messages                                               ;c*
    ---------------------------------------------------------------------------
    [";feat"]     = "feat: ",
    [";fix"]      = "fix: ",
    [";refactor"] = "refactor: ",
    [";chore"]    = "chore: ",
    [";docs"]     = "docs: ",
    [";style"]    = "style: ",
    [";ci"]       = "ci: ",
    [";breaking"] = "BREAKING CHANGE: ",
    [";wontfix"]  = "Won't fix — ",
    [";reopen"]   = "Reopening — ",

    ---------------------------------------------------------------------------
    -- YouTrack / Issue Tracking                                          ;y*
    ---------------------------------------------------------------------------
    [";inprog"]   = "State: In Progress",
    [";done"]     = "State: Done",
    [";blocked"]  = "State: Blocked\nBlocked by: ",
    [";repro"]    = "Steps to reproduce:\n1. \n2. \n3. \n\nExpected: \nActual: ",
    [";ac"]       = "Acceptance Criteria:\n- [ ] \n- [ ] \n- [ ] ",
    [";impact"]   = "Impact: \nAffected users: \nSeverity: ",
    [";rootcause"]= "Root cause: \nFix: \nPrevention: ",

    ---------------------------------------------------------------------------
    -- Standup / Status Updates                                           ;s*
    ---------------------------------------------------------------------------
    [";standup"]  = function() return os.date("%Y-%m-%d") .. " Standup\n\nDone:\n- \n\nToday:\n- \n\nBlockers:\n- none" end,
    [";eod"]      = function() return os.date("%Y-%m-%d") .. " EOD\n\nCompleted:\n- \n\nIn Progress:\n- \n\nNotes:\n- " end,
    [";weekly"]   = function() return "Week " .. os.date("%V") .. " Summary\n\nKey achievements:\n- \n\nNext week:\n- \n\nRisks:\n- " end,

    ---------------------------------------------------------------------------
    -- Meeting Notes                                                      ;m*
    ---------------------------------------------------------------------------
    [";meeting"]  = function() return os.date("%Y-%m-%d") .. " Meeting Notes\n\nAttendees: \nTopic: \n\nDiscussion:\n- \n\nAction Items:\n- [ ] \n- [ ] " end,
    [";1on1"]     = function() return os.date("%Y-%m-%d") .. " 1:1\n\nCheckin:\n- \n\nTopics:\n- \n\nAction items:\n- [ ] " end,
    [";retro"]    = function() return "Sprint Retrospective " .. os.date("%Y-%m-%d") .. "\n\nWent well:\n- \n\nCould improve:\n- \n\nAction items:\n- [ ] " end,
    [";agenda"]   = function() return "Agenda — " .. os.date("%Y-%m-%d") .. "\n\n1. \n2. \n3. \n\nNotes:\n" end,
    [";decision"] = "Decision: \nContext: \nAlternatives considered: \nRationale: ",

    ---------------------------------------------------------------------------
    -- Architecture / Technical                                           ;a*
    ---------------------------------------------------------------------------
    [";adr"]      = function() return "# ADR: \n\n## Status\nProposed\n\n## Context\n\n\n## Decision\n\n\n## Consequences\n\n" end,
    [";tradeoff"] = "Trade-off: \nPros: \nCons: \nDecision: ",
    [";techdebt"] = "Technical debt: \nImpact: \nEffort to fix: \nPriority: ",
    [";api"]      = "Endpoint: \nMethod: \nRequest: \nResponse: \nErrors: ",
    [";migration"]= "Migration plan:\n1. Backup\n2. Apply migration\n3. Verify\n4. Rollback plan: ",
    [";postmortem"]= function() return "Incident Post-Mortem " .. os.date("%Y-%m-%d") .. "\n\nSummary: \nImpact: \nTimeline:\n- \n\nRoot cause: \nFix: \nAction items:\n- [ ] " end,
    [";deploy"]   = function() return "Deploy " .. os.date("%Y-%m-%d %H:%M") .. "\n\nVersion: \nChanges:\n- \n\nRollback: \nMonitoring: " end,

    ---------------------------------------------------------------------------
    -- Communication / Email                                              ;e*
    ---------------------------------------------------------------------------
    [";regards"]  = "Best regards",
    [";ty"]       = "Thank you",
    [";tyvm"]     = "Thank you very much!",
    [";pls"]      = "Could you please ",
    [";fyi"]      = "FYI — ",
    [";imo"]      = "In my opinion, ",
    [";afaik"]    = "As far as I know, ",
    [";tldr"]     = "TL;DR: ",
    [";ping"]     = "Gentle ping on this — any updates?",
    [";followup"] = "Following up on our earlier discussion — ",
    [";ack"]      = "Acknowledged. I'll look into this.",
    [";onit"]     = "On it. Will update when done.",
    [";eta"]      = "ETA: ",
    [";wfm"]      = "Works for me.",
    [";sgtm"]     = "Sounds good to me.",
    [";np"]       = "No problem!",
    [";sync"]     = "Let's sync on this — when works for you?",
    [";async"]    = "Let's handle this async — I'll leave my thoughts here.",
    [";delegate"] = "I'd like to delegate this to ",
    [";escalate"] = "Escalating this because: ",
    [";ooo"]      = function() return "I'll be OOO on " .. os.date("%Y-%m-%d", os.time() + 86400) .. ". Back on " end,

    ---------------------------------------------------------------------------
    -- Markdown                                                          ;md*
    ---------------------------------------------------------------------------
    [";h1"]       = "# ",
    [";h2"]       = "## ",
    [";h3"]       = "### ",
    [";cb"]       = "```\n\n```",
    [";cbcs"]     = "```csharp\n\n```",
    [";cbts"]     = "```typescript\n\n```",
    [";cbsh"]     = "```bash\n\n```",
    [";cbjson"]   = "```json\n\n```",
    [";link"]     = "[]()",
    [";img"]      = "![]()",
    [";table"]    = "| Column 1 | Column 2 | Column 3 |\n|----------|----------|----------|\n|          |          |          |",
    [";details"]  = "<details>\n<summary></summary>\n\n\n</details>",
    [";checkbox"] = "- [ ] ",
    [";note"]     = "> **Note:** ",
    [";warn"]     = "> **Warning:** ",
    [";collapse"] = "<details>\n<summary>Click to expand</summary>\n\n\n</details>",

    ---------------------------------------------------------------------------
    -- Dev Utilities                                                      ;u*
    ---------------------------------------------------------------------------
    [";todo"]     = "// TODO: ",
    [";fixme"]    = "// FIXME: ",
    [";uuid"]     = function()
        local out = hs.execute("uuidgen | tr '[:upper:]' '[:lower:]'")
        return out and out:gsub("%s+$", "") or ""
    end,
    [";lorem"]    = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    [";lorem2"]   = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
    [";b64"]      = function()
        local clip = hs.pasteboard.getContents()
        if not clip then return "" end
        local out = hs.execute("echo -n " .. hs.execute("printf '%q' " .. clip) .. " | base64")
        return out and out:gsub("%s+$", "") or ""
    end,
    [";ip"]       = function()
        local out = hs.execute("curl -s --max-time 2 https://api.ipify.org")
        return out and out:gsub("%s+$", "") or "unknown"
    end,
    [";localip"]  = function()
        local out = hs.execute("ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null")
        return out and out:gsub("%s+$", "") or "unknown"
    end,
    [";epoch"]    = function() return tostring(os.time()) end,
    [";random"]   = function() return tostring(math.random(100000, 999999)) end,
    [";hex"]      = function()
        local out = hs.execute("openssl rand -hex 16")
        return out and out:gsub("%s+$", "") or ""
    end,
}
