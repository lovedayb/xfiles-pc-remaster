# Ensure PowerShell 7
#requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $PSCommandPath
if (-not $scriptDir) { $scriptDir = Get-Location }

function New-DirectoryIfMissing {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Invoke-FFmpeg {
    param([string[]]$ArgList)
    $exe = 'ffmpeg'
    & $exe @ArgList
}

function Invoke-FFprobe {
    param([string[]]$ArgList)
    $exe = 'ffprobe'
    & $exe @ArgList
}

Push-Location $scriptDir
try {
  
       $dataDir = Join-Path $scriptDir '..\data' | Resolve-Path -ErrorAction SilentlyContinue
    if ($dataDir) { $dataDir = $dataDir.Path } else { $dataDir = Join-Path $scriptDir '..\data' }

    # Helper to run the python extractor script located next to this script
    $extractor = 'extractdir.py' #Join-Path $scriptDir 'extractdir.py'

    $newDataDir = $dataDir + '\xt'
   
    # xt text files -> copy with language suffixes
    Get-ChildItem -Path (Join-Path $scriptDir 'xt') -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
        Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $newDataDir ("$($f.BaseName)-en.txt")) -Force
        $langs = @{ 'es' = '..\x-files-es'; 'fr' = '..\x-files-fr'; 'it' = '..\x-files-it'; 'de' = '..\x-files-de' }
        foreach ($k in $langs.Keys) {
            $src = Join-Path $scriptDir (Join-Path $langs[$k] $f.Name)
            if (Test-Path $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $newDataDir ("$($f.BaseName)-$k.txt")) -Force }
        }
    }


    
} finally {
    Pop-Location
}

Write-Host 'convertall.ps1 finished.'
