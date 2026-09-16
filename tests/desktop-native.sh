#!/usr/bin/env bash
# Load the actual packaged addon and reject CPU-specific compiler output.
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bsdtar -xf "${1:?Pass the Desktop package archive}" -C "$tmp" usr/lib/opencode-desktop/node_modules
addon="$tmp/usr/lib/opencode-desktop/node_modules/msgpackr-extract/build/Release/extract.node"
test -f "$addon"

# CI CPUs may support instructions unavailable on users' machines. GCC's ELF
# ISA notes catch such builds even when the runtime load succeeds on the runner.
readelf -n "$addon" > "$tmp/isa-notes"
cat "$tmp/isa-notes"
grep -q 'x86 ISA used: x86-64-baseline' "$tmp/isa-notes"
if grep -Eq 'x86-64-v[234]' "$tmp/isa-notes"; then
  echo 'FAIL: packaged extractor requires an ISA above baseline x86-64' >&2
  exit 1
fi

ELECTRON_RUN_AS_NODE=1 /usr/lib/electron42/electron -e '
  const addon = require(process.argv[1]);
  if (typeof addon.extractStrings !== "function") throw new Error("Missing native extractor");
  console.log("PASS: packaged native extractor loaded under Electron");
' "$addon"
