#!/usr/bin/env bash
# External consumer check for toolchain v0.6.2's drawing-only
# NopSCADlib publishing prerequisites. Uses real public commands.
set -euo pipefail

OUT="${1:?pass the profile output directory}"
work="${OUT}/nopscadlib-publishing"
mkdir -p "$work"

for cmd in magick vcs codespell; do
  command -v "$cmd"
done

# ImageMagick 7 processes a real OpenSCAD-generated PNG.
magick "${OUT}/openscad/smoke.png" -trim -resize 256x256 \
  "$work/openscad-preview.png"

# Python Markdown and its tables extension generate HTML for project docs.
cat > "$work/example.md" <<'MD'
# Drawing documentation

| Operation | Result |
| --- | --- |
| Hull | Pass |

This example describes a practical drawing workflow.
MD
python3 -m markdown -x tables -x sane_lists \
  "$work/example.md" > "$work/example.html"
grep -q '<table>' "$work/example.html"
grep -q '<h1>Drawing documentation</h1>' "$work/example.html"

# Codespell should check project-owned Markdown without errors.
codespell "$work/example.md"

# vcs2l must fetch an actual pinned git dependency, not merely show help.
# Use a self-contained local repository: no external network request.
mkdir -p "$work/upstream"
git -C "$work/upstream" init -q
git -C "$work/upstream" config user.name "Runtime consumer"
git -C "$work/upstream" config user.email "consumer@example.invalid"
printf 'pinned dependency content\n' > "$work/upstream/fixture.txt"
git -C "$work/upstream" add fixture.txt
git -C "$work/upstream" commit -qm "Consumer fixture"
rev="$(git -C "$work/upstream" rev-parse HEAD)"
cat > "$work/dependencies.repos" <<YAML
repositories:
  ConsumerFixture:
    type: git
    url: file://$work/upstream
    version: $rev
YAML
mkdir -p "$work/imported"
vcs import --input "$work/dependencies.repos" "$work/imported"
test -s "$work/imported/ConsumerFixture/fixture.txt"
grep -Fq 'pinned dependency content' "$work/imported/ConsumerFixture/fixture.txt"

# Check actual output and dependency imports.
python3 - "$work/openscad-preview.png" <<'PY'
from pathlib import Path
import sys
import colorama
import markdown
from PIL import Image

assert colorama.Fore.GREEN
assert markdown.__version__
with Image.open(Path(sys.argv[1])) as image:
    assert image.format == "PNG"
    assert image.width <= 256 and image.height <= 256
    assert image.width > 0 and image.height > 0
print("Drawing prerequisites: ImageMagick, Markdown, codespell, colorama, vcs2l PASS")
PY
