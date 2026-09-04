# docker.scad-toolchain.test

> **Test results:** https://brainboxemb.github.io/docker.scad-toolchain.test/

External consumer-validation suite for
`ghcr.io/brainboxemb/scad-toolchain`.

This repository intentionally tests a **published** toolchain image rather than
repeating the image's internal build checks.

## Current development target

`main` tests the latest published development image:

```text
SCAD_TOOLCHAIN_IMAGE=ghcr.io/brainboxemb/scad-toolchain
SCAD_TOOLCHAIN_VERSION=edge
```

This is intentional: `v0.2.0` does not exist until the toolchain release is
actually published.

A released test-suite tag does **not** use `edge`. Its exact immutable
toolchain version is derived from the tag name.

## Release tags

Test-suite and toolchain versions are independent. Immutable test releases use:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

For this capability update the intended tag is:

```text
test-v0.2.0-toolchain-v0.2.0
```

after toolchain v0.2.0 has actually been published and the suite is green.

### Development versus release resolution

The workflow resolves the image version as follows:

```text
main / pull request
    -> version from toolchain.env
    -> normally :edge

workflow_dispatch
    -> optional explicit override
    -> for example :edge or :v0.2.0

tag test-v0.2.0-toolchain-v0.2.0
    -> automatically :v0.2.0
```

This avoids editing `toolchain.env` back and forth during the release process
while still guaranteeing that released test reports use an immutable toolchain
tag.

## Base tests

The suite verifies:

- `openscad`
- `pythonscad`
- `python3`
- `git`
- `scad-toolchain-info`
- OpenSCAD PNG/STL
- PythonSCAD PNG/STL
- PythonSCAD `-D` define injection
- functional Git init/add/commit

## BOSL2 capability comparison

The v0.2 suite deliberately compares three routes:

```text
OpenSCAD   -> BOSL2
PythonSCAD -> BOSL2 .scad
PythonSCAD -> pybosl2
```

The comparison sources use equivalent geometry:

```text
30 × 20 × 10 rounded cuboid
rounding = 3
```

This makes the generated renders useful evidence without turning the repository
into a broad design benchmark.

### Native OpenSCAD + BOSL2

```scad
include <BOSL2/std.scad>

cuboid([30, 20, 10], rounding=3);
```

### PythonSCAD consuming BOSL2 SCAD

PythonSCAD `osuse()` needs a real filesystem path; it does not resolve
`BOSL2/shapes3d.scad` through `OPENSCADPATH`.

The toolchain therefore exposes `BOSL2_ROOT`:

```python
import os
from pathlib import Path

from pythonscad import *

bosl2_file = Path(os.environ["BOSL2_ROOT"]) / "std.scad"
bosl2 = osuse(str(bosl2_file))

part = bosl2.cuboid([30, 20, 10], rounding=3)
part.show()
```

### BOSL2 filesystem path

The external test suite requires the published image to expose:

```text
BOSL2_ROOT=/opt/openscad-libraries/BOSL2
```

The exact current value is shown in the logs, but consumers should use the
environment variable rather than hardcoding the installation directory.

This is deliberately tested separately from `OPENSCADPATH` because the two
serve different consumers:

```text
OpenSCAD include/use
    -> OPENSCADPATH

PythonSCAD osuse()/osinclude()
    -> explicit path rooted at BOSL2_ROOT
```

### PythonSCAD + pybosl2

PythonSCAD embeds CPython and does not reliably inherit the container's
`PYTHONPATH`. The toolchain-installed package directory is therefore added
explicitly:

```python
import sys
sys.path.insert(0, "/opt/python-libs")

from pythonscad import *
from pybosl2 import cuboid

part = cuboid([30, 20, 10], rounding=3)
part.show()
```

Each route must create both PNG and STL output.

The test does **not** assume full feature parity between BOSL2 and pybosl2.
They are independently versioned implementations.

### Embedded Python package path

The suite also runs a small `python_path_probe.py` under PythonSCAD. This is
useful evidence when debugging external Python package discovery.

The expected toolchain pattern for pip-installed shared packages is:

```python
import sys
sys.path.insert(0, "/opt/python-libs")
```

The suite intentionally does not treat container `PYTHONPATH` as sufficient for
the embedded PythonSCAD runtime.

### Python module naming

The pybosl2 consumer test is deliberately named:

```text
pybosl2_consumer.py
```

and **not** `pybosl2.py`. A local file called `pybosl2.py` shadows the installed
package on Python's import path and produces a circular/partially initialized
module error.

## Repository layout

```text
docker.scad-toolchain.test/
├── README.md
├── CHATGPT.md
├── toolchain.env
├── scripts/
│   ├── run-tests.sh
│   ├── test-pythonscad-defines.sh
│   ├── build-report.sh
│   └── build-index.sh
├── test/
│   ├── openscad/
│   │   ├── smoke.scad
│   │   └── bosl2.scad
│   └── pythonscad/
│       ├── smoke.py
│       ├── define-probe.py
│       ├── bosl2_scad.py
│       ├── pybosl2_consumer.py
│       └── python_path_probe.py
└── .github/
    └── workflows/
        └── test.yml
```

Generated directories:

```text
out/
site/
```

are not committed to the normal source branch.

## Pages

A successful `main` run updates:

```text
/latest/
```

A released test tag gets its own permanent directory. The root Pages index is
rebuilt after each successful publish and keeps historical reports.

## Development order

For a new toolchain capability:

1. add it to `docker.scad-toolchain`;
2. let toolchain `main` publish/update `:edge`;
3. let this repository's `main` test `:edge`;
4. fix problems until the external consumer suite is green;
5. publish the immutable toolchain tag, for example `v0.2.0`;
6. optionally run this test workflow manually against `v0.2.0`;
7. create the immutable test-suite tag, for example
   `test-v0.2.0-toolchain-v0.2.0`.

The release tag itself selects `:v0.2.0`; `toolchain.env` can remain on
`:edge` for normal development.

A failed interoperability test is useful evidence. Do not mask it merely to make
the suite green.


## BOSL2 library entrypoint

BOSL2 should be loaded through `std.scad`, including from PythonSCAD.

```text
OpenSCAD
    include <BOSL2/std.scad>

PythonSCAD
    osuse(BOSL2_ROOT / "std.scad")
```

Do not load `shapes3d.scad` directly just because the test uses `cuboid()`.
`shapes3d.scad` expects the standard constants and dependencies established by
`std.scad`; direct loading causes missing-symbol warnings such as `CENTER`,
`UP`, and `EDGES_ALL`.


## PythonSCAD interoperability findings

The suite deliberately records both supported routes and known compatibility
limits.

| Capability | Status | Finding |
| --- | --- | --- |
| OpenSCAD -> BOSL2 | PASS expected | Native BOSL2/OpenSCAD path |
| PythonSCAD -> pybosl2 | PASS expected | Python-native BOSL2 path |
| PythonSCAD -> BOSL2 `.scad` via `osuse()` | **XFAIL** | BOSL2 uses OpenSCAD's date-based `version_num()` compatibility gate; PythonSCAD exposes its own semantic-version runtime value |
| PythonSCAD -> OpenSCAD experimental `object()` | **XFAIL** | Object-based OpenSCAD APIs do not currently cross into PythonSCAD as usable Python-side objects |

These are two independent signs of the same broader architectural limitation:
PythonSCAD can consume conventional OpenSCAD modules/functions in useful cases,
but compatibility is incomplete for modern OpenSCAD library architectures and
libraries that rely strongly on OpenSCAD-specific runtime behavior.

The BOSL2 XFAIL also shows that PythonSCAD is not simply "OpenSCAD with Python
around it". Although PythonSCAD contains substantial OpenSCAD-derived
infrastructure, its interoperability/runtime layer can expose different
semantics to imported `.scad` code.

For this project the current direction is therefore:

```text
Reusable CAD libraries
    -> OpenSCAD is the primary implementation target

BOSL2
    -> OpenSCAD uses native BOSL2
    -> PythonSCAD uses pybosl2 for comparison/experimentation

PythonSCAD
    -> remains useful as an alternative/experimental CAD environment
    -> is not currently the foundation for our object-based reusable SCAD APIs
```

The direct `PythonSCAD -> BOSL2 .scad` test is intentionally retained as an
XFAIL compatibility probe. The suite only accepts the documented BOSL2 version
check failure. Unexpected success or any different failure causes the test to
fail so that this conclusion must be reviewed instead of silently becoming
outdated.


### OpenSCAD object compatibility probe

The earlier object interoperability finding is now an active XFAIL probe:

```text
test/pythonscad/openscad_object/
├── object_api.scad
└── object_bridge_probe.py
```

The OpenSCAD side deliberately exposes an experimental `object()` API without
scalar bridge wrappers. PythonSCAD must consume that real object value.

Current behavior is XFAIL. If a future PythonSCAD release successfully
round-trips the object, the probe unexpectedly succeeds and the suite fails so
the compatibility status can be reviewed.

The generated verification page puts PASS/XFAIL status first, followed by the
two interoperability findings, and only then shows renders for supported
routes.
