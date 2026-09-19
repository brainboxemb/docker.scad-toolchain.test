# docker.scad-toolchain.test

> **Test results:** https://brainboxemb.github.io/docker.scad-toolchain.test/

External consumer-validation suite for the published SCAD runtime image family:

```text
ghcr.io/brainboxemb/scad-toolchain-openscad
ghcr.io/brainboxemb/scad-toolchain
```

This repository tests published images rather than repeating their internal
Docker build checks.

## Runtime matrix

The suite treats the full image as a superset of the OpenSCAD-focused image.

Shared contract, tested against both profiles:

- `openscad`;
- Python 3;
- Git;
- SCons;
- `scad-toolchain-info` and profile identity;
- OpenSCAD PNG/STL generation;
- OpenSCAD -> BOSL2;
- OpenSCAD -> `openscad-new-dimensions` -> SVG;
- `openscad-docsgen` / `openscad-mdimggen`;
- `scad-image-watermark` / Pillow;
- generic published-runtime filesystem/environment expectations.

Additional full-runtime contract:

- `pythonscad` PNG/STL;
- PythonSCAD `-D` define injection;
- embedded Python path probe;
- PythonSCAD -> pybosl2;
- documented interoperability XFAIL probes.

A missing PythonSCAD command in the OpenSCAD profile is expected, not a test
failure.

## Current development target

The released external-suite contract remains **v0.5.1**. It now also qualifies
the immutable toolchain v0.5.2 runtime family:

```text
SCAD_TOOLCHAIN_OPENSCAD_IMAGE=ghcr.io/brainboxemb/scad-toolchain-openscad
SCAD_TOOLCHAIN_FULL_IMAGE=ghcr.io/brainboxemb/scad-toolchain
SCAD_TOOLCHAIN_VERSION=v0.5.2
```

Toolchain v0.5.2 adds producer-owned open-source acknowledgment/release
artifacts. That does not change the functional consumer contract of this suite,
so the suite itself does **not** advance to v0.5.2.

The permanent functional qualification record is:

```text
test-v0.5.1-toolchain-v0.5.2
```

The earlier `test-v0.5.1-toolchain-v0.5.1` record remains immutable historical
evidence for toolchain v0.5.1.

## Release gate at a glance

When a toolchain release changes only producer/release behavior and leaves the
functional consumer contract unchanged, reuse the latest released suite version:

```text
toolchain candidate / :edge
    ↓
released suite v0.5.1 against :edge green
    ↓
toolchain v0.5.2 immutable images
    ↓
released suite v0.5.1 against exact v0.5.2 green
    ↓
test-v0.5.1-toolchain-v0.5.2 green
    = permanent functional qualification record
```

Only a substantive external consumer-test change advances the suite version.

## Version resolution

Immutable test releases use:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

The current record is:

```text
test-v0.5.1-toolchain-v0.5.2
```

The workflow resolves runtime versions as follows:

```text
main / pull request
    -> version from toolchain.env

workflow_dispatch
    -> optional explicit override
    -> for example edge, sha-eeb40e7 or v0.5.2

tag test-v0.5.1-toolchain-v0.5.2
    -> automatically v0.5.2
```

Both runtime package names receive the same resolved version.

## Distribution measurements

Routine qualification runs on one hosted Ubuntu runner:

1. pull and test the OpenSCAD profile;
2. keep those Docker layers locally available;
3. pull and test the full superset;
4. report exact linux/amd64 compressed OCI bytes and Docker unpacked image size.

This reflects efficient normal use and shows how much additional data the full
profile needs once shared layers are present.

Migration 005 also performed one controlled cold-vs-cold benchmark by clearing
Docker state between pulls. That benchmark is historical architecture evidence;
destructive pruning is deliberately **not** part of routine CI because it
throws away shared data and unrelated hosted-runner images.

Qualified candidate measurements:

| Profile | Compressed OCI bytes | Unpacked bytes | Controlled cold pull |
| --- | ---: | ---: | ---: |
| OpenSCAD-focused | 328,098,501 | 961,779,232 | 13.211 s |
| full/dual | 449,516,893 | 1,313,898,129 | 15.464 s |

The focused runtime removes 121,418,392 compressed bytes, about 27.0% of the
full image, for consumers that do not need PythonSCAD.

## PNG watermark tooling

Both profiles must expose:

```text
scad-image-watermark
```

The external suite produces a real OpenSCAD PNG, applies a copyright label and
checks that the resulting PNG is valid, keeps the original dimensions and is
not byte-identical to its input.

## OpenSCAD documentation tooling

Both profiles must expose:

```text
openscad-docsgen
openscad-mdimggen
```

The suite runs a real docsgen parse and Markdown generation against a consumer
`.scad` source. The generated Markdown must be non-empty and contain the
expected module documentation.

## OpenSCAD dimension drawing capability

Both profiles expose the Codeberg-hosted
`adrien-delhorme/openscad-new-dimensions` library through the normal
`OPENSCADPATH` and publish:

```text
OPENSCAD_NEW_DIMENSIONS_ROOT
OPENSCAD_NEW_DIMENSIONS_COMMIT
```

The external suite does not stop at checking that the directory exists. A
suite-owned consumer source resolves the installed library and executes the
pinned upstream demo, then OpenSCAD must export a non-empty SVG. The generated
SVG is retained in the raw output and shown in the HTML report for both
profiles.

This keeps the runtime qualification generic. Project-specific dimension
layout, view selection and drawing readability remain the responsibility of
the consuming SCAD project.

## BOSL2 capability comparison

The suite deliberately keeps these routes separate:

```text
OpenSCAD   -> BOSL2          PASS expected, both profiles
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
4. Full-runtime PythonSCAD functionality, when profile=full
5. Full-runtime interoperability PASS/XFAIL probes
```

This keeps failures interpretable: establish the shared runtime contract before
advanced dual-runtime behaviour.

## Reports and artifacts

Each profile writes separate raw output below `out/`. The final report combines
both profiles and keeps profile identity visible.

The report includes:

- PASS/XFAIL table;
- profile-specific sections;
- representative generated renders;
- exact runtime image names/versions;
- raw image-distribution metrics.

Successful non-PR runs update GitHub Pages:

```text
/latest/
```

A released test tag gets a permanent tag-named directory and the root index
keeps historical reports.

## Release sequence

For a toolchain-only release such as v0.5.2, where the external functional
contract is unchanged:

1. qualify the candidate `:edge` images with the latest released suite;
2. publish immutable toolchain `v0.5.2`;
3. require the producer-triggered suite run against exact `v0.5.2` to pass;
4. create the permanent qualification tag using the unchanged released suite
   source:
   - suite version `v0.5.1`;
   - toolchain version `v0.5.2`;
   - exact released-suite source SHA;
5. require `test-v0.5.1-toolchain-v0.5.2` to pass and publish permanent Pages
   evidence.

Advance the test-suite version only when the external consumer contract itself
changes.

A failed interoperability test is useful evidence. Do not mask it merely to
make a release green.
