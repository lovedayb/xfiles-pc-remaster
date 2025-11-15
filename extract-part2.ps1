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

    # xg/*.xmv -> transcode
    Get-ChildItem -Path (Join-Path $scriptDir 'xg') -Filter '*.xmv' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
    $newDataDir = $dataDir + '\xg'
    $out = Join-Path $dataDir ($f.BaseName + '.ogv')
    $newout = Join-Path $newDataDir ($f.BaseName + '.ogv')
    $mp4out = Join-Path $newDataDir ($f.BaseName + '.mp4')
    #write-host $out
    #write-host $newout
    Invoke-FFmpeg -ArgList @('-i', $f.FullName, '-c:v','libtheora', '-c:a', 'libvorbis','-crf','1','-pix_fmt','yuv420p', $newout)
    Invoke-FFmpeg -ArgList @('-i', $f.FullName, '-c:v','libx264', '-c:a', 'aac','-pix_fmt','yuv420p', $mp4out)

    }

    # *.pff and xg/*.pff -> extract dirs
    Get-ChildItem -Path $scriptDir -Filter '*.pff' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
    $outDir = Join-Path $dataDir $f.BaseName
    write-host $outDir
    New-DirectoryIfMissing $outDir
        if (Test-Path $extractor) { & python $extractor $f.FullName $outDir }
    }
    Get-ChildItem -Path (Join-Path $scriptDir 'xg') -Filter '*.pff' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
    $outDir = Join-Path $dataDir $f.BaseName
    write-host $outDir
    New-DirectoryIfMissing $outDir
        if (Test-Path $extractor) { & python $extractor $f.FullName $outDir }
    }

} finally {
    Pop-Location
}

Write-Host 'Part 2 finished.'
