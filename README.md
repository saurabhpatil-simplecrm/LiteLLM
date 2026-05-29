# Claude LiteLLM Launcher

Use this to switch Claude Code between LiteLLM and normal Claude.

## Best Setup

Download the script once, save your LiteLLM settings once, then use short daily commands.

### Windows PowerShell

Download:

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1' -OutFile "$HOME\claude-litellm.ps1"
Unblock-File "$HOME\claude-litellm.ps1"
```

Save your LiteLLM settings once:

```powershell
& "$HOME\claude-litellm.ps1" --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
```

Daily use:

```powershell
& "$HOME\claude-litellm.ps1"
& "$HOME\claude-litellm.ps1" default
```

### macOS, Linux, Or Git Bash

Download:

```bash
curl -fsSL 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh' -o "$HOME/claude-litellm.sh"
chmod +x "$HOME/claude-litellm.sh"
```

Save your LiteLLM settings once:

```bash
"$HOME/claude-litellm.sh" --token 'sk-your-litellm-key' --model 'zai.glm-5' --save
```

Daily use:

```bash
"$HOME/claude-litellm.sh"
"$HOME/claude-litellm.sh" default
```

## VS Code Global Toggle

Use this when the Claude extension in VS Code should keep the same mode after you restart VS Code.

Turn LiteLLM on globally:

```powershell
& "$HOME\claude-litellm.ps1" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

```bash
"$HOME/claude-litellm.sh" --token 'sk-your-litellm-key' --model 'zai.glm-5' --global
```

Go back to normal Claude globally:

```powershell
& "$HOME\claude-litellm.ps1" default --global
```

```bash
"$HOME/claude-litellm.sh" default --global
```

After using `--global`, close all Claude Code and VS Code windows, then open them again.

## No Download

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

## Notes

- Replace `sk-your-litellm-key` with your real LiteLLM key.
- If your LiteLLM proxy does not need a token, skip `--token`.
- `--save` writes a local `.env` file for this launcher.
- `--global` writes Claude Code user settings in `~/.claude/settings.json`, which is the best toggle for VS Code.
- `default --global` restores the Claude environment values that existed before this launcher turned LiteLLM on globally.
- Do not commit `.env` if it contains a real token.

More details are in [docs/claude-litellm-scripts.md](docs/claude-litellm-scripts.md).
