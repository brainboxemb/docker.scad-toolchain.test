#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/test/pythonscad/define-probe.py"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run_case() {
  local label="$1"
  local expected="$2"
  shift 2

  local log="$TMP_DIR/$label.log"
  local out="$TMP_DIR/$label.stl"

  echo "-- $label"

  set +e
  xvfb-run -a pythonscad \
    --trust-python \
    "$@" \
    -o "$out" \
    "$SOURCE" \
    2>&1 | tee "$log"
  local status=${PIPESTATUS[0]}
  set -e

  if (( status != 0 )); then
    echo "ERROR: $label exited with $status" >&2
    return "$status"
  fi

  if grep -Eq '(^|[[:space:]])ERROR:' "$log"; then
    echo "ERROR: $label reported ERROR: in its log" >&2
    return 1
  fi

  if ! grep -Fq "INJECTED_DESIGN_VIEW=$expected" "$log"; then
    echo "ERROR: expected INJECTED_DESIGN_VIEW=$expected" >&2
    return 1
  fi

  if [[ ! -s "$out" ]]; then
    echo "ERROR: $label did not produce a non-empty STL" >&2
    return 1
  fi
}

echo "== PythonSCAD -D define behavior =="

run_case "define-01-ring" "01-ring" \
  -D 'design_view="01-ring"'

run_case "define-02-opening" "02-opening" \
  -D 'design_view="02-opening"'

run_case "define-final" "final" \
  -D 'design_view="final"'

run_case "define-missing" "<missing>"

echo
echo "PythonSCAD -D define behavior passed."
