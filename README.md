# CoolOS Package Repository

This repository contains the package recipes and publication workflow for the
signed CoolOS Pacman repository.

Repository URL:

```ini
[coolos]
SigLevel = Required DatabaseRequired
Server = https://coolos-repo.sarulean.com/$arch
```

Packages are rebuilt from pinned sources and manually published through the
`Publish repository` GitHub Actions workflow. Generated package archives and
repository databases are deployed to GitHub Pages; they are not committed to
Git.

## Packages

- `cachyos-calamares-next`: CoolOS development build of Calamares.
- `coolos-keyring`: Pacman trust material for the repository signing key.

## Publishing

Publishing requires the `COOLOS_GPG_SIGNING_KEY` and
`COOLOS_GPG_SIGNING_PASSPHRASE` repository secrets. The key secret must contain
only the dedicated CI signing subkey, not the offline primary key.
