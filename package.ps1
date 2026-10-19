# Builds dist\VerticalSplit-<version>.zip, laid out to be extracted into DW3CE_RE\Binaries\Win64.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$root = $PSScriptRoot
$main = Join-Path $root "mod\VerticalSplit\Scripts\main.lua"
$version = (Select-String -Path $main -Pattern 'local VERSION = "([^"]+)"').Matches[0].Groups[1].Value

# zip entry (forward slashes, as mod managers expect) -> source file
$files = [ordered]@{
    "ue4ss/Mods/VerticalSplit/Scripts/main.lua" = $main
    "ue4ss/Mods/VerticalSplit/enabled.txt"      = Join-Path $root "mod\VerticalSplit\enabled.txt"
    "README-VerticalSplit.txt"                  = Join-Path $root "README.txt"
}

$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist "VerticalSplit-$version.zip"
if (Test-Path $zip) { Remove-Item $zip }

$archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $files.Keys) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $files[$entry], $entry) | Out-Null
    }
} finally {
    $archive.Dispose()
}
Write-Output $zip
