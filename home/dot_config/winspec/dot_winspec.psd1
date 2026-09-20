@{
    SchemaVersion = 1
    Name = 'WinSpec Configuration'
    Description = 'Declarative workstation state and explicit setup actions'

    Registry = @{
        Clipboard = @{ EnableHistory = $true }
        Desktop = @{
            ForegroundLockTimeout = 0
            MenuShowDelay = '400'
        }
        Explorer = @{
            ShowFileExt = $true
            ShowHidden = $true
        }
        Start = @{
            ShowRecentlyAddedApps = $false
            ShowRecommendations = $false
        }
        Taskbar = @{
            ShowTaskViewButton = $true
            ShowWidgets = $false
        }
        Theme = @{
            AppTheme = 'dark'
            SystemTheme = 'dark'
        }
    }

    Actions = @{
        activateWindows = @{
            Use = 'MicrosoftActivation'
            With = @{
                Interactive = $true
            }
        }
        debloat = @{
            Use = 'WindowsDebloat'
            With = @{
              Interactive = $true
            }
        }
        cacheOffice = @{
            Use = 'OfficeDeployment'
            With = @{
                Cache = $true
            }
        }
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

    Workflows = @{
        setup = @{
            Steps = @(
                @{ Apply = @{ Providers = @('Registry') } }
                @{ Run = 'installPackages' }
            )
        }
    }
}
