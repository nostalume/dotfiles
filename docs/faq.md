# FAQ

> Troubleshooting and known issues.

## Go Template

### Indexing .chezmoidata with variable field

**Correct**:

```templ
(index $.roles $role "winget")
```

**Wrong**:

```templ
(index .roles $role "winget")
```

The latter causes `.roles is {}` error when using variable fields like `$role`.
Predefined instances work fine with `(index .roles "something")`.

### Accessing optional fields

Use `with (index $pkg "args")` instead of `$pkg.args`.
The latter causes the same error above.

## Interpreters

Some `.ps1` scripts require `pwsh` (>= 7.0), not `powershell` (5.0).

### Configure interpreter in `chezmoi.toml`

```toml
[interpreters.ps1]
    command = "pwsh"
    args = ["-NoLogo"]
```

See [chezmoi:interpreters](https://www.chezmoi.io/reference/configuration-file/interpreters/) for details.

## Modify templates

`modify_` targets are for a deliberately small field boundary in an existing
runtime file. Their templates receive existing target content through
`.chezmoi.stdin` and must preserve fields they do not own.

For chezmoi v2.71 in this repository, the raw `modify_` source file must carry
the `chezmoi:modify-template` marker itself and must not have a `.tmpl` suffix.
The marker activates the modify-template path that supplies `.chezmoi.stdin`.
Put shared rendering logic in `.chezmoitemplates/` and load it with
`includeTemplate`; a wrapper using `template` does not load that file.

Clash Verge Rev is the example: its `modify_profiles.yaml` template adds or
repairs only the `managed-providers` local profile entry. It does not replace
the manifest, select that profile, remove remote profiles, or manage Mihomo's
downloaded provider files.
