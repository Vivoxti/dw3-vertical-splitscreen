# Dev helper: copies mod\VerticalSplit into the game's ue4ss\Mods (enabled via enabled.txt).
#   .\deploy.ps1           -> install/update
#   .\deploy.ps1 -Remove   -> uninstall
param(
    [switch]$Remove,
    [string]$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\DW3CE_RE"
)
$ErrorActionPreference = "Stop"

$modsDir = Join-Path $GameDir "DW3CE_RE\Binaries\Win64\ue4ss\Mods"
if (-not (Test-Path $modsDir)) { throw "UE4SS not found: $modsDir" }
$dst = Join-Path $modsDir "VerticalSplit"

if ($Remove) {
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Write-Output "Removed $dst"
    return
}

# overwrite mod files but keep user data such as fov.txt
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item (Join-Path $PSScriptRoot "mod\VerticalSplit\*") $dst -Recurse -Force
Write-Output "Deployed to $dst"
