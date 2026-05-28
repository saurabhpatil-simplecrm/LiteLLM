# Claude LiteLLM Scripts

This repository contains two Claude Code launcher scripts:

- `scripts/claude-litellm.ps1` for Windows PowerShell
- `scripts/claude-litellm.sh` for Linux and macOS Bash

They start Claude in LiteLLM mode by default, or in default-Claude mode when you pass `default`, `--default`, or `--reset`. Default-Claude mode clears stale Anthropic proxy and API-key overrides for that run.

Full usage is in [docs/claude-litellm-scripts.md](docs/claude-litellm-scripts.md).

## Raw Run

PowerShell:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') }"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default"
```

Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```
