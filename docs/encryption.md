# Encryption Guide

> Setting up age/rage encryption for home key and secrets.

## Home Encryption

Use `rage` to configure per [chezmoi tutorial](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/):

```bash
# cd to source home
chezmoi cd ~
rage-keygen -o "key.txt"
# -a: --armor, -p: --passphrase
rage -a -p "key.txt" > "key.txt.rage"
```

Add `key.txt.rage` to `.chezmoiignore`.

### chezmoi.toml config

Add your public key to recipient.

```toml
encryption = "age"
[age]
    command = "rage"
    identity = # Your identity "key.txt" path
    recipient = # Your public key from rage-keygen
```

### Decrypt during apply

- [Windows](/home/.chezmoiscripts/windows/run_onchange_before_00-decrypt-home.ps1.tmpl)
- [Linux](/home/.chezmoiscripts/linux/run_onchange_before_00-decrypt-home.sh.tmpl)

These scripts decrypt `key.txt.rage` to the configured `identity` path when they
change. Before chezmoi reads encrypted source state, `read-source-state.pre`
ensures `rage`: Windows bootstraps Scoop plus `rage`; Linux bootstraps Nix plus
`rage`; macOS remains an operator-provided prerequisite. The hook exits
immediately when `rage` is already available and does not reconcile applications.

### Re-encrypt

If you want to change your passphrase, re-apply above workflow again.

Due to recipient changed, you should change all encrypted file again.

```powershell
& chezmoi managed --include encrypted --path-style absolute |
Where-Object { Test-Path $_ } |
ForEach-Object {
    $encrypted_file = $_

    chezmoi forget "$encrypted_file"

    # remove .asc suffix
    if ($encrypted_file -match '\.asc$') {
        $decrypted_file = $encrypted_file -replace '\.asc$', ''
    } else {
        Write-Warning "Skipping (not .asc): $encrypted_file"
        return
    }

    chezmoi add --encrypt "$decrypted_file"
}
```

```bash
for encrypted_file in $(chezmoi managed --include encrypted --path-style absolute)
do
  # optionally, add --force to avoid prompts
  chezmoi forget "$encrypted_file"

  # strip the .asc extension
  decrypted_file="${encrypted_file%.asc}"

  chezmoi add --encrypt "$decrypted_file"
done
```

Above script

## Data Encryption

> Requires Home Encryption first.

The repository keeps its encrypted TOML input at
`home/dot_config/encrypted_data.toml.age`. The `home/.chezmoitemplates/data`
template decrypts and exposes it to leaf templates.

Use it in a template:

```text
{{- $secret := includeTemplate "path-to-your-data" . | fromToml -}}
{{- $something := $secret.some-field -}}
```

Do not render encrypted binary/state files through an ordinary template.
OpenList stores its encrypted SQLite seed as
`home/OpenList/create_encrypted_data.db`; chezmoi decrypts it only when creating
a missing `~/OpenList/data.db` target.

Capture current OpenList state only after stopping OpenList, using:

```powershell
chezmoi re-add --re-encrypt "$HOME\OpenList\data.db"
```

`re-add --re-encrypt` preserves the `create_encrypted_` source attribute. Do
not invoke it in an apply hook or while SQLite WAL state is active. See
[Runtime State](./runtime-state.md) for the complete capture and restore flow.

macOS remains configuration-only: install `rage` before running chezmoi so encrypted source state can be read.

## Re-modify Encryption

1. Remove decrypted key identity from path
2. Remove original key from source and chezmoi config
3. Follow Home Encryption steps to add new key
4. Run `chezmoi init` to reload identity
