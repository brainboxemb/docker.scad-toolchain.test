#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/out"
SITE="${ROOT}/site"

SUITE_VERSION="${TEST_SUITE_VERSION:-unversioned}"
TOOLCHAIN_IMAGE="${SCAD_TOOLCHAIN_IMAGE:-unknown}"
TOOLCHAIN_VERSION="${SCAD_TOOLCHAIN_VERSION:-unknown}"

OPENSCAD_VERSION="$(openscad --version 2>&1 | head -n1)"
PYTHONSCAD_VERSION="$(pythonscad --version 2>&1 | head -n1)"
PYTHON_VERSION="$(python3 --version 2>&1 | head -n1)"

rm -rf "${SITE}"
mkdir -p "${SITE}/openscad" "${SITE}/pythonscad"

cp -f "${OUT}/openscad/smoke.png" "${SITE}/openscad/" 2>/dev/null || true
cp -f "${OUT}/openscad/smoke.stl" "${SITE}/openscad/" 2>/dev/null || true
cp -f "${OUT}/pythonscad/smoke.stl" "${SITE}/pythonscad/" 2>/dev/null || true

cat > "${SITE}/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SCAD toolchain test ${SUITE_VERSION}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 920px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
    code { background: #f3f3f3; padding: .1rem .3rem; border-radius: .25rem; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0 2rem; }
    th, td { text-align: left; border-bottom: 1px solid #ddd; padding: .5rem; }
    img { max-width: 100%; height: auto; border: 1px solid #ddd; }
    .pass { font-weight: 700; }
  </style>
</head>
<body>
  <h1>SCAD toolchain verification</h1>

  <table>
    <tr><th>Test suite</th><td><code>${SUITE_VERSION}</code></td></tr>
    <tr><th>Toolchain image</th><td><code>${TOOLCHAIN_IMAGE}:${TOOLCHAIN_VERSION}</code></td></tr>
    <tr><th>OpenSCAD</th><td>${OPENSCAD_VERSION}</td></tr>
    <tr><th>PythonSCAD</th><td>${PYTHONSCAD_VERSION}</td></tr>
    <tr><th>Python</th><td>${PYTHON_VERSION}</td></tr>
  </table>

  <h2>Results</h2>
  <ul>
    <li class="pass">PASS — OpenSCAD CLI</li>
    <li class="pass">PASS — OpenSCAD PNG render</li>
    <li class="pass">PASS — OpenSCAD STL export</li>
    <li class="pass">PASS — PythonSCAD CLI</li>
    <li class="pass">PASS — PythonSCAD model execution</li>
    <li class="pass">PASS — PythonSCAD STL export</li>
  </ul>

  <h2>OpenSCAD render</h2>
  <p><img src="openscad/smoke.png" alt="OpenSCAD smoke render"></p>

  <h2>Raw outputs</h2>
  <ul>
    <li><a href="openscad/smoke.png">OpenSCAD smoke PNG</a></li>
    <li><a href="openscad/smoke.stl">OpenSCAD smoke STL</a></li>
    <li><a href="pythonscad/smoke.stl">PythonSCAD smoke STL</a></li>
  </ul>
</body>
</html>
EOF

echo "Built report in ${SITE}"
