# Hammerspoon

Powerful automation tool for macOS that bridges Lua scripting with macOS APIs for desktop automation.

### Spoon System

Hammerspoon uses "Spoons" - modular extensions:

```lua
hs.loadSpoon("HotKeys")        -- Custom keyboard shortcuts
hs.loadSpoon("Windows")        -- Window management
hs.loadSpoon("KSheet")         -- Shortcut reference
hs.loadSpoon("PopupTranslateSelection") -- Translation
```

### Configuration Structure

Main configuration in `hammerspoon/init.lua`:
- Loads all spoons
- Sets up global preferences

## HotKeys Spoon

My main keyboard shortcut system with 30 different modifier combinations.

### Hyper Key System

**Caps Lock remapped to Hyper** (⌘⌃⌥⇧) for ergonomic access to all shortcuts.

### Layout System

**30 Different Modifier Combinations:**

1. **Base Layers (01-10)**: Single modifiers
   - English, Russian, Greek layouts
   - Shift variants for uppercase
   - Command, Control, Option layers

2. **Hyper Layers (11-15)**: Hyper + additional modifiers
   - Main Hyper layer (11)
   - Hyper+Alt, Hyper+Command, etc.

3. **Complex Layers (16-30)**: Multi-modifier combinations
   - Command+Shift, Control+Alt, etc.

### App-Specific Shortcuts

**Fork Git Client:**
```lua
{ from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" }
{ from = {"cmd", "shift"}, key = "r", to = {"cmd", "shift"}, target_key = "p" }
```

**Music App:**
```lua
{ from = {"cmd"}, key = "e", to = {"cmd"}, target_key = "l" }
```

## Windows Spoon

Window management with keyboard shortcuts.

### Positioning Shortcuts

Using Ctrl+Alt+Arrow keys for window positioning:
- `Ctrl+Alt+↑` - Maximize window
- `Ctrl+Alt+↓` - Minimize window
- `Ctrl+Alt+←` - Left half
- `Ctrl+Alt+→` - Right half

## KSheet Spoon

Visual shortcut reference system.

### Features

- Overlay showing available shortcuts
- Context-aware display
- Customizable appearance

### Usage

Activated via keyboard shortcut to show current layer shortcuts.

## PopupTranslateSelection Spoon

Text translation functionality.

### Integration

- Select text in any application
- Press shortcut to translate
- Shows translation in popup

### Language Support

Supports multiple languages with automatic detection.

## YouTrack Integration

### YouTrackTicket Spoon

- Create tickets from selected text
- Integration with [YouTrack](https://www.jetbrains.com/youtrack/) issue tracker

### YouTrackTasks Spoon

- View assigned tasks
- Quick access to task management

## Audio Management

### AudioSwitcher Spoon

Switch between audio devices:
- Input devices (microphones)
- Output devices (speakers, headphones)
- System audio routing

## URL Dispatching

Smart URL handling based on domain patterns.

### Browser Routing

```lua
-- Work tools open in Safari
if string.match(url, "github%.com") then
    return "com.apple.Safari"
end

-- Personal stuff in other browsers
if string.match(url, "youtube%.com") then
    return "com.google.Chrome"
end
```

Configured in `config_UrlDispatcher.lua`.

## Voice Dictation

### VoiceDictation Spoon

Real-time speech-to-text typing:
- Activate via keyboard shortcut
- Speaks into microphone
- Types transcribed text

### Integration

Works with any application that accepts text input.

## Configuration Management

### Live Reloading

```lua
reload_hammerspoon_on_script_changed.lua
```

Automatically reloads configuration when files change.

## Development Workflow

### Testing Changes

1. Make changes to Lua files
2. Save files (auto-reload enabled)
3. Test functionality
4. Check console for errors

### Custom Spoon Development

Create new spoons in `Spoons/` directory:
```
MySpoon.spoon/
├── init.lua
└── docs.json
```

## Integration with Other Tools

### Karabiner-Elements

Hammerspoon works with Karabiner for advanced keyboard remapping:
- Caps Lock → Hyper key
- Complex key combinations
- Device-specific mappings

### macOS Integration

Full access to macOS APIs:
- Accessibility features
- System events
- Application scripting
- File system operations
