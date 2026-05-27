# Claude LiteLLM Script Usage

This document is only for the two launcher scripts in `scripts/`:

- `scripts/claude-litellm.ps1`
- `scripts/claude-litellm.sh`

GitHub repo:

```text
https://github.com/simplecrm-projects/liteLLM
```

Raw script base:

```text
https://raw.githubusercontent.com/simplecrm-projects/liteLLM/main/scripts
```

Both scripts can start Claude in either mode:

- `litellm`: use the LiteLLM proxy
- `default`: clear Anthropic proxy environment variables for this run and use normal Claude

## LiteLLM Defaults

```text
ANTHROPIC_BASE_URL=http://172.22.11.114:4000
ANTHROPIC_MODEL=zai.glm-5
ANTHROPIC_AUTH_TOKEN=
```

Token lookup order:

```text
CLAUDE_LITELLM_AUTH_TOKEN
ANTHROPIC_AUTH_TOKEN
LITELLM_TEST_KEY
LITELLM_MASTER_KEY
```

## PowerShell Script

Use LiteLLM:

```powershell
.\scripts\claude-litellm.ps1
.\scripts\claude-litellm.ps1 litellm
.\scripts\claude-litellm.ps1 --token "sk-your-litellm-key"
.\scripts\claude-litellm.ps1 --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

Use default Claude:

```powershell
.\scripts\claude-litellm.ps1 default
.\scripts\claude-litellm.ps1 --default
.\scripts\claude-litellm.ps1 --reset
```

Pass Claude CLI args:

```powershell
.\scripts\claude-litellm.ps1 --claude --version
.\scripts\claude-litellm.ps1 --default --claude --version
.\scripts\claude-litellm.ps1 --claude --print "hello"
```

Check without launching Claude:

```powershell
.\scripts\claude-litellm.ps1 --dry-run
.\scripts\claude-litellm.ps1 --default --dry-run
.\scripts\claude-litellm.ps1 --print-env
.\scripts\claude-litellm.ps1 --default --print-env
.\scripts\claude-litellm.ps1 --doctor --skip-health
.\scripts\claude-litellm.ps1 --default --doctor --skip-health
```

Run directly from GitHub raw:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/simplecrm-projects/liteLLM/main/scripts/claude-litellm.ps1') }"
iex "& { $(irm 'https://raw.githubusercontent.com/simplecrm-projects/liteLLM/main/scripts/claude-litellm.ps1') } default"
```

## Bash Script

Use LiteLLM:

```bash
bash ./scripts/claude-litellm.sh
bash ./scripts/claude-litellm.sh litellm
bash ./scripts/claude-litellm.sh --token "sk-your-litellm-key"
bash ./scripts/claude-litellm.sh --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

Use default Claude:

```bash
bash ./scripts/claude-litellm.sh default
bash ./scripts/claude-litellm.sh --default
bash ./scripts/claude-litellm.sh --reset
```

Pass Claude CLI args:

```bash
bash ./scripts/claude-litellm.sh --claude --version
bash ./scripts/claude-litellm.sh --default --claude --version
bash ./scripts/claude-litellm.sh --claude --print "hello"
```

Check without launching Claude:

```bash
bash ./scripts/claude-litellm.sh --dry-run
bash ./scripts/claude-litellm.sh --default --dry-run
bash ./scripts/claude-litellm.sh --print-env
bash ./scripts/claude-litellm.sh --default --print-env
bash ./scripts/claude-litellm.sh --doctor --skip-health
bash ./scripts/claude-litellm.sh --default --doctor --skip-health
```

Run directly from GitHub raw:

```bash
curl -fsSL https://raw.githubusercontent.com/simplecrm-projects/liteLLM/main/scripts/claude-litellm.sh | bash
curl -fsSL https://raw.githubusercontent.com/simplecrm-projects/liteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```

These raw commands work after the two script files are pushed to the `main` branch. Use a pinned commit SHA instead of `main` when you want a stable command.
