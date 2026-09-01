# docker.scad-toolchain.test

> **Test results**
>
> - Latest successful test: https://brainboxemb.github.io/docker.scad-toolchain.test/latest/
> - Versioned results: `https://brainboxemb.github.io/docker.scad-toolchain.test/<test-suite-tag>/`
> - Example: https://brainboxemb.github.io/docker.scad-toolchain.test/v0.1.1/

Versioned external validation suite for `ghcr.io/brainboxemb/scad-toolchain`.

This repository tests a **published** SCAD toolchain image from a separate
consumer repository. It therefore verifies what a real CAD repository will
actually see: public commands, rendering behavior and export behavior.

## Why this repository exists

The responsibilities are deliberately separated:

```text
docker.scad-toolchain
        |
        | publishes
        v
ghcr.io/brainboxemb/scad-toolchain:vX.Y.Z
        |
        | consumed by
        v
docker.scad-toolchain.test
        |
        | validates and publishes reports
        v
GitHub Pages
```

The toolchain repository proves that the image can be built.

This repository proves that the **published image can actually be consumed**.

## Version model

The test suite and toolchain have independent version histories.

Every released test-suite tag records which toolchain version it targets in
`toolchain.env`.

For example:

| Test suite | Target toolchain |
|---|---|
| `v0.1.0` | `v0.1.0` |
| `v0.1.1` | `v0.1.1` |
| `v0.1.2` | `v0.1.1` |
| `v0.2.0` | `v0.2.0` |

A newer test suite is **not required** to work with older toolchain images.

That is intentional.

For example, test-suite `v0.2.0` may test new PythonSCAD behavior that does not
exist in toolchain `v0.1.1`.

## Current target

The current repository configuration is stored in:

```text
toolchain.env
```

and currently targets:

```text
SCAD_TOOLCHAIN_IMAGE=ghcr.io/brainboxemb/scad-toolchain
SCAD_TOOLCHAIN_VERSION=v0.1.1
```

## Permanent results per test-suite tag

When a tag is pushed, for example:

```text
v0.1.1
```

the workflow:

1. pulls the configured SCAD toolchain image;
2. runs the complete test suite;
3. generates an HTML report;
4. publishes that report under a version-specific directory on GitHub Pages.

The resulting URL is:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/v0.1.1/
```

That directory is kept when later versions are published.

So after several releases the Pages site can contain:

```text
/
├── latest/
├── v0.1.1/
├── v0.1.2/
└── v0.2.0/
```

This makes old test evidence directly browsable without downloading an Actions
artifact.

## `latest`

A successful workflow on `main` publishes to:

```text
/latest/
```

This is useful while developing the next test-suite release.

It is **not** an immutable historical reference.

For historical evidence always use the URL belonging to a Git tag, for example:

```text
/v0.1.1/
```

## What the report contains

The generated report records:

- test-suite version;
- exact toolchain image and version;
- OpenSCAD version;
- PythonSCAD version;
- Python version;
- PASS results for the smoke tests;
- rendered OpenSCAD PNG;
- direct links to generated PNG/STL output.

Raw output is still uploaded as an Actions artifact for debugging, but GitHub
Pages is the normal way to inspect successful results.

## Tests

### Runtime interface

The suite checks that these public commands are usable:

```text
openscad
pythonscad
python3
scad-toolchain-info
```

### OpenSCAD

The suite performs:

```text
SCAD -> PNG
SCAD -> STL
```

and verifies that both files are produced.

### PythonSCAD

PythonSCAD is tested through its own executable and embedded Python runtime:

```bash
pythonscad -o output.stl --trust-python model.py
```

The suite deliberately does not require:

```bash
python3 -c 'import pythonscad'
```

because the PythonSCAD module belongs to the Python environment embedded in
PythonSCAD, not necessarily the operating-system Python installation.

## Repository layout

```text
docker.scad-toolchain.test/
├── README.md
├── toolchain.env
├── scripts/
│   ├── run-tests.sh
│   └── build-report.sh
├── test/
│   ├── openscad/
│   │   └── smoke.scad
│   └── pythonscad/
│       └── smoke.py
└── .github/
    └── workflows/
        └── test.yml
```

Generated directories:

```text
out/     raw test output
site/    generated HTML report
```

Neither needs to be committed to the normal source branch.

## First-time GitHub Pages setup

The workflow publishes the generated site to the `gh-pages` branch using
`peaceiris/actions-gh-pages`.

After the first successful publish:

1. open the repository on GitHub;
2. go to **Settings -> Pages**;
3. under **Build and deployment**, select **Deploy from a branch**;
4. select branch **gh-pages**;
5. select directory **/(root)**;
6. save.

The site will then be available at:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/
```

The versioned report directories live underneath this URL.

## Creating test-suite v0.1.1

First verify that `main` is green against:

```text
ghcr.io/brainboxemb/scad-toolchain:v0.1.1
```

Then create the immutable test-suite tag:

```bash
git tag -a v0.1.1 -m "SCAD toolchain test suite v0.1.1"
git push origin v0.1.1
```

That tag triggers the tests again and, if successful, publishes:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/v0.1.1/
```

## Improving tests without changing the toolchain

Suppose toolchain `v0.1.1` remains unchanged but you add an additional
verification.

Keep:

```text
SCAD_TOOLCHAIN_VERSION=v0.1.1
```

and release the test suite as, for example:

```text
v0.1.2
```

You then have two immutable validations of the same toolchain:

```text
test suite v0.1.1 -> toolchain v0.1.1
test suite v0.1.2 -> toolchain v0.1.1
```

with separate reports:

```text
/v0.1.1/
/v0.1.2/
```

## Testing the next toolchain before releasing the suite

The workflow supports manual dispatch.

Open:

```text
Actions -> Test published SCAD toolchain -> Run workflow
```

and enter a temporary toolchain version, for example:

```text
v0.2.0
```

This lets you evaluate the next image before updating `toolchain.env`.

A manual override is development/testing only. It does not change the immutable
relationship stored in a released Git tag.

## Moving to a new toolchain line

When `docker.scad-toolchain` publishes `v0.2.0`:

1. test `v0.2.0` through manual workflow dispatch;
2. adapt the tests if required;
3. change `toolchain.env` to `v0.2.0`;
4. commit and push;
5. verify `/latest/`;
6. create the new test-suite tag;
7. verify the corresponding versioned Pages URL.

For example:

```text
test suite v0.2.0
toolchain  v0.2.0
report     /v0.2.0/
```

The `v0.2.x` suite does not need to support toolchain `v0.1.x`.

## Historical traceability

A consuming CAD repository can eventually document:

```text
SCAD toolchain : v0.1.1
validated by   : docker.scad-toolchain.test v0.1.1
results        : https://brainboxemb.github.io/docker.scad-toolchain.test/v0.1.1/
```

That provides three immutable references:

1. the GHCR toolchain image version;
2. the Git tag defining the test suite;
3. the published test evidence.

## Deleting a test-suite version

Normally, released tags and their Pages results should remain available.

If a tag was created by mistake:

```bash
git tag -d v0.1.1
git push origin :refs/tags/v0.1.1
```

Deleting the Git tag does **not** automatically remove its directory from the
`gh-pages` branch.

Likewise, deleting a test-suite tag does not delete any SCAD toolchain package
from GHCR. The test suite and container package are intentionally independent.

If a versioned Pages directory was published incorrectly, remove that directory
from the `gh-pages` branch separately.

## Release rules

- Never move an existing released Git tag.
- Never overwrite an existing historical Pages report intentionally.
- Every released test suite must point to an explicit toolchain version.
- Do not use `latest` or `edge` as the target for a released test-suite tag.
- Newer test suites are free to drop compatibility with older toolchains.
- Use `/latest/` only for current development.
- Use `/vX.Y.Z/` for historical verification.
