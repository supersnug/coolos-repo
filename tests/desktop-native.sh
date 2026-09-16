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
bash "$(dirname "$0")/cpu-isa.sh" "$addon" "${2:-x86-64}"

# Never execute a higher-tier module on an incompatible build runner.
case ${2:-x86-64} in
  x86-64) ;;
  x86-64-v3|x86-64-v4)
    if ! /lib/ld-linux-x86-64.so.2 --help | grep -q "$2 (supported, searched)"; then
      echo "PASS: ISA checked; $2 runtime check requires compatible hardware"
      exit 0
    fi
    ;;
  znver4)
    if ! gcc -march=native -Q --help=target | grep -Eq 'march=.*znver[45]'; then
      echo 'PASS: ISA checked; Zen 4 runtime check requires compatible hardware'
      exit 0
    fi
    ;;
esac

ELECTRON_RUN_AS_NODE=1 /usr/lib/electron42/electron -e '
  const addon = require(process.argv[1]);
  if (typeof addon.extractStrings !== "function") throw new Error("Missing native extractor");
  console.log("PASS: packaged native extractor loaded under Electron");
' "$addon"
