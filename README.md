# docker.scad-toolchain.test

> **Test results:** https://brainboxemb.github.io/docker.scad-toolchain.test/

External consumer-validation suite for the published SCAD runtime image family:

```text
ghcr.io/brainboxemb/scad-toolchain-openscad
ghcr.io/brainboxemb/scad-toolchain-drawing
ghcr.io/brainboxemb/scad-toolchain
```

This repository tests published images rather than repeating their internal
Docker build checks.

## Runtime matrix

The suite treats the three images as capability profiles from one shared base:
OpenSCAD-focused, drawing, and full/PythonSCAD.

Shared contract, tested against all three profiles:

- `openscad`;
- Python 3;
- Git;
- SCons;
- `scad-toolchain-info` and profile identity;
- OpenSCAD PNG/STL generation;
- OpenSCAD -> BOSL2;
- `openscad-docsgen` / `openscad-mdimggen`;
- `scad-image-watermark` / Pillow;
- generic published-runtime filesystem/environment expectations.

Additional drawing-runtime contract:

- `inkscape` and the `drawsvg` Python package are present only in the drawing profile;
- OpenSCAD generates source SVG geometry;
- suite-owned Python uses drawsvg to compose an annotated A4 SVG;
- that Python producer invokes Inkscape to export the SVG to valid PNG and PDF.

Additional full-runtime contract:

- `pythonscad` PNG/STL;
- PythonSCAD `-D` define injection;
- embedded Python path probe;
- PythonSCAD -> pybosl2;
- documented interoperability XFAIL probes.

A missing PythonSCAD command in the OpenSCAD profile is expected, not a test
failure.

## Current development target

The suite is being advanced for the toolchain v0.6.1 drawing-runtime authoring stack.
During qualification, the development branch targets the producer's mutable
`:edge` images:

```text
SCAD_TOOLCHAIN_OPENSCAD_IMAGE=ghcr.io/brainboxemb/scad-toolchain-openscad
SCAD_TOOLCHAIN_DRAWING_IMAGE=ghcr.io/brainboxemb/scad-toolchain-drawing
SCAD_TOOLCHAIN_FULL_IMAGE=ghcr.io/brainboxemb/scad-toolchain
SCAD_TOOLCHAIN_VERSION=edge
```

Once `edge` is green for all three profiles and toolchain v0.6.1 is released,
the suite is rerun against the exact immutable `v0.6.1` images before creating
the corresponding permanent test-suite tag.

## Version resolution

Immutable test releases use:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

For the current dimension-library qualification the intended record is:

```text
test-v0.5.1-toolchain-v0.5.1
```

The workflow resolves runtime versions as follows:

```text
main / pull request
    -> version from toolchain.env

workflow_dispatch
    -> optional explicit override
    -> for example edge, sha-eeb40e7 or v0.6.0

tag test-v0.6.0-toolchain-v0.6.0
    -> automatically v0.6.0
```

All three runtime package names receive the same resolved version.

## Distribution measurements

Routine qualification runs on one hosted Ubuntu runner:

1. pull and test the OpenSCAD profile;
2. keep those Docker layers locally available;
3. pull and test the drawing profile;
4. pull and test the full/PythonSCAD profile;
5. report exact linux/amd64 compressed OCI bytes and Docker unpacked image size.

This reflects efficient normal use and shows how much additional data the full
profile needs once shared layers are present.

Migration 005 also performed one controlled cold-vs-cold benchmark by clearing
Docker state between pulls. That benchmark is historical architecture evidence;
destructive pruning is deliberately **not** part of routine CI because it
throws away shared data and unrelated hosted-runner images.

Historical Migration 005 two-profile measurements:

| Profile | Compressed OCI bytes | Unpacked bytes | Controlled cold pull |
| --- | ---: | ---: | ---: |
| OpenSCAD-focused | 328,098,501 | 961,779,232 | 13.211 s |
| full/dual | 449,516,893 | 1,313,898,129 | 15.464 s |

The focused runtime removes 121,418,392 compressed bytes, about 27.0% of the
full image, for consumers that do not need PythonSCAD.

## PNG watermark tooling

All three profiles must expose:

```text
scad-image-watermark
```

The external suite produces a real OpenSCAD PNG, applies a copyright label and
checks that the resulting PNG is valid, keeps the original dimensions and is
not byte-identical to its input.

## OpenSCAD documentation tooling

All three profiles must expose:

```text
openscad-docsgen
openscad-mdimggen
```

The suite runs a real docsgen parse and Markdown generation against a consumer
`.scad` source. The generated Markdown must be non-empty and contain the
expected module documentation.

## Drawing publication capability

The drawing profile validates the intended text/code-driven publication chain:

```text
OpenSCAD geometry/projections
    -> suite-owned Python + drawsvg composition
    -> canonical SVG
    -> Python invokes Inkscape CLI
    -> SVG / PNG / PDF
```

The external test checks real generated artifacts. It does not treat
`command -v inkscape` or a successful drawsvg import as sufficient evidence, and it verifies that Inkscape is
not silently present in the OpenSCAD-focused or full/PythonSCAD profiles.

The previous v0.5.1 immutable records remain historical evidence for the
`openscad-new-dimensions` experiment. That library is not part of the current
v0.6.0 runtime contract.

## BOSL2 capability comparison

The suite deliberately keeps these routes separate:

```text
OpenSCAD   -> BOSL2          PASS expected, all three profiles
PythonSCAD -> pybosl2        PASS expected, full profile only
PythonSCAD -> BOSL2 .scad    XFAIL compatibility probe, full only
```

Native OpenSCAD uses:

```scad
include <BOSL2/std.scad>

cuboid([30, 20, 10], rounding=3);
```

The runtime exposes:

```text
OPENSCADPATH=/opt/openscad-libraries
BOSL2_ROOT=/opt/openscad-libraries/BOSL2
```

OpenSCAD resolves normal include/use through `OPENSCADPATH`. PythonSCAD
`osuse()` needs a real file path and therefore uses `BOSL2_ROOT`.

## PythonSCAD and pybosl2

The full runtime installs pybosl2 and Shapely under:

```text
/opt/python-libs
```

PythonSCAD embeds CPython and may require the shared package path to be added
explicitly:

```python
import sys
sys.path.insert(0, "/opt/python-libs")

from pythonscad import *
from pybosl2 import cuboid

part = cuboid([30, 20, 10], rounding=3)
part.show()
```

Test files must not be named `pybosl2.py`, because a local file with that name
shadows the installed package.

## PythonSCAD interoperability findings

The suite records known limitations as active XFAIL tests rather than silently
ignoring them.

| Capability | Expected status | Finding |
| --- | --- | --- |
| OpenSCAD -> BOSL2 | PASS | Native BOSL2/OpenSCAD path |
| PythonSCAD -> pybosl2 | PASS | Python-native comparison route |
| PythonSCAD -> BOSL2 `.scad` via `osuse()` | XFAIL | BOSL2's OpenSCAD runtime/version assumptions are not equivalent to PythonSCAD semantics |
| PythonSCAD -> OpenSCAD experimental `object()` | XFAIL | Object-based OpenSCAD APIs do not currently cross as usable Python-side objects |

The XFAILs are deliberately strict:

- the documented failure mode is accepted;
- unexpected success fails the suite so the conclusion must be reviewed;
- a different failure also fails the suite.

This means PythonSCAD remains a supported alternative/experimental runtime for
projects that intentionally use it, while OpenSCAD remains the primary base for
reusable SCAD-library APIs in the current ecosystem.

## Test execution order

The profile-aware runner follows the dependency chain:

```text
1. Toolchain / environment
2. Shared OpenSCAD base functionality
3. Shared OpenSCAD libraries/tooling
4. Documentation tooling
5. Drawing publication, when profile=drawing
6. Full-runtime PythonSCAD/interoperability checks, when profile=full
```

This keeps failures interpretable: establish the shared runtime contract before
advanced dual-runtime behaviour.

## Reports and artifacts

Each profile writes separate raw output below `out/`. The final report combines
all three profiles and keeps profile identity visible.

The report includes:

- PASS/XFAIL table with compressed Docker image size per profile;
- profile-specific sections;
- representative generated renders;
- exact runtime image names/versions, including drawing-only Inkscape/drawsvg
  and full-only Python libraries;
- raw image-distribution metrics.

Successful non-PR runs update GitHub Pages:

```text
/latest/
```

A released test tag gets a permanent tag-named directory and the root index
keeps historical reports.

## Release sequence

For the v0.5.0 runtime family:

1. qualify the exact runtime candidate images;
2. merge the image-family implementation and this profile-aware external suite;
3. let runtime `main` publish both `:edge` profiles and require external green;
4. publish immutable toolchain `v0.5.0`;
5. let the toolchain tag automatically dispatch this suite with
   `toolchain_version=v0.5.0`;
6. require that immutable-runtime run to pass;
7. create the test-suite release with:
   - suite version `v0.5.0`;
   - toolchain version `v0.5.0`;
   - exact verified test-suite source SHA;
8. require `test-v0.5.0-toolchain-v0.5.0` to pass and publish permanent Pages
   evidence.

Only after that final record is green should downstream tooling pin v0.5.0.

A failed interoperability test is useful evidence. Do not mask it merely to
make a release green.
