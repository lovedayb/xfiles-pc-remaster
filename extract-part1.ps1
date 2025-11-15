
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

    # Remove existing data dir and recreate structure
    if (Test-Path -LiteralPath $dataDir) { Remove-Item -LiteralPath $dataDir -Recurse -Force }
    New-DirectoryIfMissing $dataDir
    New-DirectoryIfMissing (Join-Path $dataDir 'xg')
    New-DirectoryIfMissing (Join-Path $dataDir 'xn')
    New-DirectoryIfMissing (Join-Path $dataDir 'xv')
    New-DirectoryIfMissing (Join-Path $dataDir 'xt')
    New-DirectoryIfMissing (Join-Path $dataDir 'xs')

    # Helper to run the python extractor script located next to this script
    $extractor = 'extractdir.py' #Join-Path $scriptDir 'extractdir.py'

    # *.nmv -> extract frames, then make mp4 from frames
    Get-ChildItem -Path $scriptDir -Filter '*.nmv' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
        $base = $f.BaseName
    $outDir = Join-Path $dataDir $base
    New-DirectoryIfMissing $outDir
        if (Test-Path $extractor) {
            & python $extractor $f.FullName $outDir
        }
        # ffmpeg expects an input like ../data/<base>/%1d.jpeg
        #$inputPattern = Join-Path $outDir '%1d.jpeg'
    #Invoke-FFmpeg -ArgList @('-framerate','1','-i',$inputPattern,'-r','25','-y','-c:v','libx264','-crf','1','-pix_fmt','yuv420p', (Join-Path $dataDir "$base.mp4"))
    }

   

} finally {
    Pop-Location
}

Write-Host 'Part 1 finished.'
