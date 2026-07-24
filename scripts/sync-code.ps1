param(
    [ValidateSet("pull", "push", "sync")]
    [string]$Mode = "sync",
    [string]$Branch,
    [string]$Remote = "mirror"
)

$ErrorActionPreference = "Stop"
$ExpectedBaseline = "a10a9787fd4fdc51c9426ead83ff063136015fb2"

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Run this script from inside a Git working tree."
}
Set-Location $repoRoot

if (-not $Branch) {
    $Branch = (& git branch --show-current).Trim()
}
if (-not $Branch) {
    throw "Refusing to sync a detached HEAD."
}

& git remote get-url $Remote *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Git remote '$Remote' is not configured."
}

$baseline = (& git rev-parse refs/heads/baseline/v2.5.3-pristine 2>$null).Trim()
if ($baseline -ne $ExpectedBaseline) {
    throw "Baseline ref mismatch: expected $ExpectedBaseline, got '$baseline'."
}

$dirty = @(& git status --porcelain --untracked-files=normal)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the working tree."
}
if ($dirty.Count -gt 0) {
    $dirty | Write-Error
    throw "Working tree is not clean. Commit or intentionally discard changes before syncing."
}

Invoke-Git fetch $Remote --prune

$remoteRef = "refs/remotes/$Remote/$Branch"
& git show-ref --verify --quiet $remoteRef
$remoteBranchExists = $LASTEXITCODE -eq 0

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

$head = (& git rev-parse --short=12 HEAD).Trim()
Write-Host "Synced $Branch at $head via $Remote ($Mode)."

