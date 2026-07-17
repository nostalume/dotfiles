# Bootstrap only the encryption prerequisite before chezmoi reads source state.
# Package reconciliation remains an explicit WinSpec action after apply.
$ErrorActionPreference = "Stop"

if (Get-Command "rage" -ErrorAction SilentlyContinue) {
    exit 0
}

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest "https://gh-proxy.com/https://raw.githubusercontent.com/nostalume/scoop-cn/master/installer.ps1" | Invoke-Expression
}

if (-not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    throw "Scoop is unavailable after bootstrap"
}

& scoop install spc/rage
if ($LASTEXITCODE -ne 0) {
    throw "Scoop install rage failed with exit code $LASTEXITCODE"
}

if (-not (Get-Command "rage" -ErrorAction SilentlyContinue)) {
    throw "rage is unavailable after Scoop bootstrap"
}
