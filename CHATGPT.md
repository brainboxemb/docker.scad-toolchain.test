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

The first BOSL2-capable line is intended to target:

```text
SCAD_TOOLCHAIN_VERSION=v0.2.0
```

and can be released as:

```text
test-v0.2.0-toolchain-v0.2.0
```

after the published image passes.

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
