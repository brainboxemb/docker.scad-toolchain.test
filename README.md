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

```python
from pythonscad import *

bosl2 = osuse("BOSL2/shapes3d.scad")
part = bosl2.cuboid([30, 20, 10], rounding=3)
part.show()
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
