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
  "${SITE}/bosl2-pythonscad-py"

for dir in openscad pythonscad bosl2-openscad bosl2-pythonscad-py; do
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
    th, td { text-align: left; border-bottom: 1px solid #ddd; padding: .5rem; vertical-align: top; }
    img { max-width: 100%; height: auto; border: 1px solid #ddd; }
    .pass { font-weight: 700; }
    .xfail { font-weight: 700; }
    .comparison { display: grid; grid-template-columns: repeat(auto-fit,minmax(300px,1fr)); gap: 1rem; }
    .status-table td:first-child { white-space: nowrap; font-weight: 700; }
  </style>
</head>
<body>
  <h1>SCAD toolchain verification</h1>

  <h2>Test summary</h2>
  <table class="status-table">
    <tr><th>Status</th><th>Route / test</th><th>Meaning</th></tr>
    <tr><td class="pass">PASS</td><td>OpenSCAD → BOSL2</td><td>Native OpenSCAD/BOSL2 route works.</td></tr>
    <tr><td class="pass">PASS</td><td>PythonSCAD → pybosl2</td><td>Python-native BOSL2 comparison route works.</td></tr>
    <tr><td class="xfail">XFAIL</td><td>PythonSCAD → BOSL2 .scad via osuse()</td><td>Known OpenSCAD version/runtime compatibility mismatch.</td></tr>
    <tr><td class="xfail">XFAIL</td><td>PythonSCAD → OpenSCAD object()</td><td>OpenSCAD object values do not currently cross as usable Python-side objects.</td></tr>
    <tr><td class="pass">PASS</td><td>OpenSCAD PNG/STL smoke</td><td>Basic OpenSCAD rendering/export works.</td></tr>
    <tr><td class="pass">PASS</td><td>PythonSCAD PNG/STL smoke</td><td>Basic PythonSCAD rendering/export works.</td></tr>
    <tr><td class="pass">PASS</td><td>PythonSCAD -D define injection</td><td>Command-line parameter injection works.</td></tr>
    <tr><td class="pass">PASS</td><td>Git CLI / functional commit</td><td>Git is installed and functional.</td></tr>
  </table>

  <p>
    <strong>XFAIL</strong> means the route is actively executed and is expected
    to fail for one specific documented compatibility reason. A different
    failure or an unexpected success makes the suite fail so the status must be
    reviewed instead of silently becoming stale.
  </p>

  <h2>Interoperability findings</h2>

  <h3>XFAIL — PythonSCAD → BOSL2 .scad</h3>
  <p>
    BOSL2 <code>std.scad</code> relies on OpenSCAD's date-based
    <code>version_num()</code> compatibility gate. PythonSCAD exposes its own
    semantic-version value through the SCAD compatibility runtime, so BOSL2
    rejects the runtime before the test geometry is created.
  </p>

  <h3>XFAIL — PythonSCAD → OpenSCAD object()</h3>
  <p>
    OpenSCAD experimental <code>object()</code> values currently do not cross
    the PythonSCAD/OpenSCAD boundary as usable Python-side objects. This blocks
    the object-based library architecture tested here even though conventional
    module/function interoperability can work.
  </p>

  <p>
    Together these findings show that PythonSCAD can consume useful conventional
    OpenSCAD code, but advanced OpenSCAD libraries can depend on runtime and
    value semantics that PythonSCAD does not reproduce identically.
  </p>

  <h2>Supported BOSL2 geometry comparison</h2>
  <p>
    These are the two currently supported BOSL2 routes. Both intentionally
    render the same small rounded cuboid.
  </p>

  <div class="comparison">
    <div>
      <h3>OpenSCAD → BOSL2</h3>
      <img src="bosl2-openscad/model.png" alt="OpenSCAD BOSL2 render">
    </div>
    <div>
      <h3>PythonSCAD → pybosl2</h3>
      <img src="bosl2-pythonscad-py/model.png" alt="PythonSCAD pybosl2 render">
    </div>
  </div>

  <h2>Base smoke renders</h2>
  <div class="comparison">
    <div>
      <h3>OpenSCAD</h3>
      <img src="openscad/smoke.png" alt="OpenSCAD smoke render">
    </div>
    <div>
      <h3>PythonSCAD</h3>
      <img src="pythonscad/smoke.png" alt="PythonSCAD smoke render">
    </div>
  </div>

  <h2>Environment</h2>
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

  <h2>Raw outputs</h2>
  <ul>
    <li><a href="bosl2-openscad/model.stl">OpenSCAD → BOSL2 STL</a></li>
    <li><a href="bosl2-pythonscad-py/model.stl">PythonSCAD → pybosl2 STL</a></li>
    <li><a href="openscad/smoke.stl">OpenSCAD smoke STL</a></li>
    <li><a href="pythonscad/smoke.stl">PythonSCAD smoke STL</a></li>
  </ul>
</body>
</html>
EOF

echo "Built report in ${SITE}"
