# Runtime State

> Ownership and recovery boundaries for application data that chezmoi must not treat as ordinary source.

## OpenList

chezmoi owns the portable `database.db_file` policy through `modify_config.json` and creates the encrypted SQLite seed only when `~/OpenList/data.db` is absent. A live database is never replaced by normal apply.

Capture is an explicit stopped-service operation:

```powershell
chezmoi re-add --re-encrypt "$HOME\OpenList\data.db"
```

Stop OpenList first. Do not run capture during apply or while SQLite WAL state is active.

## Clash Verge Rev and Mihomo providers

Clash Verge Rev uses one intentional local profile named `Managed Providers`. Its managed Mihomo configuration declares seven HTTP `proxy-providers`; Mihomo downloads and refreshes their payloads every hour.

### Ownership

| Artifact | Owner | Normal behavior |
|---|---|---|
| `managed-providers.yaml` local profile content | chezmoi | Replaced from the declarative provider configuration |
| `profiles.yaml` entry for `managed-providers` | chezmoi, narrowly | Added or repaired with `modify_profiles.yaml` |
| Current profile selection and all other profile entries | Clash Verge Rev | Preserved by the modify template |
| `proxy_provider/` downloads and provider refresh state | Mihomo | Downloaded and refreshed at runtime |
| Generated app-root `config.yaml` | Clash Verge Rev | Never managed as a chezmoi target |

### Activation and migration

1. Exit Clash Verge Rev so it cannot concurrently write `profiles.yaml`.
2. Review and apply the dotfiles source.
3. Start Clash Verge Rev and select **Managed Providers** once from Profiles.
4. Choose a node in the `PROXY` group, or select `DIRECT`.
5. Remove older remote profiles in the UI only after the local provider profile is working.

The migration is additive: it does not delete remote profiles or force the current profile selection.

### Provider policy

The managed configuration intentionally has a small policy surface:

```text
seven proxy-providers
→ one manual PROXY select group (plus DIRECT)
→ MATCH,PROXY
```

All unmatched traffic therefore uses the selected `PROXY` member. DNS, TUN, rule providers, regional routing, health tests, and GUI remote-profile automation are outside this profile and must be added deliberately.

### Platform boundaries

- **Windows:** targets the Scoop persistent Clash Verge Rev home.
- **Linux:** targets the XDG data home for `io.github.clash-verge-rev.clash-verge-rev`.
- **macOS:** no Clash Verge Rev target is deployed by this repository.

No URL-scheme importer, `Script.js`, `Merge.yaml`, or subscription payload backup is used. The provider URLs are public declarations; Mihomo owns their downloaded results.
