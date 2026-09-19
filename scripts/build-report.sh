#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/out"
SITE="${ROOT}/site"

SUITE_VERSION="${TEST_SUITE_VERSION:-unversioned}"
TOOLCHAIN_VERSION="${SCAD_TOOLCHAIN_VERSION:-unknown}"
OPENSCAD_CONTAINER="${OPENSCAD_CONTAINER:-unknown}"
DRAWING_CONTAINER="${DRAWING_CONTAINER:-unknown}"
FULL_CONTAINER="${FULL_CONTAINER:-unknown}"

OPENSCAD_VERSION="$(openscad --version 2>&1 | head -n1)"
PYTHONSCAD_VERSION="$(pythonscad --version 2>&1 | head -n1)"
PYTHON_VERSION="$(python3 --version 2>&1 | head -n1)"
GIT_VERSION="$(git --version 2>&1 | head -n1)"
SCONS_VERSION_INFO="$(python3 -c 'import SCons; print(SCons.__version__)')"
DOCSGEN_VERSION="$(python3 -c 'import importlib.metadata as m; print(m.version("openscad_docsgen"))')"
PILLOW_VERSION_INFO="$(python3 -c 'import importlib.metadata as m; print(m.version("Pillow"))')"
BOSL2_VERSION_INFO="${BOSL2_VERSION:-unknown}"
PYBOSL2_VERSION_INFO="${PYBOSL2_VERSION:-unknown}"

rm -rf "${SITE}"
mkdir -p "${SITE}/openscad" "${SITE}/drawing" "${SITE}/full"
cp -a "${OUT}/openscad-profile/." "${SITE}/openscad/"
cp -a "${OUT}/drawing-profile/." "${SITE}/drawing/"
cp -a "${OUT}/full-profile/." "${SITE}/full/"
cp -f "${OUT}/image-metrics.txt" "${SITE}/image-metrics.txt"

METRICS="$(cat "${OUT}/image-metrics.txt")"

cat > "${SITE}/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SCAD toolchain test ${SUITE_VERSION}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 1080px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
    code, pre { background: #f3f3f3; border-radius: .25rem; }
    code { padding: .1rem .3rem; }
    pre { padding: .8rem; overflow-x: auto; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0 2rem; }
    th, td { text-align: left; border-bottom: 1px solid #ddd; padding: .5rem; vertical-align: top; }
    img { max-width: 100%; height: auto; border: 1px solid #ddd; }
    .pass, .xfail { font-weight: 700; }
    .comparison { display: grid; grid-template-columns: repeat(auto-fit,minmax(300px,1fr)); gap: 1rem; }
  </style>
</head>
<body>
  <h1>SCAD toolchain runtime-family verification</h1>

  <p>
    One external suite validates three related runtime profiles. Shared OpenSCAD
    behavior is tested independently in all three images; drawing publication
    is isolated to the drawing runtime and PythonSCAD-specific behavior remains
    required only from the full runtime.
  </p>

  <h2>Profile summary</h2>
  <table>
    <tr><th>Capability</th><th>OpenSCAD runtime</th><th>Drawing runtime</th><th>Full runtime</th></tr>
    <tr><td>OpenSCAD PNG/STL</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>OpenSCAD → BOSL2</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>SCons → OpenSCAD</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>docsgen/mdimggen</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>watermark/Pillow</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>Inkscape drawing publication</td><td>not installed</td><td class="pass">PASS</td><td>not installed</td></tr>
    <tr><td>Git/tooling basics</td><td class="pass">PASS</td><td class="pass">PASS</td><td class="pass">PASS</td></tr>
    <tr><td>PythonSCAD PNG/STL</td><td>not required</td><td>not required</td><td class="pass">PASS</td></tr>
    <tr><td>PythonSCAD → pybosl2</td><td>not required</td><td>not required</td><td class="pass">PASS</td></tr>
    <tr><td>PythonSCAD → BOSL2 .scad</td><td>not required</td><td>not required</td><td class="xfail">XFAIL</td></tr>
    <tr><td>PythonSCAD → OpenSCAD object()</td><td>not required</td><td>not required</td><td class="xfail">XFAIL</td></tr>
  </table>

  <h2>Exact runtime inputs</h2>
  <table>
    <tr><th>Test suite</th><td><code>${SUITE_VERSION}</code></td></tr>
    <tr><th>Toolchain version/tag</th><td><code>${TOOLCHAIN_VERSION}</code></td></tr>
    <tr><th>OpenSCAD image</th><td><code>${OPENSCAD_CONTAINER}</code></td></tr>
    <tr><th>Drawing image</th><td><code>${DRAWING_CONTAINER}</code></td></tr>
    <tr><th>Full image</th><td><code>${FULL_CONTAINER}</code></td></tr>
    <tr><th>OpenSCAD</th><td>${OPENSCAD_VERSION}</td></tr>
    <tr><th>PythonSCAD (full)</th><td>${PYTHONSCAD_VERSION}</td></tr>
    <tr><th>Python</th><td>${PYTHON_VERSION}</td></tr>
    <tr><th>Git</th><td>${GIT_VERSION}</td></tr>
    <tr><th>SCons</th><td>${SCONS_VERSION_INFO}</td></tr>
    <tr><th>openscad_docsgen</th><td>${DOCSGEN_VERSION}</td></tr>
    <tr><th>Pillow</th><td>${PILLOW_VERSION_INFO}</td></tr>
    <tr><th>BOSL2</th><td>v${BOSL2_VERSION_INFO}</td></tr>
    <tr><th>pybosl2 (full)</th><td>${PYBOSL2_VERSION_INFO}</td></tr>
  </table>

  <h2>Distribution measurements</h2>
  <p>
    Exact compressed bytes are the linux/amd64 OCI layer sizes and unpacked
    bytes are reported by Docker after pull. Routine qualification keeps the
    OpenSCAD image layers locally available before pulling the full superset,
    so the raw metric explicitly identifies whether pull time is fresh-runner
    or shared-layer reuse. Independent cold-pull benchmarking is kept out of
    routine CI to avoid deliberately deleting and redownloading shared data.
  </p>
  <pre>${METRICS}</pre>
  <p><a href="image-metrics.txt">Raw image metrics</a></p>

  <h2>Shared OpenSCAD evidence</h2>
  <div class="comparison">
    <div>
      <h3>OpenSCAD-focused image</h3>
      <img src="openscad/openscad/smoke.png" alt="OpenSCAD runtime smoke render">
      <p><a href="openscad/openscad/smoke.stl">Smoke STL</a></p>
      <p><a href="openscad/scons/smoke.stl">SCons → OpenSCAD STL</a></p>
      <p><a href="openscad/docsgen/docsgen.scad.md">Generated docs</a></p>
    </div>
    <div>
      <h3>Drawing image — same OpenSCAD contract</h3>
      <img src="drawing/openscad/smoke.png" alt="Drawing runtime OpenSCAD smoke render">
      <p><a href="drawing/openscad/smoke.stl">Smoke STL</a></p>
      <p><a href="drawing/scons/smoke.stl">SCons → OpenSCAD STL</a></p>
      <p><a href="drawing/docsgen/docsgen.scad.md">Generated docs</a></p>
    </div>
    <div>
      <h3>Full image — same OpenSCAD contract</h3>
      <img src="full/openscad/smoke.png" alt="Full runtime OpenSCAD smoke render">
      <p><a href="full/openscad/smoke.stl">Smoke STL</a></p>
      <p><a href="full/scons/smoke.stl">SCons → OpenSCAD STL</a></p>
      <p><a href="full/docsgen/docsgen.scad.md">Generated docs</a></p>
    </div>
  </div>

  <h3>Watermark</h3>
  <div class="comparison">
    <img src="openscad/watermark/openscad-smoke-watermarked.png" alt="OpenSCAD runtime watermarked render">
    <img src="drawing/watermark/openscad-smoke-watermarked.png" alt="Drawing runtime watermarked render">
    <img src="full/watermark/openscad-smoke-watermarked.png" alt="Full runtime watermarked render">
  </div>

  <h3>OpenSCAD → BOSL2</h3>
  <div class="comparison">
    <img src="openscad/bosl2-openscad/model.png" alt="OpenSCAD runtime BOSL2 render">
    <img src="drawing/bosl2-openscad/model.png" alt="Drawing runtime BOSL2 render">
    <img src="full/bosl2-openscad/model.png" alt="Full runtime BOSL2 render">
  </div>

  <h2>Drawing-runtime publication evidence</h2>
  <p>
    OpenSCAD generates the source geometry. A suite-owned Python script composes
    that geometry into an A4 SVG with annotations and a title block. Inkscape
    then exports the same composed sheet to PNG and PDF.
  </p>
  <div class="comparison">
    <div>
      <img src="drawing/drawing/composed-a4.png" alt="Drawing runtime composed A4 technical drawing">
      <p><a href="drawing/drawing/composed-a4.svg">Composed SVG</a></p>
      <p><a href="drawing/drawing/composed-a4.pdf">Exported PDF</a></p>
    </div>
  </div>

  <h2>Full-runtime PythonSCAD evidence</h2>
  <div class="comparison">
    <div>
      <h3>PythonSCAD</h3>
      <img src="full/pythonscad/smoke.png" alt="PythonSCAD smoke render">
      <p><a href="full/pythonscad/smoke.stl">PythonSCAD smoke STL</a></p>
    </div>
    <div>
      <h3>PythonSCAD → pybosl2</h3>
      <img src="full/bosl2-pythonscad-py/model.png" alt="PythonSCAD pybosl2 render">
      <p><a href="full/bosl2-pythonscad-py/model.stl">pybosl2 STL</a></p>
    </div>
  </div>

  <h3>Active compatibility probes</h3>
  <p>
    <strong>XFAIL — PythonSCAD → BOSL2 .scad:</strong> the known runtime/version
    compatibility mismatch is still required to fail for the documented reason.
  </p>
  <p>
    <strong>XFAIL — PythonSCAD → OpenSCAD object():</strong> OpenSCAD object values
    still do not cross as usable Python-side objects. Unexpected success or any
    different failure fails the suite and requires review.
  </p>

  <h2>Raw profile outputs</h2>
  <ul>
    <li><a href="openscad/">OpenSCAD runtime outputs</a></li>
    <li><a href="drawing/">Drawing runtime outputs</a></li>
    <li><a href="full/">Full runtime outputs</a></li>
  </ul>
</body>
</html>
EOF

echo "Built combined runtime-family report in ${SITE}"
