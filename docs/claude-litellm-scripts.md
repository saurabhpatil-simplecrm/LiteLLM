# Claude LiteLLM Launcher Guide

This guide is written for copy and paste use.

The simple workflow is:

1. Download the script once.
2. Save your LiteLLM token and model once.
3. Run a short command for LiteLLM.
4. Run `default` to go back to normal Claude.

## Pick The Right Script

Use PowerShell on Windows:

```text
claude-litellm.ps1
```

Use Bash on macOS, Linux, WSL, or Git Bash:

```text
claude-litellm.sh
```

Do not pipe the Bash script through PowerShell. PowerShell can change the text before Bash reads it.

## Windows PowerShell

Download the script:

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1' -OutFile "$HOME\claude-litellm.ps1"
Unblock-File "$HOME\claude-litellm.ps1"
```

Save settings once:

```powershell
& "$HOME\claude-litellm.ps1" --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
```

Use LiteLLM:

```powershell
& "$HOME\claude-litellm.ps1"
```

Use normal Claude:

```powershell
& "$HOME\claude-litellm.ps1" default
```

## macOS, Linux, WSL, Or Git Bash

Download the script:

```bash
curl -fsSL 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh' -o "$HOME/claude-litellm.sh"
chmod +x "$HOME/claude-litellm.sh"
```

Save settings once:

```bash
"$HOME/claude-litellm.sh" --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
```

Use LiteLLM:

```bash
"$HOME/claude-litellm.sh"
```

Use normal Claude:

```bash
"$HOME/claude-litellm.sh" default
```

## VS Code Global Toggle

Use this when the Claude extension in VS Code should remember the mode after VS Code restarts.

PowerShell, turn LiteLLM on globally:

```powershell
& "$HOME\claude-litellm.ps1" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

PowerShell, go back to normal Claude globally:

```powershell
& "$HOME\claude-litellm.ps1" default --global
```

Bash, turn LiteLLM on globally:

```bash
"$HOME/claude-litellm.sh" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

Bash, go back to normal Claude globally:

```bash
"$HOME/claude-litellm.sh" default --global
```

Then close all Claude Code and VS Code windows and open them again.

What `--global` changes:

```text
~/.claude/settings.json
```

It adds these Claude Code user settings:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://172.22.11.114:4000",
    "ANTHROPIC_AUTH_TOKEN": "sk-your-litellm-key",
    "ANTHROPIC_MODEL": "zai.glm-5"
  }
}
```

Claude Code user settings apply to all projects. They are also the right place for a VS Code extension that starts Claude Code.

When LiteLLM is turned on globally, the launcher also saves the previous values for these Claude environment settings in `~/.claude/claude-litellm-state.json`. When you run `default --global`, it restores those previous values and removes that backup file.

## No Download Commands

Use these if you do not want to keep the script file.

PowerShell:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --token 'sk-your-litellm-key' --model 'zai.glm-5' --save"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') }"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default"
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```

## What Is Saved

`--save` creates or updates a local `.env` file:

```env
CLAUDE_LITELLM_BASE_URL=http://172.22.11.114:4000
CLAUDE_LITELLM_MODEL=zai.glm-5
CLAUDE_LITELLM_AUTH_TOKEN=sk-your-litellm-key
```

Use `--save` when you mainly launch Claude through this script.

Use `--global` when you want Claude Code or the VS Code extension to remember the mode without this script being open.

Do not commit `.env` if it contains a real token.

## Common Changes

Use a different LiteLLM URL:

```powershell
& "$HOME\claude-litellm.ps1" --base-url 'http://your-litellm-host:4000' --save
```

```bash
"$HOME/claude-litellm.sh" --base-url 'http://your-litellm-host:4000' --save
```

Save without a token:

```powershell
& "$HOME\claude-litellm.ps1" --model 'zai.glm-5' --save
```

```bash
"$HOME/claude-litellm.sh" --model 'zai.glm-5' --save
```

Open VS Code from the script for one session:

```powershell
& "$HOME\claude-litellm.ps1" --code --args --new-window .
```

```bash
"$HOME/claude-litellm.sh" --code --args --new-window .
```

Use VS Code Insiders or another command:

```powershell
& "$HOME\claude-litellm.ps1" --code-command code-insiders --args --new-window .
```

```bash
"$HOME/claude-litellm.sh" --code-command code-insiders --args --new-window .
```

## Check Before Launching

Dry run prints what would happen without launching Claude:

```powershell
& "$HOME\claude-litellm.ps1" --dry-run
& "$HOME\claude-litellm.ps1" default --dry-run
```

```bash
"$HOME/claude-litellm.sh" --dry-run
"$HOME/claude-litellm.sh" default --dry-run
```

Doctor checks the command and config:

```powershell
& "$HOME\claude-litellm.ps1" --doctor --skip-health
```

```bash
"$HOME/claude-litellm.sh" --doctor --skip-health
```

## Local Repo Usage

If you cloned this repo, run the scripts from the repo folder:

```powershell
.\scripts\claude-litellm.ps1 --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
.\scripts\claude-litellm.ps1
.\scripts\claude-litellm.ps1 default
```

```bash
bash ./scripts/claude-litellm.sh --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
bash ./scripts/claude-litellm.sh
bash ./scripts/claude-litellm.sh default
```

## Troubleshooting

### PowerShell says scripts are disabled

Run this once for the downloaded file:

```powershell
Unblock-File "$HOME\claude-litellm.ps1"
```

Or use the no-download PowerShell command from this guide.

### I saved settings but Claude does not use them

If you used `--save`, run the script from the same folder where `.env` was saved.

If you used `--global`, restart Claude Code or VS Code.

### VS Code still uses the old mode

Close all VS Code windows, then open VS Code again.

If that still does not work, use:

```powershell
& "$HOME\claude-litellm.ps1" default --global
& "$HOME\claude-litellm.ps1" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

```bash
"$HOME/claude-litellm.sh" default --global
"$HOME/claude-litellm.sh" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

### `ANTHROPIC_AUTH_TOKEN is empty`

This is only a warning. It is okay if your LiteLLM proxy allows no token. If your proxy requires a token, save or pass a token.

### `Base URL must be an absolute http or https URL`

Use a full URL:

```text
http://172.22.11.114:4000
```

Do not use only:

```text
172.22.11.114:4000
```

### `claude command: not found`

Open a terminal where this works:

```bash
claude --version
```

### `code command: not found`

VS Code is not available from that terminal. Install the `code` command or pass a path with `--code-command`.

### `--global needs Node.js`

The Bash script uses Node.js to safely edit Claude Code's JSON settings file. Install Node.js, or run the PowerShell script on Windows.

## Official Claude Code Settings

Claude Code user settings live at `~/.claude/settings.json` and apply to all projects. Claude Code also supports an `env` section in settings, which is what `--global` updates.

Reference: [Claude Code settings](https://docs.claude.com/en/docs/claude-code/settings)
