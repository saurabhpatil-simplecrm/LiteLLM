$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$DefaultBaseUrl = "http://172.22.11.114:4000"
$DefaultModel = "zai.glm-5"

$BaseUrl = $null
$BaseUrlSet = $false
$AuthToken = $null
$AuthTokenSet = $false
$TokenEnv = $null
$Model = $null
$ModelSet = $false
$EnvFile = ".env"
$LoadEnvFile = $true
$DryRun = $false
$Doctor = $false
$SkipHealth = $false
$PrintEnv = $false
$UseDefaultClaude = $false
$ShowHelp = $false
$ClaudeArgs = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()
$InputArgs = @($args)

function Show-Usage {
    @"
Usage:
  .\scripts\claude-litellm.ps1 [wrapper options] [--claude claude args...]

Runs Claude Code with Anthropic-compatible LiteLLM environment variables by default,
or clears those variables and runs normal Claude with --default.

Defaults:
  base URL: $DefaultBaseUrl
  model:    $DefaultModel
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
      --doctor               Check config, claude command, and LiteLLM /health
      --skip-health          Skip /health check when used with --doctor
      --print-env            Print PowerShell env commands, then exit
      --default, --reset     Clear Anthropic env vars and run normal Claude
      --claude               Treat the rest of the line as Claude args
  -h, --help                 Show this help

Examples:
  .\scripts\claude-litellm.ps1
  .\scripts\claude-litellm.ps1 litellm
  .\scripts\claude-litellm.ps1 --token sk-your-key --model zai.glm-5
  .\scripts\claude-litellm.ps1 --default
  .\scripts\claude-litellm.ps1 default
  .\scripts\claude-litellm.ps1 --dry-run --claude --print "hello"
  .\scripts\claude-litellm.ps1 --print-env
"@
}

function Read-RequiredValue {
    param(
        [string[]]$Values,
        [int]$Index,
        [string]$Flag
    )

    $nextIndex = $Index + 1
    if ($nextIndex -ge $Values.Count) {
        throw "Missing value for $Flag."
    }

    return [string]$Values[$nextIndex]
}

function Add-RemainingClaudeArgs {
    param(
        [string[]]$Values,
        [int]$StartIndex
    )

    for ($item = $StartIndex; $item -lt $Values.Count; $item++) {
        $ClaudeArgs.Add([string]$Values[$item]) | Out-Null
    }
}

:parse for ($i = 0; $i -lt $InputArgs.Count; $i++) {
    $arg = [string]$InputArgs[$i]

    if ($arg -eq "--" -or $arg -eq "--claude") {
        Add-RemainingClaudeArgs -Values $InputArgs -StartIndex ($i + 1)
        break parse
    }

    if ($arg -in @("default", "reset", "off", "claude-default")) {
        $UseDefaultClaude = $true
        continue
    }

    if ($arg -in @("litellm", "on")) {
        continue
    }

    if ($arg.StartsWith("--base-url=")) {
        $BaseUrl = $arg.Substring("--base-url=".Length)
        $BaseUrlSet = $true
        continue
    }
    if ($arg.StartsWith("--token=")) {
        $AuthToken = $arg.Substring("--token=".Length)
        $AuthTokenSet = $true
        continue
    }
    if ($arg.StartsWith("--auth-token=")) {
        $AuthToken = $arg.Substring("--auth-token=".Length)
        $AuthTokenSet = $true
        continue
    }
    if ($arg.StartsWith("--token-env=")) {
        $TokenEnv = $arg.Substring("--token-env=".Length)
        continue
    }
    if ($arg.StartsWith("--model=")) {
        $Model = $arg.Substring("--model=".Length)
        $ModelSet = $true
        continue
    }
    if ($arg.StartsWith("--env-file=")) {
        $EnvFile = $arg.Substring("--env-file=".Length)
        continue
    }

    switch ($arg) {
        { $_ -in @("--base-url", "-u") } {
            $BaseUrl = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            $BaseUrlSet = $true
            $i++
            continue
        }
        { $_ -in @("--token", "--auth-token", "-t") } {
            $AuthToken = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            $AuthTokenSet = $true
            $i++
            continue
        }
        "--token-env" {
            $TokenEnv = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            $i++
            continue
        }
        { $_ -in @("--model", "-m") } {
            $Model = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            $ModelSet = $true
            $i++
            continue
        }
        "--env-file" {
            $EnvFile = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            $i++
            continue
        }
        "--no-env-file" {
            $LoadEnvFile = $false
            continue
        }
        "--dry-run" {
            $DryRun = $true
            continue
        }
        "--doctor" {
            $Doctor = $true
            continue
        }
        "--skip-health" {
            $SkipHealth = $true
            continue
        }
        "--print-env" {
            $PrintEnv = $true
            continue
        }
        { $_ -in @("--default", "--reset", "--claude-default") } {
            $UseDefaultClaude = $true
            continue
        }
        { $_ -in @("--help", "-h") } {
            $ShowHelp = $true
            continue
        }
        default {
            if ($arg.StartsWith("-")) {
                $Warnings.Add("Treating `"$arg`" and the remaining arguments as Claude args. Put wrapper flags first or separate Claude args with `"--`".") | Out-Null
            }
            Add-RemainingClaudeArgs -Values $InputArgs -StartIndex $i
            break parse
        }
    }
}

if ($ShowHelp) {
    Show-Usage
    exit 0
}

function Test-NonBlank {
    param([AllowNull()][string]$Value)
    return $null -ne $Value -and $Value.Trim().Length -gt 0
}

function Test-EnvName {
    param([string]$Name)
    return $Name -match "^[A-Za-z_][A-Za-z0-9_]*$"
}

function Read-EnvFile {
    param([string]$Path)

    $values = @{}
    if (-not $LoadEnvFile -or -not (Test-Path -LiteralPath $Path)) {
        return $values
    }

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith("#")) {
            continue
        }
        if ($line.StartsWith("export ")) {
            $line = $line.Substring("export ".Length).Trim()
        }

        $equalsAt = $line.IndexOf("=")
        if ($equalsAt -lt 1) {
            continue
        }

        $key = $line.Substring(0, $equalsAt).Trim()
        if ($key -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") {
            continue
        }

        $value = $line.Substring($equalsAt + 1).Trim()
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $values[$key] = $value
    }

    return $values
}

function Get-RawConfigValue {
    param(
        [string]$Name,
        [hashtable]$EnvFileValues
    )

    $processValue = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ($null -ne $processValue) {
        return $processValue
    }

    if ($EnvFileValues.ContainsKey($Name)) {
        return [string]$EnvFileValues[$Name]
    }

    return $null
}

function Get-FirstConfigValue {
    param(
        [string[]]$Names,
        [hashtable]$EnvFileValues,
        [AllowNull()][string]$Fallback
    )

    foreach ($name in $Names) {
        $value = [Environment]::GetEnvironmentVariable($name, "Process")
        if (Test-NonBlank $value) {
            return $value
        }
    }

    foreach ($name in $Names) {
        if ($EnvFileValues.ContainsKey($name) -and (Test-NonBlank ([string]$EnvFileValues[$name]))) {
            return [string]$EnvFileValues[$name]
        }
    }

    return $Fallback
}

function Normalize-BaseUrl {
    param([string]$Value)

    if (-not (Test-NonBlank $Value)) {
        throw "Base URL cannot be empty. Pass --base-url or set CLAUDE_LITELLM_BASE_URL."
    }

    $trimmed = $Value.Trim().TrimEnd("/")
    try {
        $uri = [Uri]$trimmed
    } catch {
        throw "Base URL is not valid: $Value"
    }

    if (-not $uri.IsAbsoluteUri -or $uri.Scheme -notin @("http", "https")) {
        throw "Base URL must use http or https: $Value"
    }

    return $trimmed
}

function Redact-Token {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return "(empty)"
    }

    if ($Value.Length -le 8) {
        return "****"
    }

    return "$($Value.Substring(0, 4))...$($Value.Substring($Value.Length - 4))"
}

function Quote-PowerShellValue {
    param([AllowNull()][string]$Value)
    return "'$(([string]$Value).Replace("'", "''"))'"
}

function Format-CommandLine {
    param([string[]]$Arguments)

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("claude") | Out-Null
    foreach ($argument in $Arguments) {
        if ($argument -match "^[A-Za-z0-9_./:=@-]+$") {
            $parts.Add($argument) | Out-Null
        } else {
            $escaped = $argument.Replace('`', '``').Replace('"', '`"')
            $parts.Add("`"$escaped`"") | Out-Null
        }
    }
    return ($parts -join " ")
}

function Clear-AnthropicProcessEnv {
    Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL -ErrorAction SilentlyContinue
}

function Test-ClaudeCommand {
    $claudeCommand = Get-Command claude -ErrorAction SilentlyContinue
    if ($null -eq $claudeCommand) {
        [Console]::Error.WriteLine("FAIL claude command: not found on PATH")
        return $false
    }

    $versionOutput = & claude --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK claude command: $versionOutput"
        return $true
    }

    [Console]::Error.WriteLine("FAIL claude command: $versionOutput")
    return $false
}

foreach ($warning in $Warnings) {
    Write-Warning $warning
}

if ($UseDefaultClaude -and ($BaseUrlSet -or $AuthTokenSet -or $ModelSet -or (Test-NonBlank $TokenEnv))) {
    Write-Warning "LiteLLM connection options are ignored in --default mode."
}

if ($UseDefaultClaude) {
    if ($PrintEnv) {
        Write-Output "Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL -ErrorAction SilentlyContinue"
        Write-Output "claude"
        exit 0
    }

    if ($DryRun) {
        Write-Host "Dry run. Claude was not launched."
        Write-Host "Mode=default Claude"
        Write-Host "ANTHROPIC_BASE_URL=(cleared)"
        Write-Host "ANTHROPIC_AUTH_TOKEN=(cleared)"
        Write-Host "ANTHROPIC_MODEL=(cleared)"
        Write-Host "Command: $(Format-CommandLine $ClaudeArgs.ToArray())"
        exit 0
    }

    if ($Doctor) {
        $ok = $true
        Write-Host "Claude default doctor"
        if (-not (Test-ClaudeCommand)) {
            $ok = $false
        }
        if ($SkipHealth) {
            Write-Host "SKIP LiteLLM health check"
        } else {
            Write-Host "SKIP LiteLLM health check: default Claude mode does not use LiteLLM."
        }
        if ($ok) {
            exit 0
        }
        exit 1
    }

    $claudeCommandForDefaultRun = Get-Command claude -ErrorAction SilentlyContinue
    if ($null -eq $claudeCommandForDefaultRun) {
        throw "Could not find the claude command on PATH."
    }

    Clear-AnthropicProcessEnv
    Write-Host "Switched Claude to default config (ANTHROPIC_* env vars cleared for this run)."
    & claude @($ClaudeArgs.ToArray())
    exit $LASTEXITCODE
}

$EnvFileValues = Read-EnvFile -Path $EnvFile

if ($BaseUrlSet) {
    $ResolvedBaseUrl = $BaseUrl
} else {
    $ResolvedBaseUrl = Get-FirstConfigValue `
        -Names @("CLAUDE_LITELLM_BASE_URL") `
        -EnvFileValues $EnvFileValues `
        -Fallback $DefaultBaseUrl
}
$ResolvedBaseUrl = Normalize-BaseUrl $ResolvedBaseUrl

if ($ModelSet) {
    $ResolvedModel = $Model
} else {
    $ResolvedModel = Get-FirstConfigValue `
        -Names @("CLAUDE_LITELLM_MODEL") `
        -EnvFileValues $EnvFileValues `
        -Fallback $DefaultModel
}
if (-not (Test-NonBlank $ResolvedModel)) {
    throw "Model cannot be empty. Pass --model or set CLAUDE_LITELLM_MODEL."
}
$ResolvedModel = $ResolvedModel.Trim()

if ($AuthTokenSet) {
    $ResolvedAuthToken = $AuthToken
} elseif (Test-NonBlank $TokenEnv) {
    $ResolvedTokenEnv = $TokenEnv.Trim()
    if (-not (Test-EnvName $ResolvedTokenEnv)) {
        throw "Token environment variable name is invalid: $ResolvedTokenEnv"
    }

    $rawToken = Get-RawConfigValue -Name $ResolvedTokenEnv -EnvFileValues $EnvFileValues
    if ($null -eq $rawToken) {
        throw "Token environment variable `"$ResolvedTokenEnv`" was not found."
    }
    $ResolvedAuthToken = $rawToken
} else {
    $ResolvedAuthToken = Get-FirstConfigValue `
        -Names @("CLAUDE_LITELLM_AUTH_TOKEN", "ANTHROPIC_AUTH_TOKEN", "LITELLM_TEST_KEY", "LITELLM_MASTER_KEY") `
        -EnvFileValues $EnvFileValues `
        -Fallback ""
}

if ($PrintEnv) {
    Write-Output "`$env:ANTHROPIC_BASE_URL = $(Quote-PowerShellValue $ResolvedBaseUrl)"
    Write-Output "`$env:ANTHROPIC_AUTH_TOKEN = $(Quote-PowerShellValue $ResolvedAuthToken)"
    Write-Output "`$env:ANTHROPIC_MODEL = $(Quote-PowerShellValue $ResolvedModel)"
    Write-Output "claude"
    exit 0
}

if ($DryRun) {
    Write-Host "Dry run. Claude was not launched."
    Write-Host "ANTHROPIC_BASE_URL=$ResolvedBaseUrl"
    Write-Host "ANTHROPIC_AUTH_TOKEN=$(Redact-Token $ResolvedAuthToken)"
    Write-Host "ANTHROPIC_MODEL=$ResolvedModel"
    Write-Host "Command: $(Format-CommandLine $ClaudeArgs.ToArray())"
    exit 0
}

if ($Doctor) {
    $ok = $true
    Write-Host "Claude LiteLLM doctor"
    Write-Host "Base URL: $ResolvedBaseUrl"
    Write-Host "Model: $ResolvedModel"
    Write-Host "Token: $(Redact-Token $ResolvedAuthToken)"

    if (-not (Test-ClaudeCommand)) {
        $ok = $false
    }

    if ($SkipHealth) {
        Write-Host "SKIP LiteLLM health check"
    } else {
        $healthUrl = "$ResolvedBaseUrl/health"
        try {
            Invoke-WebRequest -Method Get -Uri $healthUrl -UseBasicParsing -TimeoutSec 5 | Out-Null
            Write-Host "OK LiteLLM health: $healthUrl"
        } catch {
            [Console]::Error.WriteLine("FAIL LiteLLM health: $healthUrl ($($_.Exception.Message))")
            $ok = $false
        }
    }

    if ([string]::IsNullOrEmpty($ResolvedAuthToken)) {
        Write-Warning "ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests."
    }

    if ($ok) {
        exit 0
    }
    exit 1
}

$claudeCommandForRun = Get-Command claude -ErrorAction SilentlyContinue
if ($null -eq $claudeCommandForRun) {
    throw "Could not find the claude command on PATH."
}

if ([string]::IsNullOrEmpty($ResolvedAuthToken)) {
    Write-Warning "ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests."
}

$env:ANTHROPIC_BASE_URL = $ResolvedBaseUrl
$env:ANTHROPIC_AUTH_TOKEN = $ResolvedAuthToken
$env:ANTHROPIC_MODEL = $ResolvedModel

Write-Host "Switched Claude to LiteLLM ($ResolvedBaseUrl, model $ResolvedModel, token $(Redact-Token $ResolvedAuthToken))"

& claude @($ClaudeArgs.ToArray())
exit $LASTEXITCODE
