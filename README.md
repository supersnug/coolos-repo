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
- `coolos-config`: Upgradeable CoolOS system and service policy.
- `coolos-keyring`: Pacman trust material for the repository signing key.
- `coolos-niri-settings`: Generic Niri and Noctalia defaults for CoolOS.
- `opencode-desktop`: OpenCode desktop app built against system Electron.

OpenCode Desktop 2 uses the version-locked `/usr/bin/opencode` package for its
V2 background service. It does not bundle or stage another CLI. User configuration
is owned by OpenCode, not by these packages; see the
[V2 config guide](https://opencode.ai/v2/docs/config) and
[migration guide](https://opencode.ai/v2/docs/migrate-v1).

The installer explicitly selects `coolos-niri-settings` for Niri. This package
does not automatically replace CachyOS settings on a system upgrade. Conflicts
with other desktop settings remain intentional to prevent overlapping files.

## Publishing

Publishing requires the `COOLOS_GPG_SIGNING_KEY` and
`COOLOS_GPG_SIGNING_PASSPHRASE` repository secrets. The key secret must contain
only the dedicated CI signing subkey, not the offline primary key.
