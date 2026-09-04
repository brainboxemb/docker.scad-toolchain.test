#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "${ROOT_DIR}"

mapfile -t versions < <(
  find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | grep -E '^test-v.*-toolchain-v.*$' \
    | sort -V -r
)

cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SCAD Toolchain Test Results</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 960px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; }
    code { background: #f3f3f3; padding: .1rem .3rem; border-radius: .25rem; }
    ul { padding-left: 1.25rem; }
    li { margin: .35rem 0; }
    .muted { color: #666; }
  </style>
</head>
<body>
  <h1>SCAD Toolchain Test Results</h1>
  <p>
    Published verification results for
    <code>ghcr.io/brainboxemb/scad-toolchain</code>.
  </p>

  <h2>Current development</h2>
  <ul>
    <li><a href="latest/">Latest successful test from main</a></li>
  </ul>

  <h2>Released test suites</h2>
EOF

if ((${#versions[@]} == 0)); then
  echo '  <p class="muted">No released test-suite reports have been published yet.</p>' >> index.html
else
  echo '  <ul>' >> index.html
  for version in "${versions[@]}"; do
    label="${version#test-v}"
    test_version="${label%%-toolchain-v*}"
    toolchain_version="${label##*-toolchain-v}"
    cat >> index.html <<EOF
    <li>
      <a href="${version}/">${version}</a>
      <span class="muted">— test suite v${test_version}, toolchain v${toolchain_version}</span>
    </li>
EOF
  done
  echo '  </ul>' >> index.html
fi

cat >> index.html <<'EOF'
</body>
</html>
EOF

echo "Generated Pages root index with ${#versions[@]} released report(s)."
