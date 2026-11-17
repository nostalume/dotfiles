# Dotfiles

Dotfiles managed with [Tuckin](https://github.com/nostalume/tuckin).

## Ownership

- **Windows:** Scoop own Windows packages and [WinSpec](https://github.com/nostalume/winspec) own declarative system state.
- **Linux:** Nix owns Linux pakcages.
- **Tuckin:** owns runtime configuration and encrypted source rendering.

## Before first install

Tuckin will automatically manage your secret by `identity_file` and `recipients` field. If you want to copy my dotfiles, please remove `secrets/**` and my recipients, then use `tuckin init --key` to re-create a new key for your secrets. Anyone should keep their own secret identity!

## First install

### Windows

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/nostalume/tuckin/main/install.ps1' -OutFile "$env:TEMP\install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Install WinSpec explicitly after configuration is applied, then preview and apply declarative system state:

```powershell
scoop install winspec
winspec validate -Spec "$HOME/.config/winspec/.winspec.psd1"
winspec apply -Spec "$HOME/.config/winspec/.winspec.psd1"
```

Package installation is an explicit non-idempotent WinSpec trigger:

```powershell
winspec actions -Spec "$HOME/.config/winspec/.winspec.ps1"
winspec run installPackages -Spec "$HOME/.config/winspec/.winspec.ps1"
```

### Linux

```bash
sh -c "$(curl -fsLS 'https://raw.githubusercontent.com/nostalume/tuckin/main/install.sh')"
```

Package installation is by `nix`:

```bash
nix profile install ~/.config/nix#default
```

## Proxy Providers

Clash Provider [FreeNodes](https://gh-proxy.org/https://raw.githubusercontent.com/nostalume/FreeNodes/HEAD/nodes/merged.yaml) is a free choice.
