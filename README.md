# ai-command

Natural language to shell command helper for **Ghostty + zsh**, powered by already authenticated CLI tools such as **Codex** and **Claude**.

This project provides a lightweight terminal UX similar to tools like `zsh-ai`, but instead of relying on direct API key based provider integration, it reuses **already logged-in CLI tools** and writes the generated command back into the current shell buffer.

> The generated command is **never auto-executed**.  
> It is only inserted into the current command line so you can review and edit it before running.

---

## Features

- `# natural language` + Enter
- `Cmd+I` to convert the current buffer into a shell command
- Uses authenticated CLI tools instead of API keys
- Supports multiple providers:
  - `codex`
  - `claude`
- Keeps `.zshrc` minimal
- Ghostty-friendly keybinding setup
- Does **not** auto-run generated commands

---

## Motivation

I wanted a workflow that feels similar to Warp or `zsh-ai`, but with a few constraints:

- keep using **Ghostty**
- avoid switching to a heavy integrated terminal
- avoid managing API keys directly
- reuse already authenticated local CLI tools
- keep the experience safe by never auto-executing generated commands

So the final design became:

- **Terminal**: Ghostty
- **Shell UX**: zsh + ZLE
- **Generation backend**: `codex` / `claude`
- **Execution model**: generate command -> insert into buffer -> user reviews -> user runs manually

---

## How It Works

### Option 1: `#` UX

Type:

```text
# show the number of files here
```

Press Enter.

The plugin intercepts the line, sends the natural language request to the configured backend, and replaces the current shell buffer with the generated command.

Example result:

```bash
find . -type f | wc -l
```

---

### Option 2: `Cmd+I`

Type:

```text
show the number of files here
```

Then press `Cmd+I`.

The current buffer is treated as a natural language request and converted into a command.

---

## Example UX

Input:

```text
# generate a commit message for current changes
```

Progress output:

```text
[codex] request: generate a commit message for current changes
[codex] ⠋ thinking...
[codex] ✓ command ready
```

Result in buffer:

```bash
git commit -m "feat: refine ai command setup and shell integration"
```

---

## Directory Layout

```text
~/.config/zsh/plugins/ai-command/
├── ai-command.zsh
├── bin/
│   └── ai-command-gen
├── setup.sh
└── README.md
```

---

## Installation

Recommended install location:

```bash
~/.config/zsh/plugins/ai-command
```

Clone and install:

```bash
git clone <YOUR_REPO_URL> ~/.config/zsh/plugins/ai-command
cd ~/.config/zsh/plugins/ai-command
chmod +x setup.sh
./setup.sh
source ~/.zshrc
```

Then restart Ghostty.

---

## Ghostty Configuration

This project uses the following Ghostty keybinding:

```ini
keybind = cmd+i=csi:9;9u
```

`setup.sh` will append this automatically if it does not already exist.

---

## zsh Configuration

Your `.zshrc` only needs these lines:

```zsh
export PATH="$HOME/.config/zsh/plugins/ai-command/bin:$PATH"
source "$HOME/.config/zsh/plugins/ai-command/ai-command.zsh"
```

The rest of the logic stays outside `.zshrc`.

---

## Setup Script

`setup.sh` is intentionally simple.

Running:

```bash
./setup.sh
```

will:

1. add the Ghostty `Cmd+I` keybind if it does not already exist
2. append the current repository's `bin` path to `.zshrc`
3. append the current repository's `ai-command.zsh` source line to `.zshrc`

It assumes the script is executed **from inside the cloned repository**.

---

## Provider Selection

Default provider:

```zsh
: "${AI_CMD_PROVIDER:=codex}"
```

You can switch providers dynamically:

```bash
aip codex
aip claude
```

Or:

```bash
AI_CMD_PROVIDER=codex
AI_CMD_PROVIDER=claude
```

---

## Code Structure

### `ai-command.zsh`

Responsible for:

- ZLE widgets
- `# ...` line interception
- `Cmd+I` key handling
- simple status / spinner UI
- replacing the current shell buffer with generated output

### `bin/ai-command-gen`

Responsible for:

- calling the configured provider backend
- normalizing provider behavior
- returning only the generated shell command

This separation keeps the shell UX layer independent from the provider execution logic.

---

## Design Decisions

### 1. Never auto execute

The generated command is **only inserted into the shell buffer**.

This is intentional.

Why:

- safer for destructive commands
- easier to review and edit
- avoids accidental execution of wrong output

---

### 2. Keep `.zshrc` small

The shell config file should only load the plugin, not contain the whole implementation.

---

### 3. Use authenticated CLI instead of API keys

This project is built around the idea that local CLI tools may already be logged in and ready to use.

That makes it simpler to:

- reuse existing auth sessions
- avoid extra API key management
- stay closer to local terminal workflows

---

### 4. Prefer stable terminal UX over flashy UI

Earlier versions experimented with box-drawing UI and multiline panels, but those caused issues:

- broken alignment with Korean text width
- Unicode box rendering issues
- prompt redraw conflicts
- background job notifications corrupting layout

The final version uses a much simpler and more stable single-line progress UX.

---

## Known Adjustments

### Claude CLI invocation may vary

Depending on how `claude` is installed, this part may need adjustment inside:

```text
bin/ai-command-gen
```

For example, you may need:

```bash
claude "..."
```

or:

```bash
claude -p "..."
```

---

## Troubleshooting

### `read-only variable: status`

Cause: `status` is a reserved/read-only zsh special variable.

Fix: use another name such as:

```zsh
local exit_code=0
```

---

### `zsh: command not found: #`

Cause: interactive comments are not enabled.

Fix:

```zsh
setopt interactivecomments
```

---

### UI looks broken or misaligned

Cause:

- terminal font / redraw issues
- Korean text width
- box drawing characters
- multiline prompt conflicts

Fix:

- use the simplified single-line UI
- avoid box-drawing layouts

---

### Background job completion messages break the spinner

Cause:

```text
[2] + done ...
```

Fix:

```zsh
unsetopt monitor notify
```

---

## Example Commands

```text
# show disk usage of current directory
# show 20 most recently modified go files
# find files larger than 100MB
# generate a commit message for current diff
# show process using port 8080
```

Example generated commands:

```bash
du -sh .
find . -name '*.go' -type f -print0 | xargs -0 ls -lt | head -n 20
find . -type f -size +100M -print0 | xargs -0 du -h | sort -hr
git commit -m "feat: ..."
lsof -i :8080
```

---

## Reference

This project was inspired by the UX of:

- [matheusml/zsh-ai](https://github.com/matheusml/zsh-ai)

However, the implementation here is intentionally different:

- `zsh-ai` is provider/API-key oriented
- `ai-command` is designed around **already authenticated local CLI tools**

---

## Summary

`ai-command` is a small personal shell plugin that gives Ghostty + zsh a natural language command generation workflow without moving to a fully AI-integrated terminal and without relying on direct API key management.
