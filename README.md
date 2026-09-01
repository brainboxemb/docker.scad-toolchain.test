# docker.scad-toolchain.test

Versioned external test harness for `ghcr.io/brainboxemb/scad-toolchain`.

This repository validates a **published** SCAD toolchain image from the point of
view of a real consumer repository. It is intentionally separate from
`docker.scad-toolchain` so that tests do not accidentally pass only because
they run inside the image build repository.

## Versioning model

The test suite and the toolchain are versioned independently.

A test-suite release records the exact toolchain image it targets.

Example:

| Test suite | Target toolchain |
|---|---|
| `v0.1.0` | `ghcr.io/brainboxemb/scad-toolchain:v0.1.0` |
| `v0.1.1` | `ghcr.io/brainboxemb/scad-toolchain:v0.1.0` |
| `v0.2.0` | `ghcr.io/brainboxemb/scad-toolchain:v0.2.0` |

There is **no requirement** that test suite `v0.2.x` remains compatible with
toolchain `v0.1.x`.

The important relation is:

```text
test-suite release
        |
        +-- TARGET_TOOLCHAIN_VERSION
                |
                +-- published GHCR image
```

This makes historical validation reproducible.

## Current release line

This repository is prepared for:

```text
test suite       : v0.1.0
target toolchain : v0.1.0
image            : ghcr.io/brainboxemb/scad-toolchain:v0.1.0
```

The target is stored in:

```text
toolchain.env
```

Do not silently change the target of an already released test-suite tag.

## What is tested

The first suite performs consumer-style smoke tests.

### Runtime

- `scad-toolchain-info`
- `openscad --version`
- Python availability
- PythonSCAD import / version probe

### OpenSCAD

- render SCAD to PNG
- export SCAD to STL
- verify output files exist and are non-empty

### PythonSCAD

- execute a PythonSCAD model
- export the model
- verify output exists and is non-empty

The PythonSCAD command may evolve with the toolchain. That is exactly why this
test repository has its own version history.

## Repository layout

```text
docker.scad-toolchain.test/
├── README.md
├── toolchain.env
├── scripts/
│   └── run-tests.sh
├── test/
│   ├── openscad/
│   │   └── smoke.scad
│   └── pythonscad/
│       └── smoke.py
└── .github/
    └── workflows/
        └── test.yml
```

Generated test output is written to `out/` and is not committed.

## Running locally

You need Docker and access to the target GHCR image.

Load the configured version:

```bash
source toolchain.env
```

Pull the exact image:

```bash
docker pull "${SCAD_TOOLCHAIN_IMAGE}:${SCAD_TOOLCHAIN_VERSION}"
```

Run the suite:

```bash
docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  "${SCAD_TOOLCHAIN_IMAGE}:${SCAD_TOOLCHAIN_VERSION}" \
  bash ./scripts/run-tests.sh
```

## GitHub Actions

The workflow reads `toolchain.env`, logs in to GHCR and runs the tests inside
the configured published image.

The workflow runs on:

- pushes to `main`
- pull requests
- version tags `v*`
- manual dispatch

A manual run may optionally override the toolchain version. This is useful
while evaluating a new toolchain **before** changing `toolchain.env`.

A manual override does not change the release contract stored in Git.

## Preparing test-suite v0.1.0

First make sure the published image exists:

```text
ghcr.io/brainboxemb/scad-toolchain:v0.1.0
```

Commit the test repository and push `main`.

Check that the GitHub Actions workflow passes.

Then create the test-suite tag:

```bash
git tag -a v0.1.0 -m "SCAD toolchain test suite v0.1.0"
git push origin v0.1.0
```

A GitHub Release page is optional. The Git tag is the important immutable
reference.

## Updating tests without changing the toolchain

Suppose the toolchain remains `v0.1.0`, but the tests improve.

Keep:

```text
SCAD_TOOLCHAIN_VERSION=v0.1.0
```

and release, for example:

```text
test suite v0.1.1
```

This gives:

```text
toolchain v0.1.0
tested by:
  - test suite v0.1.0
  - test suite v0.1.1
```

## Testing a new toolchain

Suppose `docker.scad-toolchain` publishes:

```text
ghcr.io/brainboxemb/scad-toolchain:v0.2.0
```

Before changing the repository, use **Run workflow** and enter:

```text
v0.2.0
```

If necessary, adapt the test suite on a branch.

When the new test contract is ready:

1. Change `toolchain.env` to `v0.2.0`.
2. Update tests as needed.
3. Merge and verify the workflow.
4. Tag the test repository as `v0.2.0` (or another chosen test-suite version).

The new suite is allowed to rely on behavior only available in toolchain
`v0.2.0`.

## Historical traceability

A CAD project can record:

```text
SCAD toolchain : v0.1.0
validated by   : docker.scad-toolchain.test v0.1.1
```

That is stronger than merely saying that a CI run was green at some point:
both the runtime and the test definition are immutable Git/package versions.

## Removing a test-suite version

Deleting a test-suite version means deleting the Git tag (and optionally the
GitHub Release page).

Local tag:

```bash
git tag -d v0.1.0
```

Remote tag:

```bash
git push origin :refs/tags/v0.1.0
```

Do this only when the tag was created by mistake. Published historical test
tags should normally remain immutable.

Deleting a test-suite Git tag does **not** delete the corresponding
`scad-toolchain` package version from GHCR. They are independent repositories
and version stores.

## Release policy

- Never move or overwrite an existing released Git tag.
- Never change what an existing `toolchain.env` meant in a released tag.
- Test-suite versions may evolve independently from toolchain versions.
- A newer suite does not need to support older toolchains.
- Prefer explicit versions over `latest` or `edge` for release validation.
