#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_OUT="${SCAD_TOOLCHAIN_TEST_OUT:-${ROOT}/out}"
OUT="${PROFILE_OUT}/scons"

rm -rf "${OUT}"
mkdir -p "${OUT}"

echo "== SCons -> OpenSCAD consumer test =="
command -v scons
scons --version

scons \
  -Q \
  -f "${ROOT}/test/scons/SConstruct" \
  ROOT="${ROOT}" \
  OUT="${OUT}"

test -s "${OUT}/smoke.stl"
printf 'SCons OpenSCAD output: %s\n' "${OUT}/smoke.stl"
