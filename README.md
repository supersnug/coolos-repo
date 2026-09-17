# CoolOS Package Repository

This repository contains the package recipes and publication workflow for the
signed CoolOS Pacman repository.

Repository URL:

```ini
[coolos]
SigLevel = Required DatabaseRequired
Server = https://coolos-repo.sarulean.com/$repo/$arch
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

## CPU-optimized repositories

The baseline endpoint above remains supported. Compiled packages
(`opencode-desktop` native modules and `cachyos-calamares-next`) also have
`x86-64-v3`, `x86-64-v4`, and `znver4` builds. Architecture-independent settings
and keyring packages remain in `[coolos]`. Electron and the exact-version
OpenCode CLI still come from your existing Arch/CachyOS repositories.

Fresh online CoolOS installations select the compatible repositories before
installing target packages. Priority is **znver4 → v4 → v3 → baseline**, including
only compatible tiers. Existing installations are not automatically changed.

For an existing system, check usable ISA levels:

```bash
/lib/ld-linux-x86-64.so.2 --help | grep 'supported, searched'
```

A v3 system should place these sections above the CachyOS/Arch repositories:

```ini
[coolos-v3]
Server = https://coolos-repo.sarulean.com/$repo/$arch

[coolos]
Server = https://coolos-repo.sarulean.com/$repo/$arch
```

If v4 is supported, prepend:

```ini
[coolos-v4]
Server = https://coolos-repo.sarulean.com/$repo/$arch
```

For compatible AMD Zen 4/5 CPUs, prepend this above v4:

```ini
[coolos-znver4]
Server = https://coolos-repo.sarulean.com/$repo/$arch
```

Following [CachyOS's approach](https://wiki.cachyos.org/features/optimized_repos/),
Zen 4 is a separate `-march=znver4` build, not an alias for v4. It enables
additional AMD instruction sets. The installer checks usable v4 support,
AMD family/model, and additional CPU flags on every reported processor.
Missing Zen-specific capabilities fall back to the standard compatible tier.
With GCC installed, CachyOS also recommends checking
`gcc -march=native -Q --help=target` for `znver4` or `znver5`.

After adding compatible tiers, run `sudo pacman -Syu`. Package releases use
suffixes `.1` (v3), `.2` (v4), and `.3` (znver4), preventing Pacman's package
cache from confusing same-version builds. To move back to a lower tier, remove
incompatible repository sections and explicitly reinstall the affected packages
from the desired repository, for example:
`sudo pacman -Syu coolos/opencode-desktop`. Do this before moving an installation
to a CPU that cannot run its installed optimized packages.

Build recipes default to portable x86-64. CI selects other tiers through
`COOLOS_CPU_TARGET`; every tier builds in a separate job and all four must pass
before a single signed repository deployment. ISA checks run for every tier;
native-module execution checks run only when the build CPU supports that tier.

## Publishing

All tiers use the same server template: `https://coolos-repo.sarulean.com/$repo/$arch`.
Pacman expands `$repo` from the section name. This replaces the pre-release
`/x86_64/` and `/x86_64/coolos-{v3,v4,znver4}/` URLs. Existing development
installations must update their CoolOS `Server` lines to the new template;
repository names and signing trust stay the same.

Publishing requires the `COOLOS_GPG_SIGNING_KEY` and
`COOLOS_GPG_SIGNING_PASSPHRASE` repository secrets. The key secret must contain
only the dedicated CI signing subkey, not the offline primary key.
