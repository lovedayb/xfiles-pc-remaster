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

    $newDataDir = $dataDir + '\xs'
   
       # xs audio: .amv -> m4a, .dmv -> multi-language m4a, .mus -> m4a
    Get-ChildItem -Path (Join-Path $scriptDir 'xs') -Filter '*.amv' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
    $out = Join-Path $newDataDir ($f.BaseName + '.ogg')
    $aacout = Join-Path $newDataDir ($f.BaseName + '.m4a')
  
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:a','libvorbis',$out)
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:a','aac',$aacout)
    }
    Get-ChildItem -Path (Join-Path $scriptDir 'xs') -Filter '*.dmv' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
        $base = $f.BaseName
        # English
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:a','libvorbis','-vn', (Join-Path $newDataDir ("$base-en.ogg")))
        # other languages - these are in sibling folders like ../x-files-es/
        $langs = @{ 'es' = '..\x-files-es'; 'fr' = '..\x-files-fr'; 'it' = '..\x-files-it'; 'de' = '..\x-files-de' }
        foreach ($k in $langs.Keys) {
            $src = Join-Path $scriptDir (Join-Path $langs[$k] $f.Name)
            if (Test-Path $src) {
                Invoke-FFmpeg -ArgList @('-i',$src,'-c:v','libtheora','-c:a','libvorbis', '-vn', (Join-Path $newDataDir ("$base-$k.ogg")))
                Invoke-FFmpeg -ArgList @('-i',$src,'-c:v','libtheora','-c:a','aac', '-vn', (Join-Path $newDataDir ("$base-$k.m4a")))
            }
        }
    }
    Get-ChildItem -Path (Join-Path $scriptDir 'xs') -Filter '*.mus' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:a','libvorbis','-vn', (Join-Path $newDataDir ($f.BaseName + '.ogg')))
     Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:a','aac','-vn', (Join-Path $newDataDir ($f.BaseName + '.m4a')))
    }


    
} finally {
    Pop-Location
}

Write-Host 'convertall.ps1 finished.'
