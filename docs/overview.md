# Architecture Overview

> High-level structure and lifecycle boundaries for this dotfiles repository.

## Directory layout

```text
chezmoi/
├── .chezmoiroot              → redirects to home/
├── README.md                 → operator workflow
└── home/
    ├── .chezmoi.toml.tmpl    → age, shell/editor, and interpreter config
    ├── .chezmoiignore.tmpl   → source-state platform filtering
    ├── .chezmoiexternals/    → nvim external destination split
    ├── .chezmoiscripts/      → apply-time decryption only
    ├── .chezmoitemplates/    → shared semantic templates and encrypted-data loader
    ├── dot_config/           → Linux/Windows application config and Nix flake
    ├── AppData/              → Windows application target wrappers
    ├── scoop/                → Windows/Scoop target wrappers and recovery seeds
    └── prepare/              → source-read encryption bootstrap scripts
```

## Lifecycle

### First install

```text
install chezmoi
→ chezmoi init --apply
→ read-source-state.pre ensures package manager + rage only
→ rage available
→ explicit package reconciliation
```

`read-source-state.pre` is intentionally the encryption prerequisite boundary. It exits immediately when `rage` exists; it never installs the normal application profile or package roles.

- Windows bootstrap establishes Scoop and `rage`. `scoop install winspec`, WinSpec `push`, and its `PackageInstall` trigger remain explicit post-apply operations.
- Linux bootstrap is Nix-first but installs `rage` only. The source flake's default application profile is an explicit post-apply reconciliation action.
- macOS is configuration-only after operator-provided Nix and `rage`; no Linux bootstrap or automatic package reconciliation runs there.

### Maintenance

```text
chezmoi update
→ chezmoi diff
→ chezmoi apply
→ explicit WinSpec or Linux Nix reconciliation
```

OpenList uses `modify_config.json` for field-owned configuration policy, including the portable `database.db_file` at `~/OpenList/data.db`, and `create_encrypted_data.db` for a missing encrypted SQLite seed. Normal apply never replaces a live DB; an explicit stopped-service `re-add --re-encrypt` captures state and restore remains manual. Clash Verge's runtime manifest remains app-owned except for the intentionally narrow local-profile entry that `modify_profiles.yaml` adds or repairs.

Clash Verge keeps its runtime manifest and provider downloads app-owned. chezmoi manages one intentional local profile, `Managed Providers`, whose Mihomo configuration declares seven `proxy-providers`. The `modify_profiles.yaml` targets add or repair only that local-profile entry and preserve the current selection plus existing remote profiles. After apply, the operator selects `Managed Providers` in Clash Verge Rev; Mihomo then refreshes provider downloads hourly. The local profile's minimal policy exposes all providers through `PROXY` (with `DIRECT` available) and routes `MATCH` traffic to that group.

Detailed OpenList and Clash Verge backup, restore, and migration procedures are in [Runtime State](./runtime-state.md).

## Platform ownership

| Boundary | Windows | Linux | macOS |
|---|---|---|---|
| Applications | Scoop / WinSpec | Nix profile | operator-managed only |
| Runtime config | chezmoi | chezmoi | chezmoi after prerequisites |
| Encryption tool | pre-read Scoop + rage bootstrap | pre-read Nix + rage bootstrap | operator-provided |
| OpenList state | encrypted create-only SQLite seed | manual restore / stopped-service re-add | not managed |
| Clash Verge provider payloads and selection | app/Mihomo-owned | app/Mihomo-owned | not deployed |

## Template boundaries

- `.chezmoitemplates/data` is the only encrypted-data parse/decrypt boundary.
- `.chezmoitemplates/shell/profile.ps1` is shared by the PowerShell profile targets.
- VS Code settings/keybindings and Zed keymap are shared semantic templates with thin Windows/Linux target wrappers.
- Zed settings remain a `modify_` merge: shared base/AI settings are merged while machine-local fields take precedence.
- `.chezmoiexternals/universal.toml.tmpl` owns the small OS destination branch for nvim; it needs no additional abstraction.
- `clash-verge/managed-providers.yaml` is shared Mihomo configuration; thin Windows and Linux wrappers place it in their distinct app homes, while `modify_profiles.yaml` owns only the matching local-profile entry.
