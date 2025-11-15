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
   
    # xv: copy .hot files
    Get-ChildItem -Path (Join-Path $scriptDir 'xv') -Filter '*.hot' -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $newDataDir $_.Name) -Force
    }

    # xv: videos -> video mp4 (no audio) and extract audio tracks (various languages)
    Get-ChildItem -Path (Join-Path $scriptDir 'xv') -Filter '*.xmv' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_
        $base = $f.BaseName
        # video only
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:v','libtheora','-pix_fmt','yuv420p','-an', (Join-Path $newdataDir ("$base-noaudio.ogv")))
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:v','libx264','-pix_fmt','yuv420p','-an', (Join-Path $newdataDir ("$base-noaudio.mp4")))
    

    # audio (english) from the main file
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:v','libtheora','-c:a','libvorbis','-pix_fmt','yuv420p', (Join-Path $newDataDir ("$base-en.ogv")))
    Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-c:v','libx264','-pix_fmt','yuv420p','-c:a', 'aac', (Join-Path $newdataDir ("$base-en-audio.mp4")))

        # other languages expected in sibling folders
        $langs = @{ 'es' = '..\x-files-es'; 'fr' = '..\x-files-fr'; 'it' = '..\x-files-it'; 'de' = '..\x-files-de' }
        foreach ($k in $langs.Keys) {
            $src = Join-Path $scriptDir (Join-Path $langs[$k] $f.Name)
            if (Test-Path $src) {
                Invoke-FFmpeg -ArgList @('-i',$src,'-c:a','libvorbis','-ac','2','-async','1','-vn', (Join-Path $newDataDir ("$base-$k.ogg")))
            }
        }

        # Extract subtitle streams using ffprobe and map them
        try {
            $subtitleIndexes = Invoke-FFprobe -ArgList @('-v','error','-select_streams','s','-show_entries','stream=index','-of','csv=p=0',$f.FullName) 2>&1
            if ($subtitleIndexes) {
                $subtitleIndexes -split "`n" | ForEach-Object {
                    $idx = $_.Trim()
                    if ($idx -ne '') {
                        # output file name: <base>_<idx>-en.srt (keep naming similar to original)
                        $outSrt = Join-Path $newDataDir ("${base}_$idx-en.srt")
                        Invoke-FFmpeg -ArgList @('-i',$f.FullName,'-map',"0:s:$idx", $outSrt) | Out-Null
                    }
                }
            }
        } catch {
            Write-Verbose "ffprobe/ffmpeg subtitle extraction failed for $($f.Name): $_"
        }
    }

    
} finally {
    Pop-Location
}

Write-Host 'convertall.ps1 finished.'
