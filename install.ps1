#Requires -Version 5.1
<#
.SYNOPSIS
    Installs PromptPad and configures it as the default $EDITOR.

.DESCRIPTION
    - Copies PromptPad.exe to %LOCALAPPDATA%\PromptPad\bin\
    - Adds that directory to the user's PATH (if not already present)
    - Sets the EDITOR environment variable to promptpad.exe

    Safe to run multiple times (idempotent).

.PARAMETER ExePath
    Path to the PromptPad.exe to install. If not specified, searches
    common publish output locations relative to this script.

.PARAMETER Uninstall
    Removes PromptPad from PATH and clears the EDITOR variable.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -ExePath "C:\Downloads\PromptPad.exe"
    .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$ExePath,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$InstallDir = Join-Path $env:LOCALAPPDATA 'PromptPad\bin'
$ExeName = 'PromptPad.exe'

function Write-Step($msg) { Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Done($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  [--] $msg" -ForegroundColor DarkGray }

# --- Uninstall ---
if ($Uninstall) {
    Write-Host "`nUninstalling PromptPad..." -ForegroundColor Yellow

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($currentPath -and $currentPath.Split(';') -contains $InstallDir) {
        $newPath = ($currentPath.Split(';') | Where-Object { $_ -ne $InstallDir }) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Done "Removed $InstallDir from PATH"
    } else {
        Write-Skip "PATH does not contain $InstallDir"
    }

    $currentEditor = [Environment]::GetEnvironmentVariable('EDITOR', 'User')
    if ($currentEditor -eq 'promptpad.exe' -or $currentEditor -eq "$InstallDir\$ExeName") {
        [Environment]::SetEnvironmentVariable('EDITOR', $null, 'User')
        Write-Done "Cleared EDITOR environment variable"
    } else {
        Write-Skip "EDITOR is not set to PromptPad (current: $currentEditor)"
    }

    Write-Host "`nInstall directory was NOT removed: $InstallDir" -ForegroundColor DarkYellow
    Write-Host "Delete it manually if desired.`n"
    return
}

# --- Install ---
Write-Host "`nInstalling PromptPad...`n" -ForegroundColor White

# 1. Find the exe
if (-not $ExePath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $candidates = @(
        (Join-Path $scriptDir $ExeName),
        (Join-Path $scriptDir "src\PromptPad\bin\publish\self-contained\$ExeName"),
        (Join-Path $scriptDir "src\PromptPad\bin\publish\framework-dependent\$ExeName"),
        (Join-Path $scriptDir "src\PromptPad\bin\Release\net8.0-windows\win-x64\$ExeName")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $ExePath = $candidate
            break
        }
    }
}

if (-not $ExePath -or -not (Test-Path $ExePath)) {
    Write-Error "PromptPad.exe not found. Use -ExePath to specify the location, or run 'dotnet publish' first."
    return
}

Write-Step "Source: $ExePath"

# 2. Copy exe to install directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Done "Created $InstallDir"
} else {
    Write-Skip "Directory exists: $InstallDir"
}

Copy-Item -Path $ExePath -Destination (Join-Path $InstallDir $ExeName) -Force
Write-Done "Copied $ExeName to $InstallDir"

# 3. Add to user PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = if ($currentPath) { $currentPath.Split(';') } else { @() }

if ($pathEntries -contains $InstallDir) {
    Write-Skip "PATH already contains $InstallDir"
} else {
    $newPath = if ($currentPath) { "$currentPath;$InstallDir" } else { $InstallDir }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Done "Added $InstallDir to user PATH"
}

# 4. Set EDITOR environment variable
$currentEditor = [Environment]::GetEnvironmentVariable('EDITOR', 'User')
if ($currentEditor -eq 'promptpad.exe') {
    Write-Skip "EDITOR already set to promptpad.exe"
} else {
    if ($currentEditor) {
        Write-Host "  [!!] EDITOR is currently: $currentEditor" -ForegroundColor Yellow
        Write-Host "       Overwriting with: promptpad.exe" -ForegroundColor Yellow
    }
    [Environment]::SetEnvironmentVariable('EDITOR', 'promptpad.exe', 'User')
    Write-Done "Set EDITOR=promptpad.exe"
}

# 5. Update current session
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
$env:EDITOR = 'promptpad.exe'

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "  Location: $InstallDir\$ExeName"
Write-Host "  EDITOR:   promptpad.exe"
Write-Host "`nOpen a NEW terminal for PATH changes to take effect.`n"
