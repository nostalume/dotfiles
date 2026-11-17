@{
    SchemaVersion = 2
    Registry = @{
        Clipboard = @{ EnableHistory = $true }
        Desktop = @{ ForegroundLockTimeout = 0; MenuShowDelay = '400' }
        Explorer = @{ ShowFileExt = $true; ShowHidden = $true }
        Start = @{ ShowRecentlyAddedApps = $false; ShowRecommendations = $false }
        Taskbar = @{ ShowTaskViewButton = $true; ShowWidgets = $false }
        Theme = @{ AppTheme = 'dark'; SystemTheme = 'dark' }
    }
    Actions = @{
        installPackages = @{
            Use = 'Script'
            With = @{
                File = './scripts/install.ps1'
                Args = @('-Roles', 'base,dev,backup')
            }
        }
        installDailyPackages = @{
            Use = 'Script'
            With = @{
                File = './scripts/install.ps1'
                Args = @('-Roles', 'daily', '-IncludeInteractive')
                Interactive = $true
            }
        }
    }
}
