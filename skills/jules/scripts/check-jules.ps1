<#
.SYNOPSIS
Preflight check for Google Jules CLI: verifies installation, authentication, git remote, and active sessions.
#>
param(
    [string]$WorkspacePath = (Get-Location).Path
)

$ErrorActionPreference = "Continue"

Write-Output "=== Google Jules Preflight Check ==="

# 1. Check binary
$julesCmd = Get-Command jules -ErrorAction SilentlyContinue
if (-not $julesCmd) {
    Write-Output "STATUS: MISSING_CLI"
    Write-Output "MESSAGE: 'jules' CLI is not found on PATH. Install Google Jules CLI first."
    exit 2
}

$versionOut = & jules version 2>&1 | Out-String
Write-Output ("CLI_VERSION: " + ($versionOut -replace "\r?\n", " | ").Trim())

# 2. Check current Git repository remote
$gitOrigin = ""
$repoSlug = ""
Push-Location $WorkspacePath
try {
    $gitOrigin = (& git remote get-url origin 2>$null | Out-String).Trim()
    if ($gitOrigin -match "github\.com[:/]([^/]+/[^/\.]+)(\.git)?$") {
        $repoSlug = $Matches[1]
    }
    $gitDirty = (& git status --porcelain 2>$null | Out-String).Trim()
} finally {
    Pop-Location
}

Write-Output "GIT_ORIGIN: $gitOrigin"
Write-Output "DETECTED_REPO: $repoSlug"
Write-Output ("WORKING_TREE_CLEAN: " + ([string]::IsNullOrEmpty($gitDirty)))

# 3. Check Jules Authentication & Connected Repos
$reposOut = & jules remote list --repo 2>&1 | Out-String
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0 -or $reposOut -match "(?im)^(error:|fatal:|.*(unauthenticated|not logged in|please log in|login required|token expired|unauthorized))") {
    Write-Output "STATUS: AUTH_REQUIRED"
    Write-Output "MESSAGE: Google Jules CLI authentication is missing or expired. Please run 'jules login' in your terminal to authenticate."
    Write-Output "RAW_OUTPUT: $($reposOut.Trim())"
    exit 3
}

$repoLines = $reposOut -split "\r?\n" | Where-Object { $_.Trim() -ne "" }
Write-Output "STATUS: AUTHENTICATED"
Write-Output "CONNECTED_REPO_COUNT: $($repoLines.Count)"

if ($repoSlug) {
    $isConnected = $repoLines | Where-Object { $_.Trim().ToLower() -eq $repoSlug.ToLower() }
    if ($isConnected) {
        Write-Output "CURRENT_REPO_CONNECTED: True ($repoSlug)"
    } else {
        Write-Output "CURRENT_REPO_CONNECTED: False ($repoSlug is NOT in 'jules remote list --repo')"
    }
}

# 4. List active/recent sessions
Write-Output "`n=== Remote Sessions ==="
$sessionsOut = & jules remote list --session 2>&1 | Out-String
Write-Output $sessionsOut.Trim()
exit 0
