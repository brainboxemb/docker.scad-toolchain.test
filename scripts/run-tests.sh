#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/out"

rm -rf "${OUT}"
mkdir -p "${OUT}/openscad" "${OUT}/pythonscad"

echo "== Toolchain information =="
if command -v scad-toolchain-info >/dev/null 2>&1; then
  scad-toolchain-info
fi

echo
echo "== OpenSCAD version =="
openscad --version

echo
echo "== Python =="
python3 --version

echo
echo "== PythonSCAD import =="
python3 - <<'PY'
import pythonscad
print("PythonSCAD import: OK")
print("module:", pythonscad.__file__)
PY

echo
echo "== OpenSCAD PNG =="
xvfb-run -a openscad   --render   --imgsize=800,600   -o "${OUT}/openscad/smoke.png"   "${ROOT}/test/openscad/smoke.scad"

test -s "${OUT}/openscad/smoke.png"

echo
echo "== OpenSCAD STL =="
openscad   -o "${OUT}/openscad/smoke.stl"   "${ROOT}/test/openscad/smoke.scad"

test -s "${OUT}/openscad/smoke.stl"

echo
echo "== PythonSCAD model =="
# PythonSCAD currently executes Python design files through its supplied
# command/runtime. Keep the command in this external suite so it can evolve
# independently from older toolchain versions.
if command -v pythonscad >/dev/null 2>&1; then
  xvfb-run -a pythonscad     -o "${OUT}/pythonscad/smoke.stl"     "${ROOT}/test/pythonscad/smoke.py"
elif command -v openscad-python >/dev/null 2>&1; then
  xvfb-run -a openscad-python     -o "${OUT}/pythonscad/smoke.stl"     "${ROOT}/test/pythonscad/smoke.py"
else
  echo "ERROR: No PythonSCAD CLI command found in the toolchain." >&2
  exit 1
fi

test -s "${OUT}/pythonscad/smoke.stl"

echo
echo "All SCAD toolchain tests passed."
