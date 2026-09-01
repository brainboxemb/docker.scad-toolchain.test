#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/out"

rm -rf "${OUT}"
mkdir -p "${OUT}/openscad" "${OUT}/pythonscad"

echo "== Toolchain information =="
scad-toolchain-info

echo
echo "== Public commands =="
command -v openscad
command -v pythonscad
command -v python3

echo
echo "== OpenSCAD version =="
openscad --version

echo
echo "== PythonSCAD version =="
pythonscad --version

echo
echo "== System Python =="
python3 --version

echo
echo "== OpenSCAD PNG =="
xvfb-run -a openscad   --render   --imgsize=800,600   -o "${OUT}/openscad/smoke.png"   "${ROOT}/test/openscad/smoke.scad"
test -s "${OUT}/openscad/smoke.png"

echo
echo "== OpenSCAD STL =="
openscad   -o "${OUT}/openscad/smoke.stl"   "${ROOT}/test/openscad/smoke.scad"
test -s "${OUT}/openscad/smoke.stl"

echo
echo "== PythonSCAD STL =="
xvfb-run -a pythonscad   -o "${OUT}/pythonscad/smoke.stl"   --trust-python   "${ROOT}/test/pythonscad/smoke.py"
test -s "${OUT}/pythonscad/smoke.stl"

echo
echo "All SCAD toolchain tests passed."
