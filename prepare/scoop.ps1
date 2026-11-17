$ErrorActionPreference = 'Stop'

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/nostalume/scoop-bridge/main/installer.ps1' -OutFile "$env:TEMP\scoop-bridge.ps1"
    & "$env:TEMP\scoop-bridge.ps1" -UseProxy
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw 'Scoop is unavailable after installation.'
    }
}

Write-Output 'Scoop is ready.'
