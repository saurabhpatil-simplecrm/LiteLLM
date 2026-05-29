#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BASE_URL="http://172.22.11.114:4000"
DEFAULT_MODEL="zai.glm-5"

BASE_URL=""
BASE_URL_SET=0
AUTH_TOKEN=""
AUTH_TOKEN_SET=0
TOKEN_ENV=""
MODEL=""
MODEL_SET=0
ENV_FILE=".env"
LOAD_ENV_FILE=1
DRY_RUN=0
DOCTOR=0
SKIP_HEALTH=0
PRINT_ENV=0
SAVE_CONFIG=0
SAVE_GLOBAL_CONFIG=0
SAVE_VSCODE_CONFIG=0
SKIP_VSCODE_CONFIG=0
SETTINGS_FILE=""
VSCODE_SETTINGS_FILE=""
USE_DEFAULT_CLAUDE=0
RUN_CODE=0
CODE_COMMAND=""
CODE_COMMAND_SET=0
HELP=0
TARGET_COMMAND="claude"
TARGET_LABEL="Claude"
CLAUDE_ARGS=()
WARNINGS=()
CLAUDE_ARG_COUNT=0
WARNING_COUNT=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/claude-litellm.sh [wrapper options] [--args target args...]

Runs Claude Code, or VS Code with --code, using Anthropic-compatible LiteLLM
environment variables by default. Clears those variables for normal Claude with
--default.

Defaults:
  base URL: http://172.22.11.114:4000
  model:    zai.glm-5
  token:    CLAUDE_LITELLM_AUTH_TOKEN, ANTHROPIC_AUTH_TOKEN,
            LITELLM_TEST_KEY, LITELLM_MASTER_KEY, or empty

Wrapper options:
      litellm, on           Explicitly use LiteLLM mode (default)
      default, reset, off   Clear Anthropic env vars and run normal Claude
  -u, --base-url <url>       LiteLLM Anthropic-compatible base URL
  -t, --token <token>        LiteLLM virtual key or auth token
      --token-env <name>     Read token from a named environment variable
  -m, --model <model>        Model name to expose to Claude Code
      --env-file <path>      Load missing values from an env file (default: .env)
      --no-env-file          Do not read .env
      --dry-run              Print the resolved command without launching Claude
      --doctor               Check config and target command, then exit
      --skip-health          Skip optional /health check when used with --doctor
      --print-env            Print export commands, then exit
      --save                 Save LiteLLM URL, model, and token to .env, then exit
      --global, --user       Save selected mode to Claude Code and VS Code settings, then exit
      --settings-file <path>  Use a custom Claude Code settings.json with --global
      --vscode-settings-file <path>
                             Use a custom VS Code settings.json with --global
      --no-vscode-settings   Do not update VS Code Claude extension settings
      --code, --vscode       Launch VS Code instead of claude with the selected env
      --code-command <cmd>    Use a custom VS Code command or path
      --default, --reset     Clear Anthropic env vars and run normal Claude
      --args, --claude       Treat the rest of the line as target command args
  -h, --help                 Show this help

Examples:
  bash scripts/claude-litellm.sh
  bash scripts/claude-litellm.sh litellm
  bash scripts/claude-litellm.sh --token sk-your-key --model zai.glm-5
  bash scripts/claude-litellm.sh --token sk-your-key --model zai.glm-5 --save
  bash scripts/claude-litellm.sh --token sk-your-key --model zai.glm-5 --global
  bash scripts/claude-litellm.sh default --global
  bash scripts/claude-litellm.sh --default
  bash scripts/claude-litellm.sh default
  bash scripts/claude-litellm.sh --dry-run --args --print "hello"
  bash scripts/claude-litellm.sh --code --args --new-window .
  bash scripts/claude-litellm.sh --code-command code-insiders --args --new-window .
  bash scripts/claude-litellm.sh default --code --args --new-window .
  bash scripts/claude-litellm.sh --print-env
EOF
}

die() {
  printf 'ERROR %s\n' "$*" >&2
  exit 1
}

read_required_value() {
  local index="$1"
  local flag="$2"
  local next_index=$((index + 1))
  if [ "$next_index" -ge "$INPUT_ARG_COUNT" ]; then
    die "Missing value for $flag."
  fi
  printf '%s' "${INPUT_ARGS[$next_index]}"
}

append_remaining() {
  local start="$1"
  local item
  for ((item = start; item < INPUT_ARG_COUNT; item += 1)); do
    CLAUDE_ARGS+=("${INPUT_ARGS[$item]}")
    CLAUDE_ARG_COUNT=$((CLAUDE_ARG_COUNT + 1))
  done
}

append_warning() {
  WARNINGS+=("$1")
  WARNING_COUNT=$((WARNING_COUNT + 1))
}

INPUT_ARGS=("$@")
INPUT_ARG_COUNT=$#
i=0
while [ "$i" -lt "$INPUT_ARG_COUNT" ]; do
  arg="${INPUT_ARGS[$i]}"
  case "$arg" in
    --|--args|--target-args|--claude)
      append_remaining "$((i + 1))"
      break
      ;;
    default|reset|off|claude-default)
      USE_DEFAULT_CLAUDE=1
      ;;
    litellm|on)
      ;;
    --base-url=*)
      BASE_URL="${arg#--base-url=}"
      BASE_URL_SET=1
      ;;
    --token=*)
      AUTH_TOKEN="${arg#--token=}"
      AUTH_TOKEN_SET=1
      ;;
    --auth-token=*)
      AUTH_TOKEN="${arg#--auth-token=}"
      AUTH_TOKEN_SET=1
      ;;
    --token-env=*)
      TOKEN_ENV="${arg#--token-env=}"
      ;;
    --model=*)
      MODEL="${arg#--model=}"
      MODEL_SET=1
      ;;
    --env-file=*)
      ENV_FILE="${arg#--env-file=}"
      ;;
    --settings-file=*|--claude-settings=*)
      SETTINGS_FILE="${arg#*=}"
      ;;
    --vscode-settings-file=*|--code-settings-file=*)
      VSCODE_SETTINGS_FILE="${arg#*=}"
      ;;
    --code-command=*|--vscode-command=*)
      CODE_COMMAND="${arg#*=}"
      CODE_COMMAND_SET=1
      RUN_CODE=1
      ;;
    --base-url|-u)
      BASE_URL="$(read_required_value "$i" "$arg")"
      BASE_URL_SET=1
      i=$((i + 1))
      ;;
    --token|--auth-token|-t)
      AUTH_TOKEN="$(read_required_value "$i" "$arg")"
      AUTH_TOKEN_SET=1
      i=$((i + 1))
      ;;
    --token-env)
      TOKEN_ENV="$(read_required_value "$i" "$arg")"
      i=$((i + 1))
      ;;
    --model|-m)
      MODEL="$(read_required_value "$i" "$arg")"
      MODEL_SET=1
      i=$((i + 1))
      ;;
    --env-file)
      ENV_FILE="$(read_required_value "$i" "$arg")"
      i=$((i + 1))
      ;;
    --settings-file|--claude-settings)
      SETTINGS_FILE="$(read_required_value "$i" "$arg")"
      i=$((i + 1))
      ;;
    --vscode-settings-file|--code-settings-file)
      VSCODE_SETTINGS_FILE="$(read_required_value "$i" "$arg")"
      i=$((i + 1))
      ;;
    --code-command|--vscode-command)
      CODE_COMMAND="$(read_required_value "$i" "$arg")"
      if [ -z "$CODE_COMMAND" ] || [[ "$CODE_COMMAND" == --* ]]; then
        die "Missing value for $arg."
      fi
      CODE_COMMAND_SET=1
      RUN_CODE=1
      i=$((i + 1))
      ;;
    --no-env-file)
      LOAD_ENV_FILE=0
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --doctor)
      DOCTOR=1
      ;;
    --skip-health)
      SKIP_HEALTH=1
      ;;
    --print-env)
      PRINT_ENV=1
      ;;
    --save)
      SAVE_CONFIG=1
      ;;
    --global|--user|--user-env|--vscode-global|--global-vscode)
      SAVE_GLOBAL_CONFIG=1
      SAVE_VSCODE_CONFIG=1
      ;;
    --no-vscode-settings)
      SKIP_VSCODE_CONFIG=1
      ;;
    --code|--vscode)
      RUN_CODE=1
      ;;
    --default|--reset|--claude-default)
      USE_DEFAULT_CLAUDE=1
      ;;
    --help|-h)
      HELP=1
      ;;
    -*)
      append_warning "Treating \"$arg\" and the remaining arguments as target command args. Put wrapper flags first or separate target args with \"--args\"."
      append_remaining "$i"
      break
      ;;
    *)
      append_remaining "$i"
      break
      ;;
  esac
  i=$((i + 1))
done

if [ "$HELP" -eq 1 ]; then
  usage
  exit 0
fi

trim() {
  local value="$*"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_matching_quotes() {
  local value="$1"
  if [ "${#value}" -ge 2 ] && {
    { [[ "$value" == \"*\" && "$value" == *\" ]]; } ||
    { [[ "$value" == \'*\' && "$value" == *\' ]]; }
  }; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

valid_env_name() {
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

load_env_file() {
  local raw line key value should_load current_value
  if [ "$LOAD_ENV_FILE" -ne 1 ] || [ ! -f "$ENV_FILE" ]; then
    return 0
  fi

  while IFS= read -r raw || [ -n "$raw" ]; do
    line="${raw%$'\r'}"
    line="$(trim "$line")"
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue
    [[ "$line" == export\ * ]] && line="${line#export }"
    [[ "$line" != *=* ]] && continue

    key="$(trim "${line%%=*}")"
    value="$(trim "${line#*=}")"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    value="$(strip_matching_quotes "$value")"

    case "$key" in
      CLAUDE_LITELLM_BASE_URL|CLAUDE_LITELLM_AUTH_TOKEN|ANTHROPIC_AUTH_TOKEN|LITELLM_TEST_KEY|LITELLM_MASTER_KEY|CLAUDE_LITELLM_MODEL)
        should_load=1
        ;;
      *)
        should_load=0
        if [ -n "$TOKEN_ENV" ] && [ "$key" = "$TOKEN_ENV" ]; then
          should_load=1
        fi
        ;;
    esac

    if [ "$should_load" -eq 1 ]; then
      current_value="${!key-}"
      if [ -z "$(trim "$current_value")" ]; then
        export "$key=$value"
      fi
    fi
  done < "$ENV_FILE"
}

first_nonblank_env() {
  local key value
  for key in "$@"; do
    value="${!key-}"
    if [ -n "$(trim "$value")" ]; then
      printf '%s' "$value"
      return 0
    fi
  done
  return 1
}

normalize_base_url() {
  local value
  value="$(trim "$1")"
  [ -n "$value" ] || die "Base URL cannot be empty. Pass --base-url or set CLAUDE_LITELLM_BASE_URL."
  [[ "$value" != *[[:space:]]* ]] || die "Base URL cannot contain whitespace: $value"

  while [[ "$value" == */ ]]; do
    value="${value%/}"
  done

  if [[ "$value" =~ ^https?://[^/[:space:]]+(/.*)?$ ]]; then
    printf '%s' "$value"
  else
    die "Base URL must be an absolute http or https URL: $value"
  fi
}

quote_bash() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$/\\\$}"
  value="${value//\`/\\\`}"
  printf '"%s"' "$value"
}

redact() {
  local value="$1"
  local length
  [ -n "$value" ] || {
    printf '(empty)'
    return 0
  }

  length="${#value}"
  if [ "$length" -le 8 ]; then
    printf '****'
  else
    local suffix_start=$((length - 4))
    printf '%s...%s' "${value:0:4}" "${value:$suffix_start:4}"
  fi
}

target_command() {
  printf '%s' "$TARGET_COMMAND"
}

target_label() {
  printf '%s' "$TARGET_LABEL"
}

resolve_code_command() {
  local name candidate
  for name in code code-insiders codium codium-insiders; do
    if command -v "$name" >/dev/null 2>&1; then
      command -v "$name"
      return 0
    fi
  done

  for candidate in \
    "$HOME/AppData/Local/Programs/Microsoft VS Code/bin/code" \
    "$HOME/AppData/Local/Programs/Microsoft VS Code/bin/code.cmd" \
    "$HOME/AppData/Local/Programs/Microsoft VS Code/Code.exe" \
    "$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code-insiders" \
    "$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code-insiders.cmd" \
    "$HOME/AppData/Local/Programs/Microsoft VS Code Insiders/Code - Insiders.exe" \
    "$HOME/AppData/Local/Programs/VSCodium/bin/codium" \
    "$HOME/AppData/Local/Programs/VSCodium/bin/codium.cmd" \
    "$HOME/AppData/Local/Programs/VSCodium/VSCodium.exe" \
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
    "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code-insiders" \
    "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" \
    "/usr/local/bin/code" \
    "/opt/homebrew/bin/code" \
    "/usr/bin/code"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'code\n'
}

print_exec_line() {
  local item command_name
  command_name="$(target_command)"
  printf '%q' "$command_name"
  if [ "$CLAUDE_ARG_COUNT" -gt 0 ]; then
    for item in "${CLAUDE_ARGS[@]}"; do
      printf ' %q' "$item"
    done
  fi
  printf '\n'
}

print_command() {
  printf 'Command: '
  print_exec_line
}

clear_anthropic_process_env() {
  unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_API_KEY
}

env_assignment() {
  local key="$1"
  local value="$2"
  case "$value" in
    *$'\n'*|*$'\r'*)
      die "Cannot save $key because the value contains a newline."
      ;;
  esac
  printf '%s=%s\n' "$key" "$value"
}

save_litellm_config() {
  local path="$1"
  local dir tmp raw key line_written
  local seen_base=0
  local seen_model=0
  local seen_token=0

  dir="$(dirname "$path")"
  if [ "$dir" != "." ] && [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi

  tmp="${path}.tmp.$$"
  : > "$tmp"

  if [ -f "$path" ]; then
    while IFS= read -r raw || [ -n "$raw" ]; do
      line_written=0
      if [[ "$raw" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*= ]]; then
        key="${BASH_REMATCH[2]}"
        case "$key" in
          CLAUDE_LITELLM_BASE_URL)
            env_assignment "$key" "$RESOLVED_BASE_URL" >> "$tmp"
            seen_base=1
            line_written=1
            ;;
          CLAUDE_LITELLM_MODEL)
            env_assignment "$key" "$RESOLVED_MODEL" >> "$tmp"
            seen_model=1
            line_written=1
            ;;
          CLAUDE_LITELLM_AUTH_TOKEN)
            env_assignment "$key" "$RESOLVED_AUTH_TOKEN" >> "$tmp"
            seen_token=1
            line_written=1
            ;;
        esac
      fi

      if [ "$line_written" -eq 0 ]; then
        printf '%s\n' "$raw" >> "$tmp"
      fi
    done < "$path"
  fi

  [ "$seen_base" -eq 1 ] || env_assignment "CLAUDE_LITELLM_BASE_URL" "$RESOLVED_BASE_URL" >> "$tmp"
  [ "$seen_model" -eq 1 ] || env_assignment "CLAUDE_LITELLM_MODEL" "$RESOLVED_MODEL" >> "$tmp"
  [ "$seen_token" -eq 1 ] || env_assignment "CLAUDE_LITELLM_AUTH_TOKEN" "$RESOLVED_AUTH_TOKEN" >> "$tmp"

  mv "$tmp" "$path"
}

claude_settings_path() {
  if [ -n "$(trim "$SETTINGS_FILE")" ]; then
    printf '%s' "$SETTINGS_FILE"
    return 0
  fi

  [ -n "${HOME-}" ] || die "Could not find your home folder for Claude Code settings."
  printf '%s/.claude/settings.json' "$HOME"
}

save_claude_settings_mode() {
  local mode="$1"
  local path
  path="$(claude_settings_path)"

  command -v node >/dev/null 2>&1 || die "--global needs Node.js to safely update Claude Code settings.json. Node.js is normally installed with Claude Code."

  CLAUDE_LITELLM_SETTINGS_PATH="$path" \
  CLAUDE_LITELLM_SETTINGS_MODE="$mode" \
  CLAUDE_LITELLM_SETTINGS_BASE_URL="${RESOLVED_BASE_URL-}" \
  CLAUDE_LITELLM_SETTINGS_AUTH_TOKEN="${RESOLVED_AUTH_TOKEN-}" \
  CLAUDE_LITELLM_SETTINGS_MODEL="${RESOLVED_MODEL-}" \
  node <<'NODE'
const fs = require('fs');
const path = require('path');

const settingsPath = process.env.CLAUDE_LITELLM_SETTINGS_PATH;
const mode = process.env.CLAUDE_LITELLM_SETTINGS_MODE;
const baseUrl = process.env.CLAUDE_LITELLM_SETTINGS_BASE_URL || '';
const authToken = process.env.CLAUDE_LITELLM_SETTINGS_AUTH_TOKEN || '';
const model = process.env.CLAUDE_LITELLM_SETTINGS_MODEL || '';
const managedKeys = [
  'ANTHROPIC_BASE_URL',
  'ANTHROPIC_AUTH_TOKEN',
  'ANTHROPIC_MODEL',
  'ANTHROPIC_API_KEY',
];

function fail(message) {
  console.error(`ERROR ${message}`);
  process.exit(1);
}

function readSettings(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  const raw = fs.readFileSync(filePath, 'utf8');
  if (raw.trim() === '') {
    return {};
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    fail(`Could not read ${filePath} as JSON. Fix the JSON first, then run this script again. ${error.message}`);
  }

  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object') {
    fail(`${filePath} must contain a JSON object.`);
  }

  return parsed;
}

if (!settingsPath) {
  fail('Settings path is empty.');
}

const statePath = path.join(path.dirname(settingsPath), 'claude-litellm-state.json');
const settings = readSettings(settingsPath);
let removeStateAfterWrite = false;
if (settings.env == null) {
  settings.env = {};
} else if (Array.isArray(settings.env) || typeof settings.env !== 'object') {
  fail(`The env value in ${settingsPath} must be a JSON object. Fix it first so this script does not overwrite unrelated settings.`);
}

if (mode === 'litellm') {
  for (const [name, value] of [
    ['ANTHROPIC_BASE_URL', baseUrl],
    ['ANTHROPIC_AUTH_TOKEN', authToken],
    ['ANTHROPIC_MODEL', model],
  ]) {
    if (/[\r\n]/.test(value)) {
      fail(`Cannot save ${name} because the value contains a newline.`);
    }
  }

  if (!fs.existsSync(statePath)) {
    const values = {};
    for (const key of managedKeys) {
      values[key] = Object.prototype.hasOwnProperty.call(settings.env, key)
        ? { exists: true, value: String(settings.env[key]) }
        : { exists: false, value: null };
    }
    fs.mkdirSync(path.dirname(statePath), { recursive: true });
    fs.writeFileSync(
      statePath,
      `${JSON.stringify({ version: 1, settingsPath, values }, null, 2)}\n`,
      'utf8'
    );
  }

  settings.env.ANTHROPIC_BASE_URL = baseUrl;
  settings.env.ANTHROPIC_AUTH_TOKEN = authToken;
  settings.env.ANTHROPIC_MODEL = model;
  delete settings.env.ANTHROPIC_API_KEY;
} else if (mode === 'default') {
  if (fs.existsSync(statePath)) {
    const state = readSettings(statePath);
    if (!state.values || Array.isArray(state.values) || typeof state.values !== 'object') {
      fail(`Could not restore global Claude settings because ${statePath} is missing a valid values object.`);
    }

    for (const key of managedKeys) {
      const entry = state.values[key];
      if (!entry || Array.isArray(entry) || typeof entry !== 'object') {
        continue;
      }
      if (entry.exists) {
        settings.env[key] = String(entry.value || '');
      } else {
        delete settings.env[key];
      }
    }
    removeStateAfterWrite = true;
  } else {
    delete settings.env.ANTHROPIC_BASE_URL;
    delete settings.env.ANTHROPIC_AUTH_TOKEN;
    delete settings.env.ANTHROPIC_MODEL;
  }
  if (Object.keys(settings.env).length === 0) {
    delete settings.env;
  }
} else {
  fail(`Unknown global mode: ${mode}`);
}

fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, 'utf8');
if (removeStateAfterWrite && fs.existsSync(statePath)) {
  fs.unlinkSync(statePath);
}
console.log(settingsPath);
NODE
}

save_vscode_extension_settings_mode() {
  local mode="$1"

  command -v node >/dev/null 2>&1 || die "--global needs Node.js to safely update VS Code Claude extension settings."

  CLAUDE_LITELLM_VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_FILE" \
  CLAUDE_LITELLM_VSCODE_MODE="$mode" \
  CLAUDE_LITELLM_VSCODE_BASE_URL="${RESOLVED_BASE_URL-}" \
  CLAUDE_LITELLM_VSCODE_AUTH_TOKEN="${RESOLVED_AUTH_TOKEN-}" \
  CLAUDE_LITELLM_VSCODE_MODEL="${RESOLVED_MODEL-}" \
  node <<'NODE'
const fs = require('fs');
const path = require('path');

const explicitSettingsFile = process.env.CLAUDE_LITELLM_VSCODE_SETTINGS_FILE || '';
const mode = process.env.CLAUDE_LITELLM_VSCODE_MODE || '';
const baseUrl = process.env.CLAUDE_LITELLM_VSCODE_BASE_URL || '';
const authToken = process.env.CLAUDE_LITELLM_VSCODE_AUTH_TOKEN || '';
const model = process.env.CLAUDE_LITELLM_VSCODE_MODEL || '';
const keyName = 'claudeCode.environmentVariables';
const stateFileName = 'claude-litellm-vscode-state.json';
const managedNames = new Set([
  'ANTHROPIC_BASE_URL',
  'ANTHROPIC_AUTH_TOKEN',
  'ANTHROPIC_MODEL',
  'ANTHROPIC_API_KEY',
]);

function fail(message) {
  console.error(`ERROR ${message}`);
  process.exit(1);
}

function fileExists(filePath) {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

function dirExists(dirPath) {
  try {
    return fs.statSync(dirPath).isDirectory();
  } catch {
    return false;
  }
}

function hasClaudeExtension(dirPath) {
  if (!dirExists(dirPath)) return false;
  return fs.readdirSync(dirPath).some((name) => /^anthropic\.claude-code-/i.test(name));
}

function hasSetting(filePath) {
  return fileExists(filePath) && fs.readFileSync(filePath, 'utf8').includes(`"${keyName}"`);
}

function pushTarget(targets, settingsPath, extensionDir) {
  if (!settingsPath) return;
  if (explicitSettingsFile) {
    targets.push(settingsPath);
    return;
  }
  if (hasSetting(settingsPath) || hasClaudeExtension(extensionDir)) {
    targets.push(settingsPath);
  }
}

function discoverTargets() {
  if (explicitSettingsFile) return [path.resolve(explicitSettingsFile)];

  const targets = [];
  const home = process.env.USERPROFILE || process.env.HOME || '';
  const appdata = process.env.APPDATA || '';
  const xdgConfig = process.env.XDG_CONFIG_HOME || (home ? path.join(home, '.config') : '');

  if (appdata) {
    pushTarget(targets, path.join(appdata, 'Code', 'User', 'settings.json'), home ? path.join(home, '.vscode', 'extensions') : '');
    pushTarget(targets, path.join(appdata, 'Code - Insiders', 'User', 'settings.json'), home ? path.join(home, '.vscode-insiders', 'extensions') : '');
    pushTarget(targets, path.join(appdata, 'VSCodium', 'User', 'settings.json'), home ? path.join(home, '.vscodium', 'extensions') : '');
    pushTarget(targets, path.join(appdata, 'Cursor', 'User', 'settings.json'), home ? path.join(home, '.cursor', 'extensions') : '');
  }

  if (home && process.platform === 'darwin') {
    pushTarget(targets, path.join(home, 'Library', 'Application Support', 'Code', 'User', 'settings.json'), path.join(home, '.vscode', 'extensions'));
    pushTarget(targets, path.join(home, 'Library', 'Application Support', 'Code - Insiders', 'User', 'settings.json'), path.join(home, '.vscode-insiders', 'extensions'));
    pushTarget(targets, path.join(home, 'Library', 'Application Support', 'VSCodium', 'User', 'settings.json'), path.join(home, '.vscodium', 'extensions'));
    pushTarget(targets, path.join(home, 'Library', 'Application Support', 'Cursor', 'User', 'settings.json'), path.join(home, '.cursor', 'extensions'));
  }

  if (xdgConfig) {
    pushTarget(targets, path.join(xdgConfig, 'Code', 'User', 'settings.json'), home ? path.join(home, '.vscode', 'extensions') : '');
    pushTarget(targets, path.join(xdgConfig, 'Code - Insiders', 'User', 'settings.json'), home ? path.join(home, '.vscode-insiders', 'extensions') : '');
    pushTarget(targets, path.join(xdgConfig, 'VSCodium', 'User', 'settings.json'), home ? path.join(home, '.vscodium', 'extensions') : '');
    pushTarget(targets, path.join(xdgConfig, 'Cursor', 'User', 'settings.json'), home ? path.join(home, '.cursor', 'extensions') : '');
  }

  return Array.from(new Set(targets.map((item) => path.resolve(item))));
}

function readString(source, start) {
  let i = start + 1;
  while (i < source.length) {
    const ch = source[i];
    if (ch === '\\') {
      i += 2;
      continue;
    }
    if (ch === '"') {
      return { value: JSON.parse(source.slice(start, i + 1)), end: i + 1 };
    }
    i += 1;
  }
  fail('Unterminated string in VS Code settings.json.');
}

function skipTrivia(source, index) {
  let i = index;
  while (i < source.length) {
    if (/\s/.test(source[i])) {
      i += 1;
      continue;
    }
    if (source[i] === '/' && source[i + 1] === '/') {
      i += 2;
      while (i < source.length && source[i] !== '\n') i += 1;
      continue;
    }
    if (source[i] === '/' && source[i + 1] === '*') {
      i += 2;
      while (i < source.length && !(source[i] === '*' && source[i + 1] === '/')) i += 1;
      i += 2;
      continue;
    }
    break;
  }
  return i;
}

function scanValue(source, start) {
  let i = skipTrivia(source, start);
  const opener = source[i];
  if (opener === '"') return readString(source, i).end;
  if (opener === '{' || opener === '[') {
    const stack = [opener === '{' ? '}' : ']'];
    i += 1;
    while (i < source.length && stack.length) {
      if (source[i] === '"') {
        i = readString(source, i).end;
        continue;
      }
      if (source[i] === '/' && (source[i + 1] === '/' || source[i + 1] === '*')) {
        i = skipTrivia(source, i);
        continue;
      }
      if (source[i] === '{' || source[i] === '[') stack.push(source[i] === '{' ? '}' : ']');
      else if (source[i] === stack[stack.length - 1]) stack.pop();
      i += 1;
    }
    if (stack.length) fail('Unterminated value in VS Code settings.json.');
    return i;
  }
  while (i < source.length && source[i] !== ',' && source[i] !== '}') i += 1;
  return i;
}

function findRootClose(source) {
  const rootStart = source.indexOf('{');
  if (rootStart < 0) return -1;
  let i = rootStart + 1;
  let depth = 1;
  while (i < source.length) {
    if (source[i] === '"') {
      i = readString(source, i).end;
      continue;
    }
    if (source[i] === '/' && (source[i + 1] === '/' || source[i + 1] === '*')) {
      i = skipTrivia(source, i);
      continue;
    }
    if (source[i] === '{') depth += 1;
    else if (source[i] === '}') {
      depth -= 1;
      if (depth === 0) return i;
    }
    i += 1;
  }
  return -1;
}

function findTopLevelProperty(source, key) {
  const rootStart = source.indexOf('{');
  if (rootStart < 0) return null;
  let i = rootStart + 1;
  let depth = 1;
  while (i < source.length) {
    i = skipTrivia(source, i);
    if (i >= source.length) return null;
    if (source[i] === '"') {
      const token = readString(source, i);
      const colon = skipTrivia(source, token.end);
      if (depth === 1 && source[colon] === ':' && token.value === key) {
        const valueStart = skipTrivia(source, colon + 1);
        const valueEnd = scanValue(source, valueStart);
        return { propertyStart: i, valueStart, valueEnd };
      }
      i = token.end;
      continue;
    }
    if (source[i] === '{') depth += 1;
    else if (source[i] === '}') {
      depth -= 1;
      if (depth === 0) return null;
    }
    i += 1;
  }
  return null;
}

function removeTopLevelProperty(source, key) {
  const found = findTopLevelProperty(source, key);
  if (!found) return source;
  let end = skipTrivia(source, found.valueEnd);
  if (source[end] === ',') return source.slice(0, found.propertyStart) + source.slice(end + 1);
  let start = found.propertyStart;
  let cursor = start - 1;
  while (cursor >= 0 && /\s/.test(source[cursor])) cursor -= 1;
  if (source[cursor] === ',') start = cursor;
  return source.slice(0, start) + source.slice(found.valueEnd);
}

function stripJsonc(source) {
  let result = '';
  let i = 0;
  while (i < source.length) {
    if (source[i] === '"') {
      const token = readString(source, i);
      result += source.slice(i, token.end);
      i = token.end;
      continue;
    }
    if (source[i] === '/' && source[i + 1] === '/') {
      i += 2;
      while (i < source.length && source[i] !== '\n') i += 1;
      continue;
    }
    if (source[i] === '/' && source[i + 1] === '*') {
      i += 2;
      while (i < source.length && !(source[i] === '*' && source[i + 1] === '/')) i += 1;
      i += 2;
      continue;
    }
    result += source[i];
    i += 1;
  }
  return result.replace(/,\s*([}\]])/g, '$1');
}

function readEnvArray(source, filePath) {
  const found = findTopLevelProperty(source, keyName);
  if (!found) return { existed: false, value: [] };
  const rawValue = source.slice(found.valueStart, found.valueEnd);
  let parsed;
  try {
    parsed = JSON.parse(stripJsonc(rawValue));
  } catch (error) {
    fail(`Could not read ${keyName} in ${filePath}. Fix that JSON value first. ${error.message}`);
  }
  if (!Array.isArray(parsed)) fail(`${keyName} in ${filePath} must be an array.`);
  return { existed: true, value: parsed };
}

function hasObjectContent(source, rootStart, rootClose) {
  return stripJsonc(source.slice(rootStart + 1, rootClose)).trim().length > 0;
}

function setTopLevelProperty(source, key, value) {
  let text = source.trim().length ? source : '{\n}\n';
  if (!text.includes('{')) text = '{\n}\n';
  text = removeTopLevelProperty(text, key);
  if (value === null) return text;
  const rootStart = text.indexOf('{');
  const rootClose = findRootClose(text);
  if (rootStart < 0 || rootClose < 0) fail('VS Code settings.json must contain a JSON object.');
  const valueJson = JSON.stringify(value, null, 2).replace(/\n/g, '\n  ');
  const prefix = hasObjectContent(text, rootStart, rootClose) ? ',\n  ' : '\n  ';
  const propertyText = `${prefix}${JSON.stringify(key)}: ${valueJson}\n`;
  let insertAt = rootClose;
  while (insertAt > rootStart + 1 && /\s/.test(text[insertAt - 1])) insertAt -= 1;
  return text.slice(0, insertAt) + propertyText + text.slice(rootClose);
}

function statePathFor(settingsPath) {
  return path.join(path.dirname(settingsPath), stateFileName);
}

function updateSettingsFile(settingsPath) {
  let source = fileExists(settingsPath) ? fs.readFileSync(settingsPath, 'utf8') : '{\n}\n';
  const statePath = statePathFor(settingsPath);
  const current = readEnvArray(source, settingsPath);
  let nextValue = null;
  let removeState = false;

  if (mode === 'litellm') {
    for (const [name, value] of [
      ['ANTHROPIC_BASE_URL', baseUrl],
      ['ANTHROPIC_AUTH_TOKEN', authToken],
      ['ANTHROPIC_MODEL', model],
    ]) {
      if (/[\r\n]/.test(value)) fail(`Cannot save ${name} because the value contains a newline.`);
    }
    if (!fileExists(statePath)) {
      fs.mkdirSync(path.dirname(statePath), { recursive: true });
      fs.writeFileSync(statePath, `${JSON.stringify({
        version: 1,
        settingsPath,
        existed: current.existed,
        value: current.existed ? current.value : null,
      }, null, 2)}\n`, 'utf8');
    }
    nextValue = current.value.filter((item) => !item || !managedNames.has(String(item.name || '')));
    nextValue.push({ name: 'ANTHROPIC_BASE_URL', value: baseUrl });
    nextValue.push({ name: 'ANTHROPIC_AUTH_TOKEN', value: authToken });
    nextValue.push({ name: 'ANTHROPIC_MODEL', value: model });
  } else if (mode === 'default') {
    if (fileExists(statePath)) {
      const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
      nextValue = state.existed ? state.value : null;
      removeState = true;
    } else {
      nextValue = current.value.filter((item) => !item || !managedNames.has(String(item.name || '')));
      if (nextValue.length === 0) nextValue = null;
    }
  } else {
    fail(`Unknown VS Code mode: ${mode}`);
  }

  source = setTopLevelProperty(source, keyName, nextValue);
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, source.endsWith('\n') ? source : `${source}\n`, 'utf8');
  if (removeState && fileExists(statePath)) fs.unlinkSync(statePath);
  console.log(settingsPath);
}

const targets = discoverTargets();
for (const target of targets) updateSettingsFile(target);
NODE
}

exec_target() {
  local command_name
  command_name="$(target_command)"
  if [ "$CLAUDE_ARG_COUNT" -gt 0 ]; then
    exec "$command_name" "${CLAUDE_ARGS[@]}"
  fi

  exec "$command_name"
}

test_target_command() {
  local command_name
  command_name="$(target_command)"
  if command -v "$command_name" >/dev/null 2>&1 || [ -f "$command_name" ]; then
    printf 'OK %s command: ' "$command_name"
    "$command_name" --version
    return $?
  fi

  printf 'FAIL %s command: not found on PATH\n' "$command_name" >&2
  return 1
}

print_vscode_restart_warning() {
  if [ "$RUN_CODE" -eq 1 ]; then
    printf 'WARN If VS Code is already running, restart it or open a fresh window from this command so extensions inherit this environment.\n' >&2
  fi
}

if [ "$RUN_CODE" -eq 1 ]; then
  if [ "$CODE_COMMAND_SET" -eq 1 ]; then
    TARGET_COMMAND="$(trim "$CODE_COMMAND")"
    [ -n "$TARGET_COMMAND" ] || die "Code command cannot be empty."
  else
    TARGET_COMMAND="$(resolve_code_command)"
  fi
  TARGET_LABEL="VS Code"
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
  for warning in "${WARNINGS[@]}"; do
    printf 'WARN %s\n' "$warning" >&2
  done
fi

if [ "$USE_DEFAULT_CLAUDE" -eq 1 ] && {
  [ "$BASE_URL_SET" -eq 1 ] ||
  [ "$AUTH_TOKEN_SET" -eq 1 ] ||
  [ "$MODEL_SET" -eq 1 ] ||
  [ -n "$(trim "$TOKEN_ENV")" ]
}; then
  printf 'WARN LiteLLM connection options are ignored in --default mode.\n' >&2
fi

if [ "$USE_DEFAULT_CLAUDE" -eq 1 ] && [ "$SAVE_CONFIG" -eq 1 ]; then
  die "--save is only for LiteLLM mode. Use default mode only when you want normal Claude settings for this run."
fi

if [ "$SAVE_CONFIG" -eq 1 ] && {
  [ "$PRINT_ENV" -eq 1 ] ||
  [ "$DRY_RUN" -eq 1 ] ||
  [ "$DOCTOR" -eq 1 ]
}; then
  die "--save cannot be combined with --print-env, --dry-run, or --doctor."
fi

if [ "$SAVE_GLOBAL_CONFIG" -eq 1 ] && {
  [ "$PRINT_ENV" -eq 1 ] ||
  [ "$DRY_RUN" -eq 1 ] ||
  [ "$DOCTOR" -eq 1 ]
}; then
  die "--global cannot be combined with --print-env, --dry-run, or --doctor."
fi

if [ "$SKIP_VSCODE_CONFIG" -eq 1 ]; then
  SAVE_VSCODE_CONFIG=0
fi

if [ "$USE_DEFAULT_CLAUDE" -eq 1 ]; then
  if [ "$SAVE_GLOBAL_CONFIG" -eq 1 ]; then
    saved_settings_path="$(save_claude_settings_mode default)"
    printf 'Saved global default Claude mode to %s\n' "$saved_settings_path"
    if [ "$SAVE_VSCODE_CONFIG" -eq 1 ]; then
      vscode_settings_output="$(save_vscode_extension_settings_mode default)"
      if [ -n "$vscode_settings_output" ]; then
        while IFS= read -r settings_path; do
          [ -n "$settings_path" ] && printf 'Saved VS Code Claude extension default mode to %s\n' "$settings_path"
        done <<EOF
$vscode_settings_output
EOF
      else
        printf 'No VS Code Claude extension settings found to update.\n'
      fi
    fi
    printf 'Close and reopen Claude Code or VS Code so the change is picked up.\n'
    exit 0
  fi

  if [ "$PRINT_ENV" -eq 1 ]; then
    printf 'unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_API_KEY\n'
    print_exec_line
    exit 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Dry run. %s was not launched.\n' "$(target_label)"
    printf 'Mode=default %s\n' "$(target_label)"
    printf 'ANTHROPIC_BASE_URL=(cleared)\n'
    printf 'ANTHROPIC_AUTH_TOKEN=(cleared)\n'
    printf 'ANTHROPIC_MODEL=(cleared)\n'
    printf 'ANTHROPIC_API_KEY=(cleared)\n'
    print_command
    exit 0
  fi

  if [ "$DOCTOR" -eq 1 ]; then
    ok=0
    printf '%s default doctor\n' "$(target_label)"
    test_target_command || ok=1
    if [ "$SKIP_HEALTH" -eq 1 ]; then
      printf 'SKIP LiteLLM health check\n'
    else
      printf 'SKIP LiteLLM health check: default Claude mode does not use LiteLLM.\n'
    fi
    exit "$ok"
  fi

  if ! command -v "$(target_command)" >/dev/null 2>&1 && [ ! -f "$(target_command)" ]; then
    die "Could not find the $(target_command) command on PATH."
  fi

  clear_anthropic_process_env
  printf 'Switched %s to default config (ANTHROPIC_* env vars cleared for this run).\n' "$(target_label)"
  print_vscode_restart_warning
  exec_target
fi

TOKEN_ENV="$(trim "$TOKEN_ENV")"
if [ -n "$TOKEN_ENV" ]; then
  valid_env_name "$TOKEN_ENV" || die "Token environment variable name is invalid: $TOKEN_ENV"
fi

load_env_file

if [ "$BASE_URL_SET" -eq 1 ]; then
  RESOLVED_BASE_URL="$BASE_URL"
elif value="$(first_nonblank_env CLAUDE_LITELLM_BASE_URL)"; then
  RESOLVED_BASE_URL="$value"
else
  RESOLVED_BASE_URL="$DEFAULT_BASE_URL"
fi
RESOLVED_BASE_URL="$(normalize_base_url "$RESOLVED_BASE_URL")"

if [ "$MODEL_SET" -eq 1 ]; then
  RESOLVED_MODEL="$MODEL"
elif value="$(first_nonblank_env CLAUDE_LITELLM_MODEL)"; then
  RESOLVED_MODEL="$value"
else
  RESOLVED_MODEL="$DEFAULT_MODEL"
fi
RESOLVED_MODEL="$(trim "$RESOLVED_MODEL")"
[ -n "$RESOLVED_MODEL" ] || die "Model cannot be empty. Pass --model or set CLAUDE_LITELLM_MODEL."

if [ "$AUTH_TOKEN_SET" -eq 1 ]; then
  RESOLVED_AUTH_TOKEN="$AUTH_TOKEN"
elif [ -n "$TOKEN_ENV" ]; then
  if [ -z "${!TOKEN_ENV+x}" ]; then
    die "Token environment variable \"$TOKEN_ENV\" was not found."
  fi
  RESOLVED_AUTH_TOKEN="${!TOKEN_ENV}"
elif value="$(first_nonblank_env CLAUDE_LITELLM_AUTH_TOKEN ANTHROPIC_AUTH_TOKEN LITELLM_TEST_KEY LITELLM_MASTER_KEY)"; then
  RESOLVED_AUTH_TOKEN="$value"
else
  RESOLVED_AUTH_TOKEN=""
fi

if [ "$SAVE_CONFIG" -eq 1 ] || [ "$SAVE_GLOBAL_CONFIG" -eq 1 ]; then
  if [ -z "$RESOLVED_AUTH_TOKEN" ]; then
    printf 'WARN Saving an empty token. This only works if the LiteLLM proxy allows unauthenticated requests.\n' >&2
  fi

  if [ "$SAVE_CONFIG" -eq 1 ]; then
    save_litellm_config "$ENV_FILE"
    printf 'Saved LiteLLM settings to %s\n' "$ENV_FILE"
  fi

  if [ "$SAVE_GLOBAL_CONFIG" -eq 1 ]; then
    saved_settings_path="$(save_claude_settings_mode litellm)"
    printf 'Saved global LiteLLM mode to %s\n' "$saved_settings_path"
    if [ "$SAVE_VSCODE_CONFIG" -eq 1 ]; then
      vscode_settings_output="$(save_vscode_extension_settings_mode litellm)"
      if [ -n "$vscode_settings_output" ]; then
        while IFS= read -r settings_path; do
          [ -n "$settings_path" ] && printf 'Saved VS Code Claude extension LiteLLM mode to %s\n' "$settings_path"
        done <<EOF
$vscode_settings_output
EOF
      else
        printf 'No VS Code Claude extension settings found to update.\n'
      fi
    fi
    printf 'Close and reopen Claude Code or VS Code so the change is picked up.\n'
  else
    printf 'Next time you can run this script without passing --token, --model, or --base-url.\n'
  fi
  exit 0
fi

if [ "$PRINT_ENV" -eq 1 ]; then
  printf 'unset ANTHROPIC_API_KEY\n'
  printf 'export ANTHROPIC_BASE_URL=%s\n' "$(quote_bash "$RESOLVED_BASE_URL")"
  printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' "$(quote_bash "$RESOLVED_AUTH_TOKEN")"
  printf 'export ANTHROPIC_MODEL=%s\n' "$(quote_bash "$RESOLVED_MODEL")"
  print_exec_line
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Dry run. %s was not launched.\n' "$(target_label)"
  printf 'ANTHROPIC_BASE_URL=%s\n' "$RESOLVED_BASE_URL"
  printf 'ANTHROPIC_AUTH_TOKEN=%s\n' "$(redact "$RESOLVED_AUTH_TOKEN")"
  printf 'ANTHROPIC_MODEL=%s\n' "$RESOLVED_MODEL"
  print_command
  exit 0
fi

if [ "$DOCTOR" -eq 1 ]; then
  ok=0
  printf '%s LiteLLM doctor\n' "$(target_label)"
  printf 'Base URL: %s\n' "$RESOLVED_BASE_URL"
  printf 'Model: %s\n' "$RESOLVED_MODEL"
  printf 'Token: %s\n' "$(redact "$RESOLVED_AUTH_TOKEN")"

  test_target_command || ok=1

  if [ "$SKIP_HEALTH" -eq 1 ]; then
    printf 'SKIP LiteLLM health check\n'
  elif command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 5 "$RESOLVED_BASE_URL/health" >/dev/null; then
      printf 'OK LiteLLM health: %s/health\n' "$RESOLVED_BASE_URL"
    else
      printf 'FAIL LiteLLM health: %s/health\n' "$RESOLVED_BASE_URL" >&2
      ok=1
    fi
  else
    printf 'SKIP LiteLLM health check: curl is not available\n'
  fi

  if [ -z "$RESOLVED_AUTH_TOKEN" ]; then
    printf 'WARN ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests.\n' >&2
  fi
  exit "$ok"
fi

if ! command -v "$(target_command)" >/dev/null 2>&1 && [ ! -f "$(target_command)" ]; then
  die "Could not find the $(target_command) command on PATH."
fi

if [ -z "$RESOLVED_AUTH_TOKEN" ]; then
  printf 'WARN ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests.\n' >&2
fi

export ANTHROPIC_BASE_URL="$RESOLVED_BASE_URL"
export ANTHROPIC_AUTH_TOKEN="$RESOLVED_AUTH_TOKEN"
export ANTHROPIC_MODEL="$RESOLVED_MODEL"
unset ANTHROPIC_API_KEY

printf 'Switched %s to LiteLLM (%s, model %s, token %s)\n' \
  "$(target_label)" \
  "$ANTHROPIC_BASE_URL" \
  "$ANTHROPIC_MODEL" \
  "$(redact "$ANTHROPIC_AUTH_TOKEN")"
print_vscode_restart_warning

exec_target
