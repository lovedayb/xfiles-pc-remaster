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

    $newDataDir = $dataDir + '\xv'
   
    # Run srt-vtt on ../data/xv
    $srtvtt = Join-Path $scriptDir 'srt-vtt'
    if (Test-Path $srtvtt) {
        & $srtvtt -r (Join-Path $newDataDir 'xv')
    } else {
        # try to run from PATH
        if (Get-Command 'srt-vtt' -ErrorAction SilentlyContinue) { & srt-vtt -r (Join-Path $newDataDir 'xv') }
        else { Write-Verbose 'srt-vtt not found in script dir or PATH; skipping srt-vtt step.' }
    }

    
} finally {
    Pop-Location
}

Write-Host 'convertall.ps1 finished.'
