param(
    [Parameter(Mandatory=$true)][string]$RepoUrl,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference = "Stop"

if (Test-Path $Destination) { throw "Destination already exists: $Destination" }
git clone $RepoUrl $Destination
Set-Location $Destination
git fetch --tags --prune

git switch --detach v2.5.3
$versionLine = Select-String -Path "app\pubspec.yaml" -Pattern '^version:\s*2\.5\.3\+'
if (-not $versionLine) { throw "The checked-out tag is not Butterfly 2.5.3" }

$sha = (git rev-parse HEAD).Trim()
git branch "baseline/v2.5.3-pristine" $sha
git switch -c "work/v1-main" $sha
Write-Host "Baseline SHA: $sha"
Write-Host "Created local branches baseline/v2.5.3-pristine and work/v1-main"
