# ChatGPT project handoff — docker.scad-toolchain.test

## Purpose

This repository is the external consumer-validation suite for the published
`ghcr.io/brainboxemb/scad-toolchain` image.

It is intentionally separate from `docker.scad-toolchain`.

The toolchain repository proves that an image can be built. This repository
proves that a **published image can actually be consumed** through its public
interface.

## Version model

The test-suite version and toolchain version are independent.

Released tags use:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

Never move or overwrite a released test tag.

`toolchain.env` contains the exact default image/version tested by `main`.
Manual workflow dispatch may temporarily override the toolchain version for
development.

During development, `main` deliberately targets:

```text
SCAD_TOOLCHAIN_VERSION=edge
```

A permanent test-suite release encodes the immutable toolchain version in its
tag:

```text
test-v0.2.0-toolchain-v0.2.0
```

The workflow parses `v0.2.0` from that tag and tests the corresponding
`:v0.2.0` image. Do not change `toolchain.env` to a not-yet-published release
tag just to prepare a release.

## Toolchain image resolution

Keep development and release behavior separate:

```text
main / pull request
    -> toolchain.env
    -> normally :edge

workflow_dispatch
    -> optional explicit version override

test-vX-toolchain-vY tag
    -> automatically :vY
```

This is important because the external consumer tests should run against
`:edge` **before** a new immutable toolchain release exists.

Once a test-suite release tag exists, it must never silently follow `:edge`.
Its toolchain version is encoded in the tag and is immutable.

## What must be tested

Base public commands:

```text
openscad
pythonscad
python3
git
scad-toolchain-info
```

Functional checks include PNG/STL generation, PythonSCAD command-line defines,
and a real temporary Git init/add/commit.

## BOSL2 comparison tests

The v0.2 suite adds three real CAD consumer paths:

```text
1. OpenSCAD   -> BOSL2 .scad
2. PythonSCAD -> BOSL2 .scad
3. PythonSCAD -> pybosl2
```

Use the same small geometry in all three where practical. The current comparison
shape is a rounded 30 × 20 × 10 cuboid.

The goal is to answer technical questions such as:

- does the installed BOSL2 resolve through `OPENSCADPATH`?
- can PythonSCAD consume BOSL2 SCAD modules through `osuse()`/`osinclude()`?
- can PythonSCAD import the installed pybosl2 package without a project-local
  install?
- can every route export both PNG and STL?

Do not turn this repository into a large subjective API benchmark. Small
technical comparison/probe tests belong here; a large design study can be split
out later if needed.

## BOSL2 SCAD path in PythonSCAD

PythonSCAD `osuse()` does not use `OPENSCADPATH` to resolve a string such as:

```text
BOSL2/shapes3d.scad
```

The toolchain publishes `BOSL2_ROOT` for this purpose.

The maintained test pattern is:

```python
import os
from pathlib import Path

bosl2_file = Path(os.environ["BOSL2_ROOT"]) / "std.scad"
bosl2 = osuse(str(bosl2_file))
```

The suite should fail clearly if `BOSL2_ROOT` is missing or the expected SCAD
file is absent. Do not replace this with a repository-local BOSL2 checkout.

## PythonSCAD external package discovery

The published toolchain installs shared external Python packages in:

```text
/opt/python-libs
```

PythonSCAD embeds CPython and currently does not reliably inherit the
container's `PYTHONPATH`.

Every PythonSCAD consumer test that imports a toolchain-installed pip package
must therefore do:

```python
import sys
sys.path.insert(0, "/opt/python-libs")
```

before importing that package.

Keep `python_path_probe.py` as diagnostic evidence for the embedded runtime.
Do not "fix" the test by installing pybosl2 inside the test repository.

## Python import-shadowing rule

Do not name the pybosl2 test itself `pybosl2.py`.

Python places the source-file directory on its import path, so that filename
would shadow the installed package and make `from pybosl2 import ...` import
the test file itself.

The maintained consumer-test filename is:

```text
test/pythonscad/pybosl2_consumer.py
```

## PythonSCAD/OpenSCAD object finding

A previous clamp-library experiment established that PythonSCAD currently does
not transfer OpenSCAD `object()` values across the language boundary. Do not
reinterpret a successful BOSL2 module test as proof that arbitrary object-based
OpenSCAD APIs are interoperable.

## Reports

Successful runs build `site/` and publish it to the `gh-pages` branch.

`main` publishes to:

```text
/latest/
```

released test tags publish to their permanent tag-named directory.

Reports should expose both the pass/fail summary and the generated render
evidence. Raw `out/` remains available as an Actions artifact for debugging.

## Failure discipline

Do not hide interoperability failures with test-only bridges unless the purpose
of the test explicitly is to validate such a bridge.

If one BOSL2 route fails, keep the failure visible and inspect the exact
toolchain/library boundary. These tests exist specifically to discover those
limitations.


## BOSL2 library entrypoint

Use `std.scad` as the BOSL2 entrypoint for PythonSCAD interoperability tests:

```python
import os
from pathlib import Path

bosl2_file = Path(os.environ["BOSL2_ROOT"]) / "std.scad"
bosl2 = osuse(str(bosl2_file))
```

Do not directly `osuse()` `shapes3d.scad`. BOSL2 component files rely on the
standard constants/dependencies loaded by `std.scad`.


## Current PythonSCAD interoperability conclusion

Two independent compatibility limitations have now been demonstrated.

### 1. OpenSCAD `object()` boundary

Modern OpenSCAD experimental `object()` values do not currently cross the
OpenSCAD/PythonSCAD boundary as usable Python-side objects. Do not flatten or
redesign public OpenSCAD object APIs merely to make them consumable by
PythonSCAD.

### 2. BOSL2 OpenSCAD-runtime boundary

`PythonSCAD -> BOSL2 .scad` through `osuse()` is a maintained XFAIL.

BOSL2 `std.scad` uses OpenSCAD's date-based `version_num()` compatibility check.
PythonSCAD's SCAD runtime exposes PythonSCAD's own semantic-version value, so
BOSL2 rejects the runtime.

This is important beyond the individual assertion: BOSL2 relies strongly on
OpenSCAD-specific runtime semantics, while PythonSCAD's interoperability layer
does not reproduce all of those semantics identically despite being built on
substantial OpenSCAD-derived infrastructure.

Maintain these routes as:

```text
OpenSCAD   -> BOSL2       : supported/native
PythonSCAD -> pybosl2     : supported comparison route
PythonSCAD -> BOSL2 SCAD  : XFAIL compatibility probe
```

Do not hide these findings with compatibility shims that fake OpenSCAD version
numbers or flatten object APIs.

The XFAIL is valid only when the expected message is observed:

```text
BOSL2 requires OpenSCAD version 2021.01 or later.
```

If that route unexpectedly succeeds, or fails for another reason, the suite
must fail and the compatibility conclusion must be reviewed.


### Active OpenSCAD object XFAIL

The OpenSCAD `object()` limitation is an active verification probe, not just a
documented historical finding.

Files:

```text
test/pythonscad/openscad_object/object_api.scad
test/pythonscad/openscad_object/object_bridge_probe.py
```

Expected marker:

```text
PYTHONSCAD_OPENSCAD_OBJECT_XFAIL
```

Do not add scalar bridge wrappers or fake object representations to make the
probe pass. Unexpected success means PythonSCAD interoperability has improved
and the test/report status must be updated.

The report order is intentionally:

```text
1. PASS/XFAIL summary
2. interoperability findings
3. supported geometry renders
4. smoke renders
5. environment / raw outputs
```


### PythonSCAD script-file path rule

For the object XFAIL probe, `run-tests.sh` provides the absolute SCAD library
path through:

```text
OPENSCAD_OBJECT_PROBE_SCAD
```

The PythonSCAD script must load that file directly with:

```python
library = osuse(os.environ["OPENSCAD_OBJECT_PROBE_SCAD"])
```

Do not obscure the interoperability test with separate path-management logic.
The environment variable supplies only the location; `osuse()` remains the
actual PythonSCAD/OpenSCAD-library boundary.


## Test execution order

Keep `scripts/run-tests.sh` ordered as:

```text
1. Toolchain / environment
2. Base functionality
3. Additional runtime tests
4. Library / interoperability
```

Within library/interoperability, keep the supported routes first and the
expected incompatibilities last:

```text
OpenSCAD -> BOSL2
PythonSCAD -> pybosl2
XFAIL PythonSCAD -> BOSL2 .scad
XFAIL PythonSCAD -> OpenSCAD object()
```

This mirrors the dependency chain and keeps GitHub Actions logs readable during
debugging.
