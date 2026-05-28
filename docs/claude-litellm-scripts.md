# Claude LiteLLM Launcher Scripts

This repo is intentionally small. It keeps only two Claude Code launcher scripts plus this documentation:

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

The scripts do not permanently change your system. They set or clear `ANTHROPIC_*` variables only for the Claude or VS Code process they launch.

## What The Modes Do

LiteLLM mode is the default. It clears any stale `ANTHROPIC_API_KEY` and sets:

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
ANTHROPIC_API_KEY
```

Use default-Claude mode when you want Claude Code to use its normal config instead of the LiteLLM proxy.

## VS Code Claude Extension Toggle

VS Code extensions inherit environment variables from the VS Code process. The scripts can launch VS Code with the same LiteLLM or default-Claude toggle by using `--code` or `--vscode`.

LiteLLM VS Code window:

```powershell
.\scripts\claude-litellm.ps1 --code --args --new-window .
```

```bash
bash ./scripts/claude-litellm.sh --code --args --new-window .
```

Default-Claude VS Code window:

```powershell
.\scripts\claude-litellm.ps1 default --code --args --new-window .
```

```bash
bash ./scripts/claude-litellm.sh default --code --args --new-window .
```

If VS Code is already running, restart it or open a fresh window from the script so the extension host inherits the selected environment. If `code` is not on `PATH`, the scripts try `code-insiders`, `codium`, `codium-insiders`, and common VS Code install paths.

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

Run the Bash commands from Bash or Git Bash. In PowerShell, use the PowerShell script instead of piping `curl.exe` into Bash, because PowerShell can re-encode piped text before Bash reads it.

Check from GitHub without launching a real prompt:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --dry-run"
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --dry-run"
```

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --dry-run
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --dry-run
```

Run VS Code from GitHub with the selected toggle:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } --code --args --new-window ."
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.ps1') } default --code --args --new-window ."
```

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- --code --args --new-window .
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/main/scripts/claude-litellm.sh | bash -s -- default --code --args --new-window .
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

## Passing Target Args

Put wrapper options first. Put target command options after `--args` or `--claude`. When `--code` is used, the same trailing args are passed to `code`.

PowerShell:

```powershell
.\scripts\claude-litellm.ps1 --args --version
.\scripts\claude-litellm.ps1 --default --args --version
.\scripts\claude-litellm.ps1 --args --print "hello"
.\scripts\claude-litellm.ps1 --code --args --new-window .
```

Bash:

```bash
bash ./scripts/claude-litellm.sh --args --version
bash ./scripts/claude-litellm.sh --default --args --version
bash ./scripts/claude-litellm.sh --args --print "hello"
bash ./scripts/claude-litellm.sh --code --args --new-window .
```

## Tokens And Env Files

You can pass a token directly:

```powershell
.\scripts\claude-litellm.ps1 --token "sk-your-litellm-key"
```

```bash
bash ./scripts/claude-litellm.sh --token "sk-your-litellm-key"
```

Or set one of these environment variables. The first non-empty value wins. Blank process variables do not block a non-empty value from `.env`.

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

Only the Claude/LiteLLM variables used by the launcher are loaded. When `--token-env <name>` is used, that named key is also loaded from `.env` if it is present.

Use a custom token variable:

```powershell
.\scripts\claude-litellm.ps1 --token-env MY_LITELLM_KEY
```

```bash
bash ./scripts/claude-litellm.sh --token-env MY_LITELLM_KEY
```

The custom token variable can come from the shell environment or from the selected `.env` file:

```env
MY_LITELLM_KEY=sk-your-litellm-key
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

`claude command: not found on PATH` or `code command: not found on PATH`

Install Claude Code or open a shell where `claude --version` works first. For VS Code mode, install the command-line launcher or make sure VS Code, VS Code Insiders, or VSCodium is installed in a standard location.

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
ANTHROPIC_API_KEY=(cleared)
```

## Stable Raw Commands

Raw `main` always runs the newest script. For a stable command, pin a commit SHA:

```bash
curl -fsSL https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.sh | bash
```

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/saurabhpatil-simplecrm/LiteLLM/<commit-sha>/scripts/claude-litellm.ps1') }"
```
