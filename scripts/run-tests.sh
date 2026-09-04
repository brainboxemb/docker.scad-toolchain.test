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
  "${OUT}/pythonscad-openscad-object" \
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

run_expected_failure() {
  local label="$1"
  local expected_pattern="$2"
  shift 2

  local log
  log="$(mktemp)"

  echo
  echo "== ${label} =="

  set +e
  "$@" 2>&1 | tee "$log"
  local status=${PIPESTATUS[0]}
  set -e

  if (( status == 0 )); then
    echo "ERROR: ${label} unexpectedly succeeded; review the documented XFAIL." >&2
    rm -f "$log"
    return 1
  fi

  if grep -Fq "$expected_pattern" "$log"; then
    echo "XFAIL: ${label}"
    echo "Reason: known PythonSCAD/OpenSCAD runtime compatibility mismatch."
    rm -f "$log"
    return 0
  fi

  echo "ERROR: ${label} failed for an unexpected reason." >&2
  echo "Expected log pattern: $expected_pattern" >&2
  rm -f "$log"
  return 1
}

# -------------------------------------------------------------------
# 1. Toolchain / environment
# -------------------------------------------------------------------

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

# -------------------------------------------------------------------
# 2. Base functionality
# -------------------------------------------------------------------

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
# 3. Additional runtime tests
# -------------------------------------------------------------------

echo
echo "== PythonSCAD -D define test =="
bash "$ROOT/scripts/test-pythonscad-defines.sh"

echo
echo "== PythonSCAD embedded sys.path probe =="
run_checked "PythonSCAD sys.path probe" \
  xvfb-run -a pythonscad \
    -o "${OUT}/pythonscad/path-probe.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/python_path_probe.py"
test -s "${OUT}/pythonscad/path-probe.stl"

# -------------------------------------------------------------------
# 4. Library / interoperability
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

# Known incompatibility probe:
# BOSL2/std.scad uses OpenSCAD's date-based version_num() as a compatibility
# gate. PythonSCAD reports its own semantic-version value through the SCAD
# compatibility runtime, so BOSL2 currently rejects the runtime.
run_expected_failure \
  "PythonSCAD -> BOSL2 SCAD (expected incompatibility)" \
  "BOSL2 requires OpenSCAD version 2021.01 or later." \
  xvfb-run -a pythonscad \
    -o "${OUT}/bosl2-pythonscad-scad/xfail.stl" \
    --trust-python \
    "${ROOT}/test/pythonscad/bosl2_scad.py"

# Known incompatibility probe:
# OpenSCAD experimental object() values do not currently cross into PythonSCAD
# as usable Python-side objects.
run_expected_failure \
  "PythonSCAD -> OpenSCAD object() (expected incompatibility)" \
  "PYTHONSCAD_OPENSCAD_OBJECT_XFAIL" \
  env \
    OPENSCAD_OBJECT_PROBE_SCAD="${ROOT}/test/pythonscad/openscad_object/object_api.scad" \
    xvfb-run -a pythonscad \
      --enable=object-function \
      -o "${OUT}/pythonscad-openscad-object/xfail.stl" \
      --trust-python \
      "${ROOT}/test/pythonscad/openscad_object/object_bridge_probe.py"

echo
echo "All supported SCAD toolchain consumer tests passed; documented XFAILs matched expectations."
