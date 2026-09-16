#!/usr/bin/env bash
# Check the compiler-emitted ISA requirements against the repository contract.
set -euo pipefail
notes=$(readelf -n "${1:?Pass an ELF file}")
grep -q 'x86 ISA used: x86-64-baseline' <<< "$notes"
case ${2:-x86-64} in
  x86-64) forbidden='x86-64-v[234]' ;;
  x86-64-v3) forbidden='x86-64-v4' ;;
  x86-64-v4|znver4) forbidden='x86-64-v[5-9]' ;;
  *) echo 'Unsupported CPU target' >&2; exit 1 ;;
esac
if grep -Eq "$forbidden" <<< "$notes"; then
  echo "FAIL: ELF exceeds ${2:-x86-64} ISA contract" >&2
  printf '%s\n' "$notes" >&2
  exit 1
fi
