#!/usr/bin/env bash
# Exercise the packaged PTY addon under the same Electron runtime as Desktop.
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bsdtar -xf "${1:?Pass the Desktop package archive}" -C "$tmp" usr/lib/opencode-desktop/node_modules
modules="$tmp/usr/lib/opencode-desktop/node_modules"
pty="$modules/@lydell/node-pty-linux-x64"
addon="$pty/prebuilds/linux-x64/pty.node"
test -f "$addon"
# 2.0.8 removed MessagePack. Fail if its formerly CPU-specific addon returns,
# or another native dependency appears without a corresponding runtime check.
test ! -d "$modules/msgpackr-extract"
while IFS= read -r -d '' native; do
  if [[ "$native" != "$addon" ]]; then
    echo "FAIL: untested native addon: $native" >&2
    exit 1
  fi
done < <(find "$modules" -name '*.node' -print0)

# Upstream's PTY prebuild is shared across tiers; some prebuilds omit ISA notes.
notes=$(readelf -n "$addon")
if grep -q 'x86 ISA used:' <<< "$notes"; then
  bash "$(dirname "$0")/cpu-isa.sh" "$addon" x86-64
fi

ELECTRON_RUN_AS_NODE=1 /usr/lib/electron42/electron -e '
  const pty = require(process.argv[1]);
  const child = pty.spawn("/bin/sh", ["-c", "printf coolos-pty-ok"], {
    name: "xterm", cols: 80, rows: 24, env: process.env,
  });
  let output = "";
  const timer = setTimeout(() => { child.kill(); process.exit(1); }, 10000);
  child.onData(data => { output += data; });
  child.onExit(({exitCode}) => {
    clearTimeout(timer);
    if (exitCode !== 0 || !output.includes("coolos-pty-ok")) process.exit(1);
    console.log("PASS: packaged PTY spawned a shell and returned output under Electron");
  });
' "$pty/lib/index.js"
