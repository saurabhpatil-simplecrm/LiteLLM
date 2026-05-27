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
USE_DEFAULT_CLAUDE=0
HELP=0
CLAUDE_ARGS=()
WARNINGS=()
CLAUDE_ARG_COUNT=0
WARNING_COUNT=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/claude-litellm.sh [wrapper options] [--claude claude args...]

Runs Claude Code with Anthropic-compatible LiteLLM environment variables by default,
or clears those variables and runs normal Claude with --default.

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
      --doctor               Check config and claude command, then exit
      --skip-health          Skip optional /health check when used with --doctor
      --print-env            Print export commands, then exit
      --default, --reset     Clear Anthropic env vars and run normal Claude
      --claude               Treat the rest of the line as Claude args
  -h, --help                 Show this help

Examples:
  bash scripts/claude-litellm.sh
  bash scripts/claude-litellm.sh litellm
  bash scripts/claude-litellm.sh --token sk-your-key --model zai.glm-5
  bash scripts/claude-litellm.sh --default
  bash scripts/claude-litellm.sh default
  bash scripts/claude-litellm.sh --dry-run --claude --print "hello"
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
    --|--claude)
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
    --default|--reset|--claude-default)
      USE_DEFAULT_CLAUDE=1
      ;;
    --help|-h)
      HELP=1
      ;;
    -*)
      append_warning "Treating \"$arg\" and the remaining arguments as Claude args. Put wrapper flags first or separate Claude args with \"--\"."
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
  local raw line key value
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
        if [ -z "${!key+x}" ]; then
          export "$key=$value"
        fi
        ;;
    esac
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

print_command() {
  local item
  printf 'Command: claude'
  if [ "$CLAUDE_ARG_COUNT" -gt 0 ]; then
    for item in "${CLAUDE_ARGS[@]}"; do
      printf ' %q' "$item"
    done
  fi
  printf '\n'
}

clear_anthropic_process_env() {
  unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL
}

exec_claude() {
  if [ "$CLAUDE_ARG_COUNT" -gt 0 ]; then
    exec claude "${CLAUDE_ARGS[@]}"
  fi

  exec claude
}

test_claude_command() {
  if command -v claude >/dev/null 2>&1; then
    printf 'OK claude command: '
    claude --version
    return $?
  fi

  printf 'FAIL claude command: not found on PATH\n' >&2
  return 1
}

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

if [ "$USE_DEFAULT_CLAUDE" -eq 1 ]; then
  if [ "$PRINT_ENV" -eq 1 ]; then
    printf 'unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL\n'
    printf 'claude\n'
    exit 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Dry run. Claude was not launched.\n'
    printf 'Mode=default Claude\n'
    printf 'ANTHROPIC_BASE_URL=(cleared)\n'
    printf 'ANTHROPIC_AUTH_TOKEN=(cleared)\n'
    printf 'ANTHROPIC_MODEL=(cleared)\n'
    print_command
    exit 0
  fi

  if [ "$DOCTOR" -eq 1 ]; then
    ok=0
    printf 'Claude default doctor\n'
    test_claude_command || ok=1
    if [ "$SKIP_HEALTH" -eq 1 ]; then
      printf 'SKIP LiteLLM health check\n'
    else
      printf 'SKIP LiteLLM health check: default Claude mode does not use LiteLLM.\n'
    fi
    exit "$ok"
  fi

  if ! command -v claude >/dev/null 2>&1; then
    die "Could not find the claude command on PATH."
  fi

  clear_anthropic_process_env
  printf 'Switched Claude to default config (ANTHROPIC_* env vars cleared for this run).\n'
  exec_claude
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
elif [ -n "$(trim "$TOKEN_ENV")" ]; then
  TOKEN_ENV="$(trim "$TOKEN_ENV")"
  valid_env_name "$TOKEN_ENV" || die "Token environment variable name is invalid: $TOKEN_ENV"
  if [ -z "${!TOKEN_ENV+x}" ]; then
    die "Token environment variable \"$TOKEN_ENV\" was not found."
  fi
  RESOLVED_AUTH_TOKEN="${!TOKEN_ENV}"
elif value="$(first_nonblank_env CLAUDE_LITELLM_AUTH_TOKEN ANTHROPIC_AUTH_TOKEN LITELLM_TEST_KEY LITELLM_MASTER_KEY)"; then
  RESOLVED_AUTH_TOKEN="$value"
else
  RESOLVED_AUTH_TOKEN=""
fi

if [ "$PRINT_ENV" -eq 1 ]; then
  printf 'export ANTHROPIC_BASE_URL=%s\n' "$(quote_bash "$RESOLVED_BASE_URL")"
  printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' "$(quote_bash "$RESOLVED_AUTH_TOKEN")"
  printf 'export ANTHROPIC_MODEL=%s\n' "$(quote_bash "$RESOLVED_MODEL")"
  printf 'claude\n'
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Dry run. Claude was not launched.\n'
  printf 'ANTHROPIC_BASE_URL=%s\n' "$RESOLVED_BASE_URL"
  printf 'ANTHROPIC_AUTH_TOKEN=%s\n' "$(redact "$RESOLVED_AUTH_TOKEN")"
  printf 'ANTHROPIC_MODEL=%s\n' "$RESOLVED_MODEL"
  print_command
  exit 0
fi

if [ "$DOCTOR" -eq 1 ]; then
  ok=0
  printf 'Claude LiteLLM doctor\n'
  printf 'Base URL: %s\n' "$RESOLVED_BASE_URL"
  printf 'Model: %s\n' "$RESOLVED_MODEL"
  printf 'Token: %s\n' "$(redact "$RESOLVED_AUTH_TOKEN")"

  test_claude_command || ok=1

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

if ! command -v claude >/dev/null 2>&1; then
  die "Could not find the claude command on PATH."
fi

if [ -z "$RESOLVED_AUTH_TOKEN" ]; then
  printf 'WARN ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests.\n' >&2
fi

export ANTHROPIC_BASE_URL="$RESOLVED_BASE_URL"
export ANTHROPIC_AUTH_TOKEN="$RESOLVED_AUTH_TOKEN"
export ANTHROPIC_MODEL="$RESOLVED_MODEL"

printf 'Switched Claude to LiteLLM (%s, model %s, token %s)\n' \
  "$ANTHROPIC_BASE_URL" \
  "$ANTHROPIC_MODEL" \
  "$(redact "$ANTHROPIC_AUTH_TOKEN")"

exec_claude
