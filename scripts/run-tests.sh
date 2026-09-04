#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/out"

rm -rf "${OUT}"
mkdir -p \
  "${OUT}/openscad" \
  "${OUT}/pythonscad" \
  "${OUT}/bosl2-openscad" \
  "${OUT}/bosl2-pythonscad-scad" \
  "${OUT}/bosl2-pythonscad-py"

run_checked() {
  local label="$1"
  shift

  local log
  log="$(mktemp)"

  echo
  echo "== ${label} =="

  set +e
  "$@" 2>&1 | tee "$log"
  local status=${PIPESTATUS[0]}
  set -e

  if (( status != 0 )); then
    echo "ERROR: ${label} failed with exit code ${status}" >&2
    rm -f "$log"
    return "$status"
  fi

  if grep -Eq '(^|[[:space:]])ERROR:' "$log"; then
    echo "ERROR: ${label} reported ERROR: in its log" >&2
    rm -f "$log"
    return 1
  fi

  rm -f "$log"
}

echo "== Toolchain information =="
scad-toolchain-info

echo
echo "== Public commands =="
command -v openscad
command -v pythonscad
command -v python3
command -v git

echo
echo "== Environment library paths =="
printf 'OPENSCADPATH=%s\n' "${OPENSCADPATH:-<unset>}"
printf 'BOSL2_ROOT=%s\n' "${BOSL2_ROOT:-<unset>}"
printf 'PYTHONPATH=%s\n' "${PYTHONPATH:-<unset>}"

test -n "${BOSL2_ROOT:-}"
test -f "${BOSL2_ROOT}/std.scad"
test -f "${BOSL2_ROOT}/shapes3d.scad"

echo
echo "== Git functional smoke test =="
GIT_TEST_DIR="$(mktemp -d)"
git -C "$GIT_TEST_DIR" init -q
git -C "$GIT_TEST_DIR" config user.name "SCAD Toolchain Test"
git -C "$GIT_TEST_DIR" config user.email "scad-toolchain-test@example.invalid"
printf 'SCAD toolchain Git smoke test\n' > "$GIT_TEST_DIR/test.txt"
git -C "$GIT_TEST_DIR" add test.txt
git -C "$GIT_TEST_DIR" commit -q -m "Git smoke test"
git -C "$GIT_TEST_DIR" rev-parse --verify HEAD >/dev/null
rm -rf "$GIT_TEST_DIR"

echo
bash "$ROOT/scripts/test-pythonscad-defines.sh"

run_checked "OpenSCAD PNG" \
  xvfb-run -a openscad \
    --render \
    --imgsize=800,600 \
    -o "${OUT}/openscad/smoke.png" \
    "${ROOT}/test/openscad/smoke.scad"
test -s "${OUT}/openscad/smoke.png"

run_checked "OpenSCAD STL" \
  openscad \
    -o "${OUT}/openscad/smoke.stl" \
    "${ROOT}/test/openscad/smoke.scad"
test -s "${OUT}/openscad/smoke.stl"


echo
echo "== PythonSCAD embedded sys.path probe =="
run_checked "PythonSCAD sys.path probe" \
  xvfb-run -a pythonscad \
    -o "${OUT}/pythonscad/path-probe.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/python_path_probe.py"
test -s "${OUT}/pythonscad/path-probe.stl"

run_checked "PythonSCAD PNG" \
  xvfb-run -a pythonscad \
    --render \
    --imgsize=800,600 \
    -o "${OUT}/pythonscad/smoke.png" \
    --trust-python \
    "${ROOT}/test/pythonscad/smoke.py"
test -s "${OUT}/pythonscad/smoke.png"

run_checked "PythonSCAD STL" \
  xvfb-run -a pythonscad \
    -o "${OUT}/pythonscad/smoke.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/smoke.py"
test -s "${OUT}/pythonscad/smoke.stl"

# -------------------------------------------------------------------
# BOSL2 capability comparison
# -------------------------------------------------------------------

run_checked "OpenSCAD -> BOSL2 PNG" \
  xvfb-run -a openscad \
    --render \
    --imgsize=800,600 \
    -o "${OUT}/bosl2-openscad/model.png" \
    "${ROOT}/test/openscad/bosl2.scad"
test -s "${OUT}/bosl2-openscad/model.png"

run_checked "OpenSCAD -> BOSL2 STL" \
  openscad \
    -o "${OUT}/bosl2-openscad/model.stl" \
    "${ROOT}/test/openscad/bosl2.scad"
test -s "${OUT}/bosl2-openscad/model.stl"

run_checked "PythonSCAD -> BOSL2 SCAD PNG" \
  xvfb-run -a pythonscad \
    --render \
    --imgsize=800,600 \
    -o "${OUT}/bosl2-pythonscad-scad/model.png" \
    --trust-python \
    "${ROOT}/test/pythonscad/bosl2_scad.py"
test -s "${OUT}/bosl2-pythonscad-scad/model.png"

run_checked "PythonSCAD -> BOSL2 SCAD STL" \
  xvfb-run -a pythonscad \
    -o "${OUT}/bosl2-pythonscad-scad/model.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/bosl2_scad.py"
test -s "${OUT}/bosl2-pythonscad-scad/model.stl"

run_checked "PythonSCAD -> pybosl2 PNG" \
  xvfb-run -a pythonscad \
    --render \
    --imgsize=800,600 \
    -o "${OUT}/bosl2-pythonscad-py/model.png" \
    --trust-python \
    "${ROOT}/test/pythonscad/pybosl2_consumer.py"
test -s "${OUT}/bosl2-pythonscad-py/model.png"

run_checked "PythonSCAD -> pybosl2 STL" \
  xvfb-run -a pythonscad \
    -o "${OUT}/bosl2-pythonscad-py/model.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/pybosl2_consumer.py"
test -s "${OUT}/bosl2-pythonscad-py/model.stl"

echo
echo "All SCAD toolchain consumer tests passed."
