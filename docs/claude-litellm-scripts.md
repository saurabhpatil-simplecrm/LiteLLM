# Claude LiteLLM Launcher Scripts

This repo has only two Claude Code launcher scripts:

- `scripts/claude-litellm.ps1` for Windows PowerShell
- `scripts/claude-litellm.sh` for macOS and Linux Bash

Repository:

```text
https://github.com/saurabhpatil-simplecrm/LiteLLM
```

Raw script base:

```text
https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts
```

The scripts do not permanently change your system. They set or clear `ANTHROPIC_*` variables only for the Claude process they launch.

## What The Modes Do

LiteLLM mode is the default. It sets:

```text
ANTHROPIC_BASE_URL=http://172.22.11.114:4000
ANTHROPIC_MODEL=zai.glm-5
ANTHROPIC_AUTH_TOKEN=
```

Default-Claude mode clears these variables for this run:

```text
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_MODEL
```

Use default-Claude mode when you want Claude Code to use its normal config instead of the LiteLLM proxy.

## Run From GitHub

Windows PowerShell, LiteLLM mode:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') }"
```

Windows PowerShell, default-Claude mode:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default"
```

macOS or Linux Bash, LiteLLM mode:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash
```

macOS or Linux Bash, default-Claude mode:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default
```

Check from GitHub without launching a real prompt:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --dry-run"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --dry-run"
```

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --dry-run
```

## Local Usage

PowerShell:

```powershell
.\scripts\claude-litellm.ps1
.\scripts\claude-litellm.ps1 litellm
.\scripts\claude-litellm.ps1 default
.\scripts\claude-litellm.ps1 --default
.\scripts\claude-litellm.ps1 --reset
```

Bash:

```bash
bash ./scripts/claude-litellm.sh
bash ./scripts/claude-litellm.sh litellm
bash ./scripts/claude-litellm.sh default
bash ./scripts/claude-litellm.sh --default
bash ./scripts/claude-litellm.sh --reset
```

## Passing Claude Args

Put wrapper options first. Put Claude options after `--claude` or `--`.

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --claude --version
.\scripts\claude-litellm.ps1 --default --claude --version
.\scripts\claude-litellm.ps1 --claude --print "hello"
.\scripts\claude-litellm.ps1 -- --version
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --claude --version
bash ./scripts/claude-litellm.sh --default --claude --version
bash ./scripts/claude-litellm.sh --claude --print "hello"
bash ./scripts/claude-litellm.sh -- --version
```

## Tokens And Env Files

You can pass a token directly:

```powershell
.\scripts\claude-litellm.ps1 --token "sk-your-litellm-key"
```

```bash
bash ./scripts/claude-litellm.sh --token "sk-your-litellm-key"
```

Or set one of these environment variables. The first non-empty value wins:

```text
CLAUDE_LITELLM_AUTH_TOKEN
ANTHROPIC_AUTH_TOKEN
LITELLM_TEST_KEY
LITELLM_MASTER_KEY
```

You can also use a `.env` file in the current directory:

```env
CLAUDE_LITELLM_BASE_URL=http://172.22.11.114:4000
CLAUDE_LITELLM_MODEL=zai.glm-5
CLAUDE_LITELLM_AUTH_TOKEN=sk-your-litellm-key
```

Supported `.env` forms:

```env
KEY=value
KEY="value"
KEY='value'
export KEY=value
```

Only the Claude/LiteLLM variables used by the launcher are loaded. Other `.env` keys are ignored by the Bash script.

Use a custom token variable:

```powershell
.\scripts\claude-litellm.ps1 --token-env MY_LITELLM_KEY
```

```bash
bash ./scripts/claude-litellm.sh --token-env MY_LITELLM_KEY
```

An empty token is allowed only when the LiteLLM proxy allows unauthenticated requests.

## Changing URL Or Model

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --base-url "http://172.22.11.114:4000" --model "zai.glm-5"
```

The base URL must be an absolute `http://` or `https://` URL. Trailing slashes are removed.

## Checks And Diagnostics

Dry run:

```powershell
.\scripts\claude-litellm.ps1 --dry-run
.\scripts\claude-litellm.ps1 --default --dry-run
```

```bash
bash ./scripts/claude-litellm.sh --dry-run
bash ./scripts/claude-litellm.sh --default --dry-run
```

Print environment commands:

```powershell
.\scripts\claude-litellm.ps1 --print-env
.\scripts\claude-litellm.ps1 --default --print-env
```

```bash
bash ./scripts/claude-litellm.sh --print-env
bash ./scripts/claude-litellm.sh --default --print-env
```

Check `claude` and skip network health:

```powershell
.\scripts\claude-litellm.ps1 --doctor --skip-health
.\scripts\claude-litellm.ps1 --default --doctor --skip-health
```

```bash
bash ./scripts/claude-litellm.sh --doctor --skip-health
bash ./scripts/claude-litellm.sh --default --doctor --skip-health
```

Check LiteLLM `/health` too:

```powershell
.\scripts\claude-litellm.ps1 --doctor
```

```bash
bash ./scripts/claude-litellm.sh --doctor
```

## Platform Notes

Windows:

- Use PowerShell for `claude-litellm.ps1`.
- If script execution is blocked locally, run with `powershell -ExecutionPolicy Bypass -File .\scripts\claude-litellm.ps1`.

macOS:

- Use `bash`, not `sh` or `zsh`, for `claude-litellm.sh`.
- The script is written to work with macOS system Bash 3.2 and newer Bash versions.

Linux:

- Use `bash`, not `sh`.
- `curl` is only needed for raw GitHub usage and the optional `/health` check.

## Troubleshooting

`bash: WARNINGS[@]: unbound variable`

Update to the latest script from this repo. Older script versions expanded an empty Bash array under `set -u`, which can fail on macOS Bash 3.2.

`claude command: not found on PATH`

Install Claude Code or open a shell where `claude --version` works first.

`ANTHROPIC_AUTH_TOKEN is empty`

Pass `--token`, set `CLAUDE_LITELLM_AUTH_TOKEN`, or make sure your LiteLLM proxy allows unauthenticated requests.

`Base URL must be an absolute http or https URL`

Use a full URL such as `http://172.22.11.114:4000`, not only `172.22.11.114:4000` and not `http://`.

`default` still uses LiteLLM

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --dry-run
```

or:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --dry-run"
```

The output must show:

```text
ANTHROPIC_BASE_URL=(cleared)
ANTHROPIC_AUTH_TOKEN=(cleared)
ANTHROPIC_MODEL=(cleared)
```

## Stable Raw Commands

Raw `main` always runs the newest script. For a stable command, pin a commit SHA:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.sh | bash
```

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.ps1') }"
```
