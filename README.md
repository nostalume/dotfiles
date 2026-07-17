# Dotfiles

Dotfiles managed with [chezmoi](https://www.chezmoi.io).

## Ownership

- **Windows:** Scoop and [WinSpec](https://github.com/nostalume/winspec) own Windows packages and declarative system state.
- **Linux:** Nix owns applications, including `rage`, `shed`, and `rustic`.
- **chezmoi:** owns runtime configuration and encrypted source rendering.
- **Outside normal chezmoi convergence:** OpenList stopped-service `re-add` captures plus Clash Verge's provider downloads, current selection, and other GUI runtime state.
- **macOS:** configuration-only after the operator has installed Nix and `rage`; it is not a fully validated package-management target.

## First install

`read-source-state.pre` is the minimal encryption prerequisite: it establishes Scoop/Nix only when `rage` is absent, then installs `rage` and exits. It does not reconcile applications. Once `rage` exists, `init`, `diff`, and `apply` have no bootstrap work.

### Windows

```powershell
winget install twpayne.chezmoi
chezmoi init --apply nostalume
```

Install WinSpec explicitly after configuration is applied, then preview and apply declarative system state:

```powershell
scoop install winspec
winspec validate -Spec "$HOME/.config/winspec/.winspec.ps1"
winspec push -Spec "$HOME/.config/winspec/.winspec.ps1" -DryRun
winspec push -Spec "$HOME/.config/winspec/.winspec.ps1"
```

Package installation is an explicit non-idempotent WinSpec trigger:

```powershell
winspec trigger -Spec "$HOME/.config/winspec/.winspec.ps1"
```

Interactive Winget packages remain skipped by the spec's default `IncludeInteractive = $false`; change that trigger configuration deliberately before including them.

### Linux

The minimum bootstrap environment is `chezmoi`, Bash/sh, `curl`, and network access.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init nostalume
```

The pre-read hook installs Nix and `rage` only when `rage` is absent. After apply, reconcile the application profile explicitly:

```bash
nix profile install ~/.config/nix#default
```

### macOS

Install Nix and `rage` yourself before `chezmoi apply`. This repository does not run a Linux bootstrap artifact or automatic package reconciliation on macOS.

## Routine maintenance

```text
chezmoi update
chezmoi diff
chezmoi apply
```

After apply, run the platform's explicit reconciliation command when desired:

- Windows: `winspec push` for declarative state, then `winspec trigger` for selected package actions.
- Linux: update/install the managed Nix profile from `~/.config/nix#default`.

Do not use a chezmoiscript to write mutable state back to source while applying. OpenList uses `modify_config.json` to own its SQLite `database.db_file` field and point it at `~/OpenList/data.db`; `create_encrypted_data.db` creates that DB only when missing. Capture is explicit `chezmoi re-add --re-encrypt` after OpenList stops, and restore is manual. Clash Verge's profile manifest remains app-owned except for the narrow additive local-profile entry managed by `modify_profiles.yaml`.

Clash Verge uses one chezmoi-managed local Mihomo profile. Its `proxy-providers` fetch the seven public subscriptions at runtime; Mihomo owns downloaded provider files and refreshes, while chezmoi only manages the provider declarations. Applying source adds the `Managed Providers` local profile entry without changing the current profile or deleting existing remote profiles. Select `Managed Providers` once in Clash Verge Rev to activate it.

## Documentation

- [Architecture](./docs/overview.md) — ownership, state flow, and template boundaries
- [Encryption](./docs/encryption.md) — home key and encrypted source requirements
- [Runtime state](./docs/runtime-state.md) — OpenList and Clash Verge backup, recovery, and migration boundaries
- [FAQ](./docs/faq.md) — Go template quirks and interpreter configuration
