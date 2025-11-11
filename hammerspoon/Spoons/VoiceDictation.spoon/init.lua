--- === VoiceDictation ===
---
--- Record voice, transcribe with Whisper, and type the result
---
--- First press: start recording
--- Second press: stop, transcribe, and type

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "VoiceDictation"
obj.version = "2.1"
obj.author = "servitola"
obj.license = "MIT"

-- State
obj.isRecording = false
obj.recordingTask = nil
obj.tempAudioFile = nil
obj.alertId = nil
obj.transcribingAlertId = nil
obj.startTime = nil

-- Config
obj.maxRecordingSeconds = 300
obj.audioDevice = ":1" -- MacBook Pro Microphone
obj.ffmpegPath = "/opt/homebrew/bin/ffmpeg" -- Full path to ffmpeg
obj.transcriptionCmd = "whisper_voice" -- Use your whisper_voice function

--- VoiceDictation:toggleRecording()
--- Method
--- Toggle recording state - start or stop recording
---
--- Returns:
---  * The VoiceDictation object
function obj:toggleRecording()
    if self.isRecording then
        self:stopRecording()
    else
        self:startRecording()
    end
    return self
end

--- Internal function to start recording
function obj:startRecording()
    if self.isRecording then
        hs.alert.show("⚠️ Already recording")
        return
    end

    -- Generate temp file path
    local timestamp = os.time()
    local tmpDir = os.getenv("TMPDIR") or "/tmp/"
    if not tmpDir:match("/$") then
        tmpDir = tmpDir .. "/"
    end
    self.tempAudioFile = tmpDir .. "voice_dictation_" .. timestamp .. ".wav"

    print("Recording to: " .. self.tempAudioFile)

    self.alertId = hs.alert.show("🎤 Recording...", 999999)
    self.isRecording = true
    self.startTime = hs.timer.secondsSinceEpoch()

    self:startStandardRecording()
end

function obj:startStandardRecording()
    -- Build ffmpeg command for audio recording
    local cmd = string.format(
        "\"%s\" -f avfoundation -i \"%s\" -t %d -y \"%s\" 2>/dev/null",
        self.ffmpegPath,
        self.audioDevice,
        self.maxRecordingSeconds,
        self.tempAudioFile
    )

    print("Starting recording: " .. self.tempAudioFile)

    self.recordingTask = hs.task.new(
        "/bin/zsh",
        function(exitCode, stdOut, stdErr)
            print("Recording process finished. Exit code: " .. exitCode)
            if stdErr and stdErr ~= "" then
                print("ffmpeg stderr: " .. stdErr)
            end
        end,
        {"-c", cmd}
    )

    self.recordingTask:start()
end

function obj:stopRecording()
    if not self.isRecording then
        hs.alert.show("⚠️ Not recording")
        return
    end

    if self.alertId then
        hs.alert.closeSpecific(self.alertId)
    end

    local duration = math.floor(hs.timer.secondsSinceEpoch() - self.startTime)
    print(string.format("Recording stopped after %d seconds", duration))

    if self.recordingTask and self.recordingTask:isRunning() then
        self.recordingTask:terminate()
    end

    self.isRecording = false

    self.transcribingAlertId = hs.alert.show("⏳ Transcribing...", 999999)
    self:transcribeAndType()
end

function obj:transcribeAndType()
    print("Transcribing: " .. self.tempAudioFile)

    local fileExists = hs.fs.attributes(self.tempAudioFile)
    if not fileExists then
        print("ERROR: Recording file not found at: " .. self.tempAudioFile)
        hs.alert.show("❌ Recording file not found")
        self:cleanup()
        return
    end

    print("File found! Size: " .. fileExists.size .. " bytes")

    if fileExists.size < 100 then
        print("ERROR: Recording file is too small (" .. fileExists.size .. " bytes)")
        hs.alert.show("❌ No audio recorded (file too small)")
        self:cleanup()
        return
    end

    -- Extract base name and directory from the path
    local baseName = self.tempAudioFile:match("([^/]+)%.wav$")
    local fileDir = self.tempAudioFile:match("^(.*)/[^/]+$") or "/tmp"

    if not baseName then
        print("ERROR: Could not extract base name from: " .. self.tempAudioFile)
        hs.alert.show("❌ Invalid file path")
        self:cleanup()
        return
    end

    -- whisper_voice (whisper-mps) outputs JSON to current directory
    -- Output file will be: output.json (default from whisper-mps)
    local jsonFile = fileDir .. "/output.json"

    local whisperCmd = string.format(
        "cd \"%s\" && %s \"%s\" 2>&1",
        fileDir,
        self.transcriptionCmd,
        self.tempAudioFile
    )

    print("Running transcription command: " .. whisperCmd)

    local result, success, execType, returnCode = hs.execute(whisperCmd, true)

    print("Transcription exit code: " .. returnCode)

    if returnCode ~= 0 then
        print("Transcription command failed with exit code: " .. returnCode)
        print("Output: " .. (result or "none"))
        hs.alert.show("❌ Transcription failed")
        self:cleanup()
        return
    end

    local jsonFile_handle = io.open(jsonFile, "r")
    if not jsonFile_handle then
        print("ERROR: Could not open JSON output file: " .. jsonFile)
        if self.transcribingAlertId then
            hs.alert.closeSpecific(self.transcribingAlertId)
        end
        hs.alert.show("❌ Could not read transcription output")
        self:cleanup()
        return
    end

    local jsonContent = jsonFile_handle:read("*all")
    jsonFile_handle:close()

    local transcribedText = jsonContent:match('"text"%s*:%s*"([^"]*)"') or ""

    transcribedText = transcribedText:gsub('\\"', '"')
    transcribedText = transcribedText:gsub('\\/', '/')
    transcribedText = transcribedText:gsub('\\n', '\n')
    transcribedText = transcribedText:match("^%s*(.-)%s*$") or ""

    if transcribedText == "" then
        print("ERROR: No text extracted from JSON")
        print("JSON content: " .. jsonContent)
        if self.transcribingAlertId then
            hs.alert.closeSpecific(self.transcribingAlertId)
        end
        hs.alert.show("❌ No speech detected")
        self:cleanup()
        return
    end

    print("Transcribed text: " .. transcribedText)

    if self.transcribingAlertId then
        hs.alert.closeSpecific(self.transcribingAlertId)
        self.transcribingAlertId = nil
    end

    hs.eventtap.keyStrokes(transcribedText)
    local displayText = string.sub(transcribedText, 1, 40)
    if string.len(transcribedText) > 40 then
        displayText = displayText .. "..."
    end

    self:cleanup()
end

function obj:cleanup()
    if self.tempAudioFile then

        local baseName = self.tempAudioFile:match("([^/]+)%.wav$")
        local fileDir = self.tempAudioFile:match("^(.*)/[^/]+$") or "/tmp"

        hs.execute("rm -f \"" .. self.tempAudioFile .. "\"")

        if baseName then
            hs.execute("rm -f \"" .. fileDir .. "/" .. baseName .. ".txt\"")
        end

        self.tempAudioFile = nil
    end
end

function obj:init()
    print("VoiceDictation initialized")

    local ffmpegCheck = hs.fs.attributes(self.ffmpegPath)
    if not ffmpegCheck then
        hs.alert.show("⚠️ ffmpeg not found at " .. self.ffmpegPath)
        print("Warning: ffmpeg not found at " .. self.ffmpegPath .. ". Install with: brew install ffmpeg")
    end

end

return obj
