# docker.scad-toolchain.test

> **Test results:** https://brainboxemb.github.io/docker.scad-toolchain.test/

Versioned external validation suite for `ghcr.io/brainboxemb/scad-toolchain`.

This repository tests a **published** SCAD toolchain image from a separate
consumer repository. It therefore verifies what a real CAD repository will
actually see: public commands, rendering behavior and export behavior.




## Release tag convention

Released test-suite tags encode **both** the test-suite version and the exact
toolchain version being validated.

Use this format:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

Examples:

```text
test-v0.1.1-toolchain-v0.1.2
test-v0.1.1-toolchain-v0.1.1
test-v0.2.0-toolchain-v0.2.0
```

This makes the validation relationship visible directly in Git history,
GitHub Actions and the versioned Pages URL.

The test-suite version and toolchain version are independent:

The test-suite SemVer starts independently at `v0.1.0`. It does not inherit the current toolchain version.

```text
test-v0.1.1-toolchain-v0.1.2
     ^^^^^^              ^^^^^^
     test suite          target toolchain
```

A newer test-suite release may continue to validate the same toolchain, and a
newer test suite does not need to remain compatible with older toolchains.

### Pages URL

The tag name is also used as the permanent Pages directory.

For example:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/test-v0.1.1-toolchain-v0.1.2/
```

`/latest/` remains the development view from `main`.


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
SCAD_TOOLCHAIN_VERSION=v0.1.2
```

## Test results dashboard

The single public entry point for test results is:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/
```

The root page is generated automatically after every successful publish.

It contains:

- a link to `/latest/` for the latest successful run from `main`;
- all released test-suite reports;
- the test-suite version;
- the toolchain version encoded in each release tag.

Example generated entries:

```text
test-v0.1.1-toolchain-v0.1.2
test-v0.1.1-toolchain-v0.1.1
test-v0.2.0-toolchain-v0.2.0
```

You normally do not need to remember or copy a version-specific Pages URL:
open the dashboard and select the required historical test result.

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
https://brainboxemb.github.io/docker.scad-toolchain.test/test-v0.1.1-toolchain-v0.1.2/
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
- rendered PythonSCAD PNG;
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

The suite performs:

```text
PY -> PNG
PY -> STL
```

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

## Git validation

Git is part of the public CI interface of the SCAD toolchain because consuming
CAD repositories may inspect and commit generated design or verification files.

The test suite therefore checks both availability and basic functionality:

```text
git --version
git init
git config user.name / user.email
git add
git commit
git rev-parse HEAD
```

The test identity is configured **locally inside the temporary smoke-test
repository**:

```text
user.name  = SCAD Toolchain Test
user.email = scad-toolchain-test@example.invalid
```

This is intentional. The test does not depend on global Git configuration or
GitHub environment variables, and it leaves no persistent identity settings in
the container.

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
git tag -a test-v0.1.1-toolchain-v0.1.2 -m "Test suite v0.1.2 against SCAD toolchain v0.1.1"
git push origin test-v0.1.1-toolchain-v0.1.2
```

That tag triggers the tests again and, if successful, publishes:

```text
https://brainboxemb.github.io/docker.scad-toolchain.test/test-v0.1.1-toolchain-v0.1.2/
```

## Improving tests without changing the toolchain

Suppose toolchain `v0.1.1` remains unchanged but you add an additional
verification.

Keep:

```text
SCAD_TOOLCHAIN_VERSION=v0.1.2
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


## Current release instruction

The current suite targets:

```text
SCAD toolchain : v0.1.1
```

This is the first released test-suite version, so release it as:

```text
test-v0.1.1-toolchain-v0.1.2
```

Commands:

```bash
git add .
git commit -m "Add versioned Pages reports and PythonSCAD PNG test"
git push

git tag -a test-v0.1.1-toolchain-v0.1.2 \
  -m "Test suite v0.1.2 against SCAD toolchain v0.1.1"

git push origin test-v0.1.1-toolchain-v0.1.2
```

After the tagged workflow passes, open the test results dashboard and verify that the new release appears there.

Do not move or overwrite this tag later. A future test-only change becomes,
for example:

```text
test-v0.1.1-toolchain-v0.1.1
```

A future toolchain upgrade might become:

```text
test-v0.2.0-toolchain-v0.2.0
```


## Current test-suite release

The current test-suite change adds Git validation and targets SCAD toolchain
`v0.1.2`.

Because the previously released test-suite line started at `v0.1.0`, this
change should be tagged as:

```text
test-v0.1.1-toolchain-v0.1.2
```

## Historical traceability

A consuming CAD repository can eventually document:

```text
SCAD toolchain : v0.1.1
validated by   : docker.scad-toolchain.test v0.1.1
results        : https://brainboxemb.github.io/docker.scad-toolchain.test/
```

That provides three immutable references:

1. the GHCR toolchain image version;
2. the Git tag defining the test suite;
3. the published test evidence.

## Deleting a test-suite version

Normally, released tags and their Pages results should remain available.

If a tag was created by mistake:

```bash
git tag -d test-v0.1.1-toolchain-v0.1.2
git push origin :refs/tags/test-v0.1.1-toolchain-v0.1.2
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

## PythonSCAD command-line define test

The suite contains an isolated test for PythonSCAD `-D name=value` behavior.

It checks whether a command such as:

```bash
-D 'design_view="01-ring"'
```

makes `design_view` available in the Python script before the script assigns a
default. The probe also calls `add_parameter()` under a different name so both
mechanisms can be observed independently.

The test runs three explicit values and one case without `-D`.
