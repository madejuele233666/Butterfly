param(
    [ValidateSet("pull", "push", "sync")]
    [string]$Mode = "sync",
    [string]$Branch,
    [string]$Remote = "mirror"
)

$ErrorActionPreference = "Stop"
$ExpectedBaseline = "a10a9787fd4fdc51c9426ead83ff063136015fb2"

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($gitCommand) {
    $GitExe = $gitCommand.Source
} else {
    $gitCandidates = @(
        "D:\install_software\Git\cmd\git.exe",
        "$env:ProgramFiles\Git\cmd\git.exe"
    )
    $GitExe = $gitCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $GitExe) {
    throw "Git for Windows was not found in PATH or a supported installation path."
}

function Start-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $GitExe
    $startInfo.Arguments = $Arguments -join " "
    $startInfo.WorkingDirectory = (Get-Location).Path
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Unable to start Git for Windows."
    }
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    [PSCustomObject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $result = Start-Git @Arguments
    if ($result.StdOut) { Write-Host $result.StdOut.TrimEnd() }
    if ($result.StdErr) { Write-Host $result.StdErr.TrimEnd() }
    if ($result.ExitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $($result.ExitCode)"
    }
}

function Get-GitOutput {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $result = Start-Git @Arguments
    if ($result.ExitCode -ne 0) {
        if ($result.StdErr) { Write-Host $result.StdErr.TrimEnd() }
        throw "git $($Arguments -join ' ') failed with exit code $($result.ExitCode)"
    }
    $result.StdOut.Trim()
}

$repoRoot = Get-GitOutput rev-parse --show-toplevel
if (-not $repoRoot) {
    throw "Run this script from inside a Git working tree."
}
Set-Location $repoRoot

if (-not $Branch) {
    $Branch = Get-GitOutput branch --show-current
}
if (-not $Branch) {
    throw "Refusing to sync a detached HEAD."
}

$remoteResult = Start-Git remote get-url $Remote
if ($remoteResult.ExitCode -ne 0) {
    throw "Git remote '$Remote' is not configured."
}

$baselineResult = Start-Git rev-parse refs/heads/baseline/v2.5.3-pristine
$baseline = $baselineResult.StdOut.Trim()
if ($baselineResult.ExitCode -ne 0 -or $baseline -ne $ExpectedBaseline) {
    throw "Baseline ref mismatch: expected $ExpectedBaseline, got '$baseline'."
}

$statusResult = Start-Git status --porcelain --untracked-files=normal
if ($statusResult.ExitCode -ne 0) {
    throw "Unable to inspect the working tree."
}
if ($statusResult.StdOut.Trim()) {
    Write-Error $statusResult.StdOut.TrimEnd()
    throw "Working tree is not clean. Commit or intentionally discard changes before syncing."
}

Invoke-Git fetch $Remote --prune

$remoteRef = "refs/remotes/$Remote/$Branch"
$showRefResult = Start-Git show-ref --verify --quiet $remoteRef
$remoteBranchExists = $showRefResult.ExitCode -eq 0

if ($Mode -in @("pull", "sync")) {
    if ($remoteBranchExists) {
        Invoke-Git merge --ff-only $remoteRef
    } elseif ($Mode -eq "pull") {
        throw "Remote branch '$Remote/$Branch' does not exist."
    }
}

if ($Mode -in @("push", "sync")) {
    Invoke-Git push $Remote "HEAD:refs/heads/$Branch"
}

$head = Get-GitOutput rev-parse --short=12 HEAD
Write-Host "Synced $Branch at $head via $Remote ($Mode)."

