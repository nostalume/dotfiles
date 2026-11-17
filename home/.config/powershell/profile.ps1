function Clear-PSReadLineHistory {
    Remove-Item (Get-PSReadLineOption).HistorySavePath
}

function Initialize-Env {
    if ($PSVersionTable.PSVersion -lt [version]'7.5') { return }
    $shedCommand = Get-Command shed -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $shedCommand) { return }
    $shedVersion = & $shedCommand.Source --version
    if ($LASTEXITCODE -ne 0 -or $shedVersion -notmatch '^shed (\d+\.\d+\.\d+)$' -or [version]$Matches[1] -lt [version]'0.2.0') {
        Write-Warning 'The shed profile requires shed 0.2.0 or newer; skipping ~/.shed.'
        return
    }
    $generated = Join-Path ([IO.Path]::GetTempPath()) "shed-$([guid]::NewGuid().ToString('N')).ps1"
    try {
        & $shedCommand.Source powershell "$HOME/.shed" > $generated
        if ($LASTEXITCODE -ne 0) { throw 'shed compilation failed' }
        . $generated
    } finally {
        Remove-Item -LiteralPath $generated -Force -ErrorAction SilentlyContinue
    }
}

function Add-OwnModule {
    param([Parameter(Mandatory=$true)][string]$moduleName, [switch]$Optional)
    try { Import-Module $moduleName -ErrorAction Stop; return $true }
    catch { if (-not $Optional) { Write-Warning "Failed to import ${moduleName}: $_" }; return $false }
}

function Install-ProfileModules {
    [CmdletBinding()]
    param([switch]$Force)
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warning "Profile modules require PowerShell 7 or newer."
        return
    }
    foreach ($moduleName in @("CompletionPredictor", "PSReadLine")) {
        $params = @{ Name = $moduleName; Scope = "CurrentUser"; AllowClobber = $true; SkipPublisherCheck = $true }
        if ($Force) { $params.Force = $true }
        if (-not (Get-Module -ListAvailable -Name $moduleName)) { Install-Module @params }
        Import-Module $moduleName -ErrorAction Stop
    }
}

function Initialize-Modules {
    if ($PSVersionTable.PSVersion.Major -lt 7) { return }

    $completionAvailable = [bool](Get-Module -Name "CompletionPredictor" -ErrorAction SilentlyContinue)
    if (-not $completionAvailable) { $completionAvailable = Add-OwnModule -moduleName "CompletionPredictor" -Optional }

    $psReadLineAvailable = [bool](Get-Module -Name "PSReadLine" -ErrorAction SilentlyContinue)
    if (-not $psReadLineAvailable) { $psReadLineAvailable = Add-OwnModule -moduleName "PSReadLine" -Optional }
    if (-not $psReadLineAvailable) { return }

    $historyFilter = {
        Param([string]$line)
        if ($line -like " *") { return $false }
        $ignores = @("user", "pass", "account", "apikey", "token")
        foreach ($ignore in $ignores) { if ($line -match $ignore) { return $false } }
        return $true
    }

    $PSReadLineOptions = @{
        EditMode                      = "Vi"
        AddToHistoryHandler           = $historyFilter
        ShowToolTips                  = $true
        ExtraPromptLineCount          = $true
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        MaximumHistoryCount           = 5000
        PredictionSource              = if ($completionAvailable) { "HistoryAndPlugin" } else { "History" }
        PredictionViewStyle           = "ListView"
        BellStyle                     = "None"
        Colors                        = @{
            Command   = '#87CEEB'
            Parameter = '#98FB98'
            Operator  = '#FFB6C1'
            Variable  = '#DDA0DD'
            String    = '#FFDAB9'
            Number    = '#B0E0E6'
            Type      = '#F0E68C'
            Comment   = '#D3D3D3'
            Keyword   = '#8367c7'
            Error     = '#FF6347'
        }
    }
    if ([Console]::IsOutputRedirected) {
        [void]$PSReadLineOptions.Remove('PredictionSource')
        [void]$PSReadLineOptions.Remove('PredictionViewStyle')
    }
    Set-PSReadLineOption @PSReadLineOptions

    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key "Alt+j" -Function ViCommandMode
    Set-PSReadLineKeyHandler -Key "Alt+d" -Function ShellKillWord
    Set-PSReadLineKeyHandler -Key "Alt+Backspace" -Function ShellBackwardKillWord
    Set-PSReadLineKeyHandler -Key "Alt+b" -Function ShellBackwardWord
    Set-PSReadLineKeyHandler -Key "Alt+e" -Function ShellForwardWord
    Set-PSReadLineKeyHandler -Key "Alt+B" -Function SelectShellBackwardWord
    Set-PSReadLineKeyHandler -Key "Alt+E" -Function SelectShellForwardWord
}

function setup {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Initialize-Modules
    Initialize-Env
}

setup
