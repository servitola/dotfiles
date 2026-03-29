-- Clipboard-to-LLM Processor
-- Ctrl+Hyper+R → ascetic chooser menu → send selected text to Groq → paste result
-- Uses Groq API (OpenAI-compatible) with llama-3.1-8b-instant
-- Free tier: 14,400 req/day, no expiration

local M = {}
local log = hs.logger.new('ClipboardLLM', 'info')

local apiKey = nil
local chooser = nil
local pendingText = nil
local clipboardTimer = nil  -- prevent GC

-- Read GROQ_API_KEY from ~/.config/openai_key.sh
local function getApiKey()
    if apiKey then return apiKey end
    local f = io.open(os.getenv("HOME") .. "/.config/openai_key.sh", "r")
    if not f then
        log.e("Cannot read ~/.config/openai_key.sh")
        return nil
    end
    local content = f:read("*all")
    f:close()
    apiKey = content:match('GROQ_API_KEY="([^"]+)"') or content:match("GROQ_API_KEY='([^']+)'")
    if not apiKey then
        log.e("GROQ_API_KEY not found in ~/.config/openai_key.sh")
    end
    return apiKey
end

-- Get selected text (accessibility API → clipboard fallback)
local function getSelectedText(callback)
    local selectedText = nil

    local systemElement = hs.axuielement.systemWideElement()
    local focusedElement = systemElement:attributeValue("AXFocusedUIElement")
    if focusedElement then
        selectedText = focusedElement:attributeValue("AXSelectedText")
    end

    if selectedText and selectedText ~= "" then
        callback(selectedText)
        return
    end

    -- Fallback: copy to clipboard, read after delay
    local prevClipboard = hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c", 0)
    clipboardTimer = hs.timer.doAfter(0.15, function()
        clipboardTimer = nil
        local clipText = hs.pasteboard.getContents()
        if clipText and clipText ~= "" and clipText ~= prevClipboard then
            callback(clipText)
        else
            hs.alert.show("No text selected", 1.5)
        end
    end)
end

-- LLM action definitions
local actions = {
    { text = "Rewrite",        subText = "Improve clarity and style",     prompt = "Rewrite the following text to improve clarity, style, and readability. Keep the same meaning and tone. Return only the rewritten text, nothing else." },
    { text = "Fix Grammar",    subText = "Fix spelling and grammar",      prompt = "Fix all spelling and grammar errors in the following text. Keep the original meaning and style. Return only the corrected text, nothing else." },
    { text = "Translate → EN", subText = "Translate to English",          prompt = "Translate the following text to English. Return only the translation, nothing else." },
    { text = "Translate → RU", subText = "Translate to Russian",          prompt = "Translate the following text to Russian. Return only the translation, nothing else." },
    { text = "Summarize",      subText = "Concise summary",              prompt = "Summarize the following text concisely. Return only the summary, nothing else." },
    { text = "Explain",        subText = "Explain in simple terms",       prompt = "Explain the following text in simple, clear terms. Be concise." },
    { text = "Shorter",        subText = "Make it shorter",              prompt = "Make the following text significantly shorter while keeping the key meaning. Return only the shortened text, nothing else." },
    { text = "Professional",   subText = "Make it professional",          prompt = "Rewrite the following text in a professional business tone. Return only the rewritten text, nothing else." },
}

-- Call Groq API async
local function callLLM(systemPrompt, userText)
    local key = getApiKey()
    if not key then
        hs.alert.show("Groq API key not configured", 2)
        return
    end

    local payload = hs.json.encode({
        model = "llama-3.1-8b-instant",
        messages = {
            { role = "system", content = systemPrompt },
            { role = "user", content = userText }
        },
        temperature = 0.3
    })

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. key
    }

    hs.http.asyncPost("https://api.groq.com/openai/v1/chat/completions", payload, headers, function(status, body, responseHeaders)
        if status ~= 200 then
            log.e("Groq API error: " .. tostring(status) .. " " .. tostring(body))
            hs.alert.show("API error: " .. tostring(status), 2)
            return
        end

        local ok, response = pcall(hs.json.decode, body)
        if not ok or not response then
            log.e("Failed to parse response")
            hs.alert.show("Failed to parse response", 2)
            return
        end

        local result = response.choices
            and response.choices[1]
            and response.choices[1].message
            and response.choices[1].message.content

        if result then
            result = result:gsub("^%s+", ""):gsub("%s+$", "")
            hs.pasteboard.setContents(result)
            hs.eventtap.keyStroke({"cmd"}, "v", 0)
            hs.alert.show("Done", 0.8)
        else
            hs.alert.show("Empty response", 2)
        end
    end)
end

-- Handle chooser selection
local function onChoice(choice)
    if not choice or not pendingText then return end

    hs.alert.show("Processing...", 1)
    callLLM(choice.prompt, pendingText)
    pendingText = nil
end

-- Create the chooser (once, reuse)
local function getChooser()
    if chooser then return chooser end

    chooser = hs.chooser.new(onChoice)
    chooser:bgDark(true)
    chooser:placeholderText("AI Action")
    chooser:searchSubText(true)
    chooser:width(30)

    local choices = {}
    for _, action in ipairs(actions) do
        table.insert(choices, {
            text = action.text,
            subText = action.subText,
            prompt = action.prompt,
        })
    end
    chooser:choices(choices)

    return chooser
end

-- Main entry point
function M.show()
    getSelectedText(function(text)
        pendingText = text
        local c = getChooser()
        c:query("")
        c:show()
    end)
end

return M
