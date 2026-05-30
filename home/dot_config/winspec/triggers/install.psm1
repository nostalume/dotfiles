$script:Config = @{
    EnabledRoles = @("base", "dev", "backup", "utils")
    Roles        = @{
        base   = @{
            Scoop  = @(
                "7zip", "git", "starship", "rage", "neovim", "shed", "aria2", "bat", "fd", "fzf",
                "ripgrep", "tree-sitter", "scoop-search", "eget", "just", "zed",
                "Maple-Mono", "Maple-Mono-NF", "Maple-Mono-NF-CN", "clash-verge-rev"
            )
            Winget = @("Microsoft.PowerToys", "Microsoft.PowerShell", "MartiCliment.UniGetUI", "GitHub.cli")
        }
        daily  = @{
            Winget = @(
                @{ Name = "Vivaldi.Vivaldi"; Interactive = $true }
                @{ Name = "Valve.Steam"; Interactive = $true }
                @{ Name = "EpicGames.EpicGamesLauncher"; Interactive = $true }
                @{ Name = "Tencent.QQ"; Interactive = $true }
            )
        }
        utils  = @{
            Winget = @(
                @{ Name = "Anki.Anki"; Interactive = $true }
                @{ Name = "DigitalScholar.Zotero"; Interactive = $true }
            )
        }
        dev    = @{ Scoop = @("aqua", "pixi", "hugo-extended"); Winget = @("Rustlang.Rustup") }
        backup = @{ Scoop = @("restic", "resticprofile", "openlist") }
    }
}

function Get-ProviderInfo {
    return @{ Name = "PackageInstall"; Type = "Trigger" }
}

function Resolve-Package {
    param([Parameter(Mandatory)] [object]$Package)

    if ($Package -is [string]) {
        return @{ Name = $Package; Flags = @(); Interactive = $false }
    }

    $flags = if ($null -ne $Package.Flags) { @($Package.Flags) } else { @() }
    return @{
        Name        = $Package.Name
        Flags       = $flags
        Interactive = [bool]$Package.Interactive -or ($flags -contains "-i")
    }
}

function Invoke-Trigger {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string[]]$Roles = $script:Config.EnabledRoles,
        [switch]$Force,
        [switch]$IncludeInteractive
    )

    $results = @()
    $errors = @()

    foreach ($role in $Roles) {
        if (-not $script:Config.Roles.ContainsKey($role)) {
            $errors += [pscustomobject]@{ Role = $role; Status = "Error"; Reason = "UnknownRole" }
            continue
        }

        $roleDef = $script:Config.Roles[$role]
        foreach ($providerName in @("Scoop", "Winget")) {
            foreach ($raw in @($roleDef[$providerName])) {
                if ($null -eq $raw) { continue }

                $provider = $providerName.ToLowerInvariant()
                $pkg = Resolve-Package $raw

                $args = if ($provider -eq "scoop") { @("install") } else { @("install", "--accept-source-agreements", "--accept-package-agreements") }
                if ($Force) { $args += "--force" }
                if ($provider -eq "winget" -and -not $pkg.Interactive) { $args += "--silent" }
                $args += @($pkg.Flags) + $pkg.Name

                if ($pkg.Interactive -and -not $IncludeInteractive) {
                    $results += [pscustomobject]@{ Provider = $provider; Role = $role; Package = $pkg.Name; Status = "Skipped"; Reason = "InteractivePackage" }
                    continue
                }

                if (-not $PSCmdlet.ShouldProcess("$provider package $($pkg.Name)", "Install")) {
                    $results += [pscustomobject]@{ Provider = $provider; Role = $role; Package = $pkg.Name; Status = "DryRun"; Reason = "WhatIf" }
                    continue
                }

                Write-Host "Install package: $($pkg.Name)"
                try {
                    & $provider @args
                    $exitCode = $LASTEXITCODE
                    $status = if ($exitCode -eq 0) { "Success" } else { "Failed" }
                    $result = [pscustomobject]@{ Provider = $provider; Role = $role; Package = $pkg.Name; Status = $status; ExitCode = $exitCode }
                }
                catch {
                    $result = [pscustomobject]@{ Provider = $provider; Role = $role; Package = $pkg.Name; Status = "Failed"; Reason = $_.Exception.Message; ExitCode = 1 }
                }

                $results += $result
                if ($result.Status -eq "Failed") { $errors += $result }
            }
        }
    }

    $status = if ($errors.Count -gt 0 -and $results.Count -eq 0) { "Error" }
        elseif ($errors.Count -gt 0) { "PartialFailure" }
        elseif ($results.Count -gt 0 -and @($results | Where-Object Status -eq "DryRun").Count -eq $results.Count) { "DryRun" }
        elseif ($results.Count -gt 0 -and @($results | Where-Object Status -eq "Skipped").Count -eq $results.Count) { "Skipped" }
        else { "Success" }

    return @{
        Status  = $status
        Message = "Processed $($results.Count) package(s). Failed: $($errors.Count)"
        Results = $results
        Errors  = $errors
    }
}

Export-ModuleMember -Function "Get-ProviderInfo", "Invoke-Trigger"
