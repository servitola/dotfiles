"""Parse JetBrains Rider keymap from settings.zip to extract real shortcuts."""
import os, re, zipfile, xml.etree.ElementTree as ET

_ZIP = os.path.join(os.path.dirname(__file__), "..", "..", "jetbrains rider", "settings.zip")
_KEYMAP = "keymaps/IntelliJ copy.xml"

# JetBrains key names → our physical key names
_TO_PHYS = {
    "a":"a","b":"b","c":"c","d":"d","e":"e","f":"f","g":"g","h":"h","i":"i",
    "j":"j","k":"k","l":"l","m":"m","n":"n","o":"o","p":"p","q":"q","r":"r",
    "s":"s","t":"t","u":"u","v":"v","w":"w","x":"x","y":"y","z":"z",
    "1":"1","2":"2","3":"3","4":"4","5":"5","6":"6","7":"7","8":"8","9":"9","0":"0",
    "back_quote":"tilde", "escape":"tilde",  # Karabiner remaps tilde→escape
    "minus":"minus", "equals":"equal", "equal":"equal",
    "open_bracket":"bracketleft", "close_bracket":"bracketright",
    "back_slash":"backslash", "semicolon":"semicolon", "quote":"apostrophe",
    "comma":"comma", "period":"period", "slash":"slash",
    "space":"space", "tab":"tab", "enter":"return",
    "back_space":"backspace",
    "left":"left", "right":"right", "up":"up", "down":"down",
    "multiply":"period",  # numpad * mapped loosely
}
# F-keys
for i in range(1, 13):
    _TO_PHYS[f"f{i}"] = str(i) if i <= 10 else ("minus" if i == 11 else "equal")

# JetBrains modifier names → our layer modifier names
_MOD_MAP = {"meta": "cmd", "ctrl": "ctrl", "alt": "alt", "shift": "shift"}

# Action ID → human-readable name (curated for common actions)
_NAMES = {
    "$Redo": "Redo", "Annotate": "Blame", "BuildSolutionAction": "Build Solution",
    "BuildStartupProject": "Build Project", "CancelBuildAction": "Cancel Build",
    "CloseAllEditorsButActive": "Close Other Tabs", "CloseAllNotifications": "Close Notifications",
    "CloseProject": "Close Project", "CodeCompletion": "Code Completion",
    "EditorCloneCaretAbove": "Clone Caret Above",
    "EditorBackwardParagraph": "Backward Paragraph", "EditorForwardParagraph": "Forward Paragraph",
    "EditorBackwardParagraphWithSelection": "Select Backward Paragraph",
    "EditorForwardParagraphWithSelection": "Select Forward Paragraph",
    "EditorScrollBottom": "Scroll to Bottom", "EditorScrollTop": "Scroll to Top",
    "ExpandAllToLevel3": "Expand All Lvl 3",
    "FindNext": "Find Next", "FindUsages": "Find Usages", "FindUsagesInFile": "Find Usages in File",
    "GotoTest": "Go to Test", "GotoLinkedTypes2": "Go to Linked Types",
    "GotoNextBookmarkInEditor": "Next Bookmark", "GotoPreviousBookmarkInEditor": "Prev Bookmark",
    "GotoNextElementUnderCaretUsage": "Next Usage Under Caret",
    "GotoPrevElementUnderCaretUsage": "Prev Usage Under Caret",
    "MembersPullUp": "Pull Members Up", "MergeAllWindowsAction": "Merge Windows",
    "MethodDown": "Next Method", "MethodUp": "Prev Method",
    "NextProjectWindow": "Next Project Window",
    "OpenInlineChatAction": "Inline AI Chat", "OpenXCodeAction": "Open in Xcode",
    "ReSharperGotoImplementation": "Go to Implementation",
    "RebuildSolutionAction": "Rebuild Solution", "RenameElement": "Rename",
    "ReopenClosedTab": "Reopen Closed Tab",
    "RevealIn": "Reveal in Finder", "RiderManageRecentProjects": "Recent Projects",
    "RiderNuGetToggleToolWindowAction": "NuGet", "RiderUnitTestQuickListPopupAction": "Unit Test Menu",
    "RiderUnitTestSessionAbortAction": "Abort Tests", "RunConfiguration": "Run Config",
    "SelectInProjectView": "Select in Project", "SilentCodeCleanup": "Code Cleanup + Save",
    "ShowContent": "Show Content", "ShowPopupMenu": "Context Menu",
    "Stop": "Stop", "Unscramble": "Unscramble",
    "Vcs.QuickListPopupAction": "Git Operations", "Vcs.ShowHistoryForBlock": "Git Block History",
    "Vcs.ShowTabbedFileHistory": "Git File History", "Vcs.Log.ShowDiffPreview": "Git Diff Preview",
    "Git.Log": "Git Log",
    "ActivateVersionControlToolWindow": "Git Panel",
    "ActivateFindToolWindow": "Find Panel", "ActivateHierarchyToolWindow": "Hierarchy",
    "ActivateBookmarksToolWindow": "Bookmarks", "ActivateBuildToolWindow": "Build Panel",
    "ActivateDebugToolWindow": "Debug Panel", "ActivateRunToolWindow": "Run Panel",
    "ActivateTestsToolWindow": "Tests Panel", "ActivateUnitTestsToolWindow": "Unit Tests Panel",
    "ActivateProblemsViewToolWindow": "Problems Panel",
    "ActivateDeviceManager2ToolWindow": "Device Manager",
    "ActivateLogcatToolWindow": "Logcat", "ActivateEventLogToolWindow": "Event Log",
    "ActivateXcodeToolWindow": "Xcode Panel",
    "ActiveConfiguration": "Active Config",
    "AIAssistant.ToolWindow.ShowOrFocus": "AI Assistant",
    "IntentionActionAsAction_com.intellij.ml.llm.intentions.chat.AIAssistantIntention": "AI Intention",
    "DeviceAndSnapshotComboBox": "Device Selector",
    "ToolWindowsGroup": "Tool Windows",
    "Macro.Save Macros": "Save Macros",
    "RestartIde": "Restart IDE",
}


def _action_name(action_id):
    """Convert action ID to human-readable name."""
    if action_id in _NAMES: return _NAMES[action_id]
    # CamelCase split: ActivateDebugToolWindow → Activate Debug Tool Window
    name = re.sub(r'([a-z])([A-Z])', r'\1 \2', action_id)
    name = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', name)
    # Clean up common patterns
    name = name.replace(".", " ").replace("_", " ").replace("$", "")
    name = re.sub(r'\s+', ' ', name).strip()
    # Shorten common suffixes
    for s in ("Tool Window", "Action"):
        if name.endswith(s): name = name[:-len(s)].strip()
    return name


def _parse_keystroke(ks):
    """Parse 'shift meta z' → (frozenset_layer_mods, physical_key) or None."""
    parts = ks.strip().lower().split()
    if not parts: return None
    key_name = parts[-1]
    phys = _TO_PHYS.get(key_name)
    if not phys: return None
    mods = set()
    for p in parts[:-1]:
        lm = _MOD_MAP.get(p)
        if lm: mods.add(lm)
    return (frozenset(mods), phys)


def parse_rider():
    """Return {(frozenset_layer_mods, physical_key): [("Rider", action_name)]} from keymap XML."""
    if not os.path.exists(_ZIP): return {}
    try:
        with zipfile.ZipFile(_ZIP) as zf:
            with zf.open(_KEYMAP) as f:
                tree = ET.parse(f)
    except (KeyError, ET.ParseError, zipfile.BadZipFile):
        return {}
    result = {}
    for action in tree.getroot().findall("action"):
        aid = action.get("id", "")
        for sc in action.findall("keyboard-shortcut"):
            # Skip chord sequences (second-keystroke)
            if sc.get("second-keystroke"): continue
            first = sc.get("first-keystroke", "")
            parsed = _parse_keystroke(first)
            if not parsed: continue
            layer, phys = parsed
            name = _action_name(aid)
            result.setdefault((layer, phys), []).append(("Rider", name))
    return result
