# sync-mission.ps1
# Copies the LIVE Zargabad mission from the Arma 3 profile into this repo's mission\ folder,
# so the committed snapshot stays current. Run it before committing:
#     powershell -ExecutionPolicy Bypass -File sync-mission.ps1
# (or right-click -> Run with PowerShell)

$ErrorActionPreference = "Stop"

$missionName = "The%20Outpost%20(Defense).cup_Zargabad_a3"
$src = Join-Path $env:USERPROFILE "Documents\Arma 3 - Other Profiles\Ragequit\mpmissions\$missionName"
$dst = Join-Path $PSScriptRoot "mission\$missionName"

if (-not (Test-Path $src)) {
    Write-Error "Live mission not found:`n  $src"
    exit 1
}

New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot "mission") | Out-Null
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
Copy-Item -Recurse $src $dst

Write-Host "Mission synced:"
Write-Host "  from  $src"
Write-Host "  to    $dst"
Write-Host ""
Write-Host "Now:  git add -A ; git commit -m ""update mission"" ; git push"
