# PromptPad

A lightweight Windows prompt editor for AI CLI tools. PromptPad acts as your `$EDITOR` — launch it from the command line, write or refine your prompt, submit, and it exits. No background process, no residency, no complexity.

Built with WPF (.NET 8). Inspired by [TurboDraft](https://github.com/gradigit/turbodraft) (macOS), adapted for Windows.

## Features

### 1. $EDITOR CLI Integration

PromptPad works as a drop-in `$EDITOR` replacement for any CLI tool that opens an external editor — Claude Code, Codex CLI, git, kubectl, and others.

**Usage:**

```
promptpad.exe prompt.md           # Open a file for editing
promptpad.exe +15 prompt.md      # Open a file at line 15
promptpad.exe                     # Empty buffer, writes to stdout on submit
```

**Behavior:**

- **Submit** (Ctrl+Enter or Submit button): saves the file and exits with code 0
- **Cancel** (Escape or close window): exits with code 1, file unchanged
- Window title shows the current filename
- Monospace editor (Cascadia Code with Consolas fallback)
- Window position and size remembered between sessions

**Setting as your default editor:**

The easiest way is to run `.\install.ps1` (see [Installation](#installation)) — it handles PATH and EDITOR setup automatically.

To set it up manually:

```cmd
:: Permanent — persists across new terminal windows (open a new terminal after running)
setx EDITOR "C:\full\path\to\PromptPad.exe"
```

```bash
# Git Bash / WSL — add to your .bashrc or .zshrc
export EDITOR="/c/full/path/to/PromptPad.exe"
```

Use the full path to `PromptPad.exe` unless it's already on your PATH.

### 2. Image Paste

Paste screenshots and images directly into your prompts. PromptPad saves the image to disk and inserts a Markdown image placeholder at your cursor.

**How it works:**

- **Ctrl+V** with a screenshot on clipboard: saves as PNG, inserts `![image](path)` at cursor
- **Ctrl+V** with files on clipboard: inserts file path references (image format for image files)
- **Drag and drop** image files onto the editor: same as paste
- Plain text paste works normally — no interference

**Image storage:**

Images are saved to `%LOCALAPPDATA%\PromptPad\images\` with timestamp-based filenames (`img_20260221_143022_123.png`). These are not automatically cleaned up — manage the folder manually if disk space is a concern.

### 3. AI Prompt Improvement

Press **Ctrl+R** to send your current editor content to Claude for improvement. The response replaces your text, and you can **Ctrl+Z** to undo if you prefer the original.

**How it works:**

1. Write a rough prompt in the editor
2. Press Ctrl+R
3. Status bar shows "Improving..."
4. Claude returns an improved version of your prompt
5. Editor content is replaced (undo-able with Ctrl+Z)
6. Press Ctrl+Enter to submit the improved prompt

The status bar at the bottom shows the current model and provider (e.g., `Ctrl+R: claude / claude-sonnet-4-6`).

## How PromptPad Connects to Claude

### No API Key Required

PromptPad does **not** call the Anthropic API directly and does **not** need an API key. Instead, it shells out to the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude -p`) for prompt improvement.

This means:

- **Claude Code must be installed** and available on your PATH
- **Authentication is handled by Claude Code** — when you sign into Claude Code via your browser, PromptPad inherits that session automatically
- You do not need to manage API keys, tokens, or billing separately

### Why not use the Anthropic API directly?

Claude Code authenticates via browser-based OAuth and stores first-party tokens (`sk-ant-oat01-*`) in `~/.claude/.credentials.json`. These tokens are bound to the Claude Code application — they return `401 Unauthorized` when used with the Anthropic API directly. Rather than requiring users to obtain and configure a separate API key, PromptPad delegates to the Claude Code CLI, which handles its own authentication transparently.

### Prerequisites

1. **Install Claude Code**: Follow the [Claude Code installation guide](https://docs.anthropic.com/en/docs/claude-code)
2. **Sign in**: Run `claude` once in your terminal and complete the browser sign-in
3. **Verify**: Run `echo "hello" | claude -p` — if you get a response, PromptPad's Ctrl+R will work

If Claude Code is not installed or not on PATH, pressing Ctrl+R will show an error in the status bar.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Ctrl+Enter | Submit (save and exit) |
| Escape | Cancel (exit without saving) |
| Ctrl+R | Improve prompt with Claude |
| Ctrl+Z | Undo (including after Ctrl+R) |
| Ctrl+V | Paste (text, images, or files) |

## Configuration

Settings are stored in `%LOCALAPPDATA%\PromptPad\settings.json`, created automatically on first launch.

```json
{
  "window": {
    "left": 100,
    "top": 100,
    "width": 800,
    "height": 600
  },
  "ai": {
    "model": "claude-sonnet-4-6",
    "systemPrompt": "Improve this prompt for clarity, specificity, and effectiveness. Return only the improved prompt, no explanation.",
    "timeoutSeconds": 120
  }
}
```

| Setting | Description |
|---|---|
| `window.*` | Window position and size (updated automatically on exit) |
| `ai.model` | Claude model to use for prompt improvement |
| `ai.systemPrompt` | Instruction sent to Claude along with your prompt text |
| `ai.timeoutSeconds` | Maximum wait time for Claude CLI response |

Edit this file directly to change settings. Changes take effect on the next launch of PromptPad.

## Installation

### Option A: Install Script (recommended)

Build the project, then run the install script:

```powershell
# Build
dotnet publish src/PromptPad/PromptPad.csproj -p:PublishProfile=FrameworkDependent-win-x64

# Install
.\install.ps1
```

The install script:
- Copies `PromptPad.exe` to `%LOCALAPPDATA%\PromptPad\bin\`
- Adds that directory to your user PATH
- Sets the `EDITOR` environment variable to `promptpad.exe`
- Is idempotent — safe to run multiple times

Open a **new terminal** after running the script for PATH changes to take effect.

To uninstall:
```powershell
.\install.ps1 -Uninstall
```

### Option B: Manual Installation

1. Build the project (see [Building from Source](#building-from-source) below)
2. Copy `PromptPad.exe` to a directory of your choice
3. Add that directory to your PATH
4. Set the EDITOR variable:

```cmd
setx EDITOR "promptpad.exe"
```

### Choosing a Build: Framework-Dependent vs Self-Contained

PromptPad ships two publish profiles:

| | Framework-Dependent | Self-Contained |
|---|---|---|
| **Size** | ~165 KB | ~69 MB |
| **Requires .NET 8 Desktop Runtime** | Yes | No |
| **Startup speed** | Fast | Fast (after first launch) |
| **Best for** | Users with .NET 8 installed | Users without .NET 8 |

**First-launch note for the self-contained build:** On its very first run, the self-contained exe extracts the bundled .NET runtime to a cache directory (`%LOCALAPPDATA%\Temp\.net\PromptPad\`). This one-time extraction can take several seconds. All subsequent launches use the cache and start in under a second — the same speed as the framework-dependent build.

**Recommendation:** Use the framework-dependent build if you have the [.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) installed. It's smaller and has no first-launch delay.

## Building from Source

Requires the [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0). No third-party NuGet packages.

**Debug build:**
```bash
dotnet build src/PromptPad/PromptPad.csproj --configuration Debug
```

**Publish — framework-dependent (165 KB, requires .NET 8 Desktop Runtime):**
```bash
dotnet publish src/PromptPad/PromptPad.csproj -p:PublishProfile=FrameworkDependent-win-x64
# Output: src/PromptPad/bin/publish/framework-dependent/PromptPad.exe
```

**Publish — self-contained (69 MB, no runtime needed):**
```bash
dotnet publish src/PromptPad/PromptPad.csproj -p:PublishProfile=SelfContained-win-x64
# Output: src/PromptPad/bin/publish/self-contained/PromptPad.exe
```

## Project Structure

```
src/PromptPad/
  App.xaml / App.xaml.cs             Entry point, command-line arg parsing
  EditorWindow.xaml / .xaml.cs       Main window, keybindings, paste/drop handling
  Models/
    AppSettings.cs                   Settings data model
  Services/
    ClaudeCliCheck.cs                Startup check for Claude CLI on PATH
    ImageService.cs                  Clipboard image save to PNG
    PromptService.cs                 Shells out to Claude Code CLI
    SettingsService.cs               JSON settings load/save
```

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Submitted — file was saved |
| 1 | Cancelled — file unchanged |
| 2 | Error — invalid file path |
