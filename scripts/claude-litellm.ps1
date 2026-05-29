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
$RunCode = $false
$CodeCommand = $null
$CodeCommandSet = $false
$ShowHelp = $false
$ClaudeArgs = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()
$InputArgs = @($args)

function Show-Usage {
    @"
Usage:
  .\scripts\claude-litellm.ps1 [wrapper options] [--args target args...]

Runs Claude Code, or VS Code with --code, using Anthropic-compatible LiteLLM
environment variables by default. Clears those variables for normal Claude with
--default.

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
      --doctor               Check config, target command, and LiteLLM /health
      --skip-health          Skip /health check when used with --doctor
      --print-env            Print PowerShell env commands, then exit
      --code, --vscode       Launch VS Code instead of claude with the selected env
      --code-command <cmd>    Use a custom VS Code command or path
      --default, --reset     Clear Anthropic env vars and run normal Claude
      --args, --claude       Treat the rest of the line as target command args
  -h, --help                 Show this help

Examples:
  .\scripts\claude-litellm.ps1
  .\scripts\claude-litellm.ps1 litellm
  .\scripts\claude-litellm.ps1 --token sk-your-key --model zai.glm-5
  .\scripts\claude-litellm.ps1 --default
  .\scripts\claude-litellm.ps1 default
  .\scripts\claude-litellm.ps1 --dry-run --args --print "hello"
  .\scripts\claude-litellm.ps1 --code --args --new-window .
  .\scripts\claude-litellm.ps1 --code-command code-insiders --args --new-window .
  .\scripts\claude-litellm.ps1 default --code --args --new-window .
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

    if ($arg -in @("--", "--args", "--target-args", "--claude")) {
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
    if ($arg.StartsWith("--code-command=") -or $arg.StartsWith("--vscode-command=")) {
        $CodeCommand = $arg.Substring($arg.IndexOf("=") + 1)
        $CodeCommandSet = $true
        $RunCode = $true
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
        { $_ -in @("--code-command", "--vscode-command") } {
            $CodeCommand = Read-RequiredValue -Values $InputArgs -Index $i -Flag $arg
            if ($CodeCommand -match "^\s*--") {
                throw "Missing value for $arg."
            }
            $CodeCommandSet = $true
            $RunCode = $true
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
        { $_ -in @("--code", "--vscode") } {
            $RunCode = $true
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
                $Warnings.Add("Treating `"$arg`" and the remaining arguments as target command args. Put wrapper flags first or separate target args with `"--args`".") | Out-Null
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

function Format-CommandPart {
    param([string]$Value)

    if ($Value -match "^[A-Za-z0-9_./:=@-]+$") {
        return $Value
    }

    $escaped = $Value.Replace('`', '``').Replace('"', '`"')
    return "`"$escaped`""
}

function Format-CommandLine {
    param(
        [string[]]$Arguments,
        [string]$Command = "claude"
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add((Format-CommandPart $Command)) | Out-Null
    foreach ($argument in $Arguments) {
        $parts.Add((Format-CommandPart $argument)) | Out-Null
    }
    return ($parts -join " ")
}

function Clear-AnthropicProcessEnv {
    Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL, Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
}

function Resolve-CodeCommand {
    $pathCommands = @("code", "code-insiders", "codium", "codium-insiders")
    foreach ($name in $pathCommands) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            if (Test-NonBlank $command.Source) {
                return $command.Source
            }
            if (Test-NonBlank $command.Path) {
                return $command.Path
            }
            return $name
        }
    }

    $candidates = [System.Collections.Generic.List[string]]::new()
    if (Test-NonBlank $env:LOCALAPPDATA) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd")) | Out-Null
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\Code.exe")) | Out-Null
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd")) | Out-Null
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code Insiders\Code - Insiders.exe")) | Out-Null
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\VSCodium\bin\codium.cmd")) | Out-Null
        $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\VSCodium\VSCodium.exe")) | Out-Null
    }
    if (Test-NonBlank $env:ProgramFiles) {
        $candidates.Add((Join-Path $env:ProgramFiles "Microsoft VS Code\bin\code.cmd")) | Out-Null
        $candidates.Add((Join-Path $env:ProgramFiles "Microsoft VS Code\Code.exe")) | Out-Null
    }
    if (Test-NonBlank ${env:ProgramFiles(x86)}) {
        $candidates.Add((Join-Path ${env:ProgramFiles(x86)} "Microsoft VS Code\bin\code.cmd")) | Out-Null
        $candidates.Add((Join-Path ${env:ProgramFiles(x86)} "Microsoft VS Code\Code.exe")) | Out-Null
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return "code"
}

function Test-ExternalCommand {
    param(
        [string]$Command,
        [string]$Label
    )

    $externalCommand = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $externalCommand) {
        [Console]::Error.WriteLine("FAIL $Label command: not found on PATH")
        return $false
    }

    $versionOutput = & $Command --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK $Label command: $((@($versionOutput) -join " ").Trim())"
        return $true
    }

    [Console]::Error.WriteLine("FAIL $Label command: $((@($versionOutput) -join " ").Trim())")
    return $false
}

function Test-TargetCommand {
    Test-ExternalCommand -Command $TargetCommand -Label $TargetCommandName
}

$TargetCommandName = if ($RunCode) { "code" } else { "claude" }
if ($RunCode -and $CodeCommandSet) {
    if (-not (Test-NonBlank $CodeCommand)) {
        throw "Code command cannot be empty."
    }
    $TargetCommand = $CodeCommand.Trim()
} elseif ($RunCode) {
    $TargetCommand = Resolve-CodeCommand
} else {
    $TargetCommand = "claude"
}
$TargetLabel = if ($RunCode) { "VS Code" } else { "Claude" }

foreach ($warning in $Warnings) {
    Write-Warning $warning
}

if ($UseDefaultClaude -and ($BaseUrlSet -or $AuthTokenSet -or $ModelSet -or (Test-NonBlank $TokenEnv))) {
    Write-Warning "LiteLLM connection options are ignored in --default mode."
}

if ($UseDefaultClaude) {
    if ($PrintEnv) {
        Write-Output "Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL, Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue"
        Write-Output "$(Format-CommandLine -Arguments $ClaudeArgs.ToArray() -Command $TargetCommand)"
        exit 0
    }

    if ($DryRun) {
        Write-Host "Dry run. $TargetLabel was not launched."
        Write-Host "Mode=default $TargetLabel"
        Write-Host "ANTHROPIC_BASE_URL=(cleared)"
        Write-Host "ANTHROPIC_AUTH_TOKEN=(cleared)"
        Write-Host "ANTHROPIC_MODEL=(cleared)"
        Write-Host "ANTHROPIC_API_KEY=(cleared)"
        Write-Host "Command: $(Format-CommandLine -Arguments $ClaudeArgs.ToArray() -Command $TargetCommand)"
        exit 0
    }

    if ($Doctor) {
        $ok = $true
        Write-Host "$TargetLabel default doctor"
        if (-not (Test-TargetCommand)) {
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

    $targetCommandForDefaultRun = Get-Command $TargetCommand -ErrorAction SilentlyContinue
    if ($null -eq $targetCommandForDefaultRun) {
        throw "Could not find the $TargetCommand command on PATH."
    }

    Clear-AnthropicProcessEnv
    Write-Host "Switched $TargetLabel to default config (ANTHROPIC_* env vars cleared for this run)."
    if ($RunCode) {
        Write-Warning "If VS Code is already running, restart it or open a fresh window from this command so extensions inherit this environment."
    }
    & $TargetCommand @($ClaudeArgs.ToArray())
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
    Write-Output "Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue"
    Write-Output "`$env:ANTHROPIC_BASE_URL = $(Quote-PowerShellValue $ResolvedBaseUrl)"
    Write-Output "`$env:ANTHROPIC_AUTH_TOKEN = $(Quote-PowerShellValue $ResolvedAuthToken)"
    Write-Output "`$env:ANTHROPIC_MODEL = $(Quote-PowerShellValue $ResolvedModel)"
    Write-Output "$(Format-CommandLine -Arguments $ClaudeArgs.ToArray() -Command $TargetCommand)"
    exit 0
}

if ($DryRun) {
    Write-Host "Dry run. $TargetLabel was not launched."
    Write-Host "ANTHROPIC_BASE_URL=$ResolvedBaseUrl"
    Write-Host "ANTHROPIC_AUTH_TOKEN=$(Redact-Token $ResolvedAuthToken)"
    Write-Host "ANTHROPIC_MODEL=$ResolvedModel"
    Write-Host "Command: $(Format-CommandLine -Arguments $ClaudeArgs.ToArray() -Command $TargetCommand)"
    exit 0
}

if ($Doctor) {
    $ok = $true
    Write-Host "$TargetLabel LiteLLM doctor"
    Write-Host "Base URL: $ResolvedBaseUrl"
    Write-Host "Model: $ResolvedModel"
    Write-Host "Token: $(Redact-Token $ResolvedAuthToken)"

    if (-not (Test-TargetCommand)) {
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

$targetCommandForRun = Get-Command $TargetCommand -ErrorAction SilentlyContinue
if ($null -eq $targetCommandForRun) {
    throw "Could not find the $TargetCommand command on PATH."
}

if ([string]::IsNullOrEmpty($ResolvedAuthToken)) {
    Write-Warning "ANTHROPIC_AUTH_TOKEN is empty. This only works if the proxy allows unauthenticated requests."
}

$env:ANTHROPIC_BASE_URL = $ResolvedBaseUrl
$env:ANTHROPIC_AUTH_TOKEN = $ResolvedAuthToken
$env:ANTHROPIC_MODEL = $ResolvedModel
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue

Write-Host "Switched $TargetLabel to LiteLLM ($ResolvedBaseUrl, model $ResolvedModel, token $(Redact-Token $ResolvedAuthToken))"
if ($RunCode) {
    Write-Warning "If VS Code is already running, restart it or open a fresh window from this command so extensions inherit this environment."
}

& $TargetCommand @($ClaudeArgs.ToArray())
exit $LASTEXITCODE
