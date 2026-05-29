# Claude LiteLLM Launcher Guide

This guide is for people who just want the right command to copy and paste.

The repo has two scripts:

- `scripts/claude-litellm.ps1` for Windows PowerShell
- `scripts/claude-litellm.sh` for macOS, Linux, and Git Bash

The scripts can start Claude Code or VS Code in one of two modes:

- **LiteLLM mode**: Claude uses the LiteLLM proxy.
- **Default Claude mode**: Claude uses its normal/original settings.

The scripts do **not** permanently change your computer. They only set or clear variables for the Claude or VS Code process they start.

## Which Command Should I Use?

Use this table first.

| I want | Windows PowerShell | macOS/Linux/Git Bash |
| --- | --- | --- |
| Claude with LiteLLM | Use command 1 below | Use command 5 below |
| Claude with default Claude settings | Use command 2 below | Use command 6 below |
| VS Code with LiteLLM | Use command 3 below | Use command 7 below |
| VS Code with default Claude settings | Use command 4 below | Use command 8 below |

## Commands To Copy

### 1. Windows: Claude With LiteLLM

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') }"
```

### 2. Windows: Claude With Default Claude Settings

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default"
```

### 3. Windows: VS Code With LiteLLM

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --code --args --new-window ."
```

### 4. Windows: VS Code With Default Claude Settings

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --code --args --new-window ."
```

### 5. macOS/Linux/Git Bash: Claude With LiteLLM

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash
```

### 6. macOS/Linux/Git Bash: Claude With Default Claude Settings

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```

### 7. macOS/Linux/Git Bash: VS Code With LiteLLM

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --code --args --new-window .
```

### 8. macOS/Linux/Git Bash: VS Code With Default Claude Settings

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --code --args --new-window .
```

## VS Code Notes

VS Code extensions receive settings from the VS Code process when the window starts.

For the toggle to affect a Claude extension:

1. Close old VS Code windows, or open a new window using one of the commands above.
2. Use the LiteLLM command when you want the extension to use LiteLLM.
3. Use the default command when you want the extension to use normal Claude settings.

This works for Claude extensions or extension versions that read inherited `ANTHROPIC_*` variables or launch Claude Code from the VS Code process. If an extension uses only its own account, API key, or server setting, set that extension separately.

The scripts try to find these VS Code commands automatically:

- `code`
- `code-insiders`
- `codium`
- `codium-insiders`
- common Windows, macOS, and Linux install locations

For a custom VS Code command or path, use `--code-command`.

PowerShell:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --code-command code-insiders --args --new-window ."
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --code-command code-insiders --args --new-window .
```

## What The Scripts Change

LiteLLM mode sets these values for the app it starts:

```text
ANTHROPIC_BASE_URL=http://172.22.11.114:4000
ANTHROPIC_MODEL=zai.glm-5
ANTHROPIC_AUTH_TOKEN=
```

LiteLLM mode also clears any old `ANTHROPIC_API_KEY` value for that run.

Default Claude mode clears these values for the app it starts:

```text
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_MODEL
ANTHROPIC_API_KEY
```

That is why default mode is useful when Claude is stuck trying to use an old proxy such as `localhost`.

## Before You Run

Windows:

- Open PowerShell.
- Use the PowerShell commands.
- Do not pipe the Bash script through PowerShell.

macOS/Linux:

- Open Terminal.
- Use the Bash commands.

Windows with Git Bash:

- Open Git Bash.
- Use the Bash commands there.

Why this matters: PowerShell can re-encode text when piping `curl.exe` into Bash. Use the PowerShell script in PowerShell, and use the Bash script in Bash/Git Bash.

## Check Without Launching Claude

Use dry run when you only want to see what would happen.

PowerShell:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --dry-run"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --dry-run"
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --dry-run
```

Default dry run should show:

```text
ANTHROPIC_BASE_URL=(cleared)
ANTHROPIC_AUTH_TOKEN=(cleared)
ANTHROPIC_MODEL=(cleared)
ANTHROPIC_API_KEY=(cleared)
```

## Local Repo Usage

If you already cloned this repo, use these commands from the repo folder.

PowerShell:

```powershell
.\scripts\claude-litellm.ps1
.\scripts\claude-litellm.ps1 default
.\scripts\claude-litellm.ps1 --code --args --new-window .
.\scripts\claude-litellm.ps1 default --code --args --new-window .
```

Bash:

```bash
bash ./scripts/claude-litellm.sh
bash ./scripts/claude-litellm.sh default
bash ./scripts/claude-litellm.sh --code --args --new-window .
bash ./scripts/claude-litellm.sh default --code --args --new-window .
```

## Optional Settings

Most people do not need this section.

### Use A LiteLLM Token

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --token "sk-your-litellm-key"
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --token "sk-your-litellm-key"
```

The scripts also read the first non-empty value from:

```text
CLAUDE_LITELLM_AUTH_TOKEN
ANTHROPIC_AUTH_TOKEN
LITELLM_TEST_KEY
LITELLM_MASTER_KEY
```

### Change The LiteLLM URL Or Model

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

The URL must start with `http://` or `https://`.

### Use A `.env` File

Create a `.env` file in the current folder:

```env
CLAUDE_LITELLM_BASE_URL=http://172.22.11.114:4000
CLAUDE_LITELLM_MODEL=zai.glm-5
CLAUDE_LITELLM_AUTH_TOKEN=sk-your-litellm-key
```

Supported forms:

```env
KEY=value
KEY="value"
KEY='value'
export KEY=value
```

Blank shell values do not block non-empty `.env` values.

### Use A Custom Token Variable

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --token-env MY_LITELLM_KEY
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --token-env MY_LITELLM_KEY
```

Your `.env` file can contain:

```env
MY_LITELLM_KEY=sk-your-litellm-key
```

## Diagnostics

Check the command and skip the network health check:

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --doctor --skip-health
.\scripts\claude-litellm.ps1 default --doctor --skip-health
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --doctor --skip-health
bash ./scripts/claude-litellm.sh default --doctor --skip-health
```

Print the environment commands:

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --print-env
.\scripts\claude-litellm.ps1 default --print-env
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --print-env
bash ./scripts/claude-litellm.sh default --print-env
```

## Troubleshooting

### Claude still tries to use LiteLLM after I choose default

Run default dry run and check for the cleared lines:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --dry-run"
```

### `claude command: not found`

Claude Code is not available in that terminal. Open a terminal where this works:

```bash
claude --version
```

### `code command: not found`

VS Code is not available from that terminal. The scripts try common VS Code, VS Code Insiders, and VSCodium locations. If your install is somewhere else, use `--code-command`.

### `ANTHROPIC_AUTH_TOKEN is empty`

This is only a warning. It is okay if your LiteLLM proxy allows no token. If your proxy requires a token, pass `--token` or set `CLAUDE_LITELLM_AUTH_TOKEN`.

### `Base URL must be an absolute http or https URL`

Use a full URL like:

```text
http://172.22.11.114:4000
```

Do not use only `172.22.11.114:4000`.

### `bash: WARNINGS[@]: unbound variable`

You are using an older script. Run the latest command from this guide.

## Stable Commands

The commands above use `main`, so they always run the newest script.

For a fixed version, replace `<commit-sha>` with a commit ID:

PowerShell:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.ps1') }"
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.sh | bash
```
