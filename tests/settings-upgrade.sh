#!/usr/bin/env bash
# Exercise Pacman's replacement/upgrade selection using an isolated database.
# Dependency installation is covered by the package builds, not these fixtures.
set -euo pipefail

config=$(realpath "${1:?Pass the coolos-config archive}")
settings=$(realpath "${2:?Pass the coolos-niri-settings archive}")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/root" "$tmp/db/local" "$tmp/db/sync"
printf '9\n' > "$tmp/db/local/ALPM_DB_VERSION"
repo-add "$tmp/db/sync/coolos.db.tar.gz" "$config" "$settings" >/dev/null
cat > "$tmp/pacman.conf" <<EOF
[options]
Architecture = auto
# Only locally supplied test archives; this does not change host trust policy.
SigLevel = Never
[coolos]
Server = file://$tmp
EOF

installed() {
  mkdir -p "$tmp/db/local/$1-$2"
  printf '%%FILES%%\n\n' > "$tmp/db/local/$1-$2/files"
  printf '%%NAME%%\n%s\n\n%%VERSION%%\n%s\n\n%%ARCH%%\nany\n' "$1" "$2" \
    > "$tmp/db/local/$1-$2/desc"
}

pacman_test() {
  pacman --root "$tmp/root" --dbpath "$tmp/db" \
    --config "$tmp/pacman.conf" --logfile "$tmp/pacman.log" \
    --noconfirm --nodeps --nodeps --print-format '%n' "$@"
}

installed cachyos-niri-noctalia 1.4.0-1
selected=$(pacman_test -Sup)
if grep -qx coolos-niri-settings <<< "$selected"; then
  echo 'FAIL: ordinary upgrade replaces CachyOS Niri settings' >&2
  exit 1
fi

# Fresh installs explicitly request CoolOS settings rather than migrating on -Su.
rm -rf "$tmp/db/local/cachyos-niri-noctalia-1.4.0-1"
pacman_test -Sp coolos-niri-settings | grep -qx coolos-niri-settings

installed coolos-config 1.0.0-1
installed coolos-niri-settings 1.0.0-1
selected=$(pacman_test -Sup)
grep -qx coolos-config <<< "$selected"
grep -qx coolos-niri-settings <<< "$selected"
echo 'PASS: no unsolicited replacement; explicit install and CoolOS upgrades work'
