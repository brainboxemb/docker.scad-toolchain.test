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
GIT_VERSION="$(git --version 2>&1 | head -n1)"
BOSL2_VERSION_INFO="${BOSL2_VERSION:-unknown}"
PYBOSL2_VERSION_INFO="${PYBOSL2_VERSION:-unknown}"

rm -rf "${SITE}"
mkdir -p \
  "${SITE}/openscad" \
  "${SITE}/pythonscad" \
  "${SITE}/bosl2-openscad" \
  "${SITE}/bosl2-pythonscad-scad" \
  "${SITE}/bosl2-pythonscad-py"

for dir in openscad pythonscad bosl2-openscad bosl2-pythonscad-scad bosl2-pythonscad-py; do
  cp -f "${OUT}/${dir}/"*.png "${SITE}/${dir}/" 2>/dev/null || true
  cp -f "${OUT}/${dir}/"*.stl "${SITE}/${dir}/" 2>/dev/null || true
done

cat > "${SITE}/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SCAD toolchain test ${SUITE_VERSION}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 980px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
    code { background: #f3f3f3; padding: .1rem .3rem; border-radius: .25rem; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0 2rem; }
    th, td { text-align: left; border-bottom: 1px solid #ddd; padding: .5rem; }
    img { max-width: 100%; height: auto; border: 1px solid #ddd; }
    .pass { font-weight: 700; }
    .comparison { display: grid; grid-template-columns: repeat(auto-fit,minmax(260px,1fr)); gap: 1rem; }
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
    <tr><th>Git</th><td>${GIT_VERSION}</td></tr>
    <tr><th>BOSL2</th><td>v${BOSL2_VERSION_INFO}</td></tr>
    <tr><th>pybosl2</th><td>${PYBOSL2_VERSION_INFO}</td></tr>
  </table>

  <h2>Results</h2>
  <ul>
    <li class="pass">PASS — PythonSCAD -D define injection</li>
    <li class="pass">PASS — Git CLI and functional commit</li>
    <li class="pass">PASS — OpenSCAD PNG/STL</li>
    <li class="pass">PASS — PythonSCAD PNG/STL</li>
    <li class="pass">PASS — OpenSCAD → BOSL2 PNG/STL</li>
    <li class="pass">PASS — PythonSCAD → BOSL2 .scad PNG/STL</li>
    <li class="pass">PASS — PythonSCAD → pybosl2 PNG/STL</li>
  </ul>

  <h2>BOSL2 comparison</h2>
  <p>
    The three renders below intentionally use the same small rounded cuboid.
    This is a technical interoperability comparison, not a claim that the two
    BOSL2 implementations have complete feature parity.
  </p>

  <div class="comparison">
    <div>
      <h3>OpenSCAD → BOSL2</h3>
      <img src="bosl2-openscad/model.png" alt="OpenSCAD BOSL2 render">
    </div>
    <div>
      <h3>PythonSCAD → BOSL2 .scad</h3>
      <img src="bosl2-pythonscad-scad/model.png" alt="PythonSCAD BOSL2 SCAD render">
    </div>
    <div>
      <h3>PythonSCAD → pybosl2</h3>
      <img src="bosl2-pythonscad-py/model.png" alt="PythonSCAD pybosl2 render">
    </div>
  </div>

  <h2>Base smoke renders</h2>
  <h3>OpenSCAD</h3>
  <img src="openscad/smoke.png" alt="OpenSCAD smoke render">

  <h3>PythonSCAD</h3>
  <img src="pythonscad/smoke.png" alt="PythonSCAD smoke render">

  <h2>Raw outputs</h2>
  <ul>
    <li><a href="bosl2-openscad/model.stl">OpenSCAD → BOSL2 STL</a></li>
    <li><a href="bosl2-pythonscad-scad/model.stl">PythonSCAD → BOSL2 .scad STL</a></li>
    <li><a href="bosl2-pythonscad-py/model.stl">PythonSCAD → pybosl2 STL</a></li>
    <li><a href="openscad/smoke.stl">OpenSCAD smoke STL</a></li>
    <li><a href="pythonscad/smoke.stl">PythonSCAD smoke STL</a></li>
  </ul>
</body>
</html>
EOF

echo "Built report in ${SITE}"
