# Claude LiteLLM Launcher

Use these commands to switch Claude Code between:

- **LiteLLM mode**: Claude talks through the LiteLLM proxy.
- **Default Claude mode**: Claude uses its normal/original settings.

Nothing is permanently changed. The scripts set or clear Claude environment variables only for the app they start.

## Pick One Command

### Windows PowerShell

Claude with LiteLLM:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') }"
```

Claude with default/original settings:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default"
```

VS Code with LiteLLM:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --code --args --new-window ."
```

VS Code with default/original settings:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --code --args --new-window ."
```

### macOS, Linux, Or Git Bash

Claude with LiteLLM:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash
```

Claude with default/original settings:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```

VS Code with LiteLLM:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --code --args --new-window .
```

VS Code with default/original settings:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --code --args --new-window .
```

## Important Notes

- On Windows, use the PowerShell commands.
- Run Bash commands from Bash, Git Bash, macOS Terminal, or Linux Terminal.
- If VS Code is already open, close it or open a new window from the command above so extensions inherit the selected mode.
- VS Code Stable, VS Code Insiders, and VSCodium are auto-detected when possible.
- For a custom VS Code command, add `--code-command <command-or-path>`.

Full details are in [docs/claude-litellm-scripts.md](docs/claude-litellm-scripts.md).
