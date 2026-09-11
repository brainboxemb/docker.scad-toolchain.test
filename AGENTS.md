# Repository agent guidance

Persistent guidance for automated coding agents working in
`docker.scad-toolchain.test`.

## Purpose

This repository is the external consumer-validation suite for the published
`ghcr.io/brainboxemb/scad-toolchain` image.

It deliberately remains separate from `docker.scad-toolchain`:

```text
docker.scad-toolchain
    builds/publishes the runtime

docker.scad-toolchain.test
    consumes the published runtime
    verifies the public interface
    publishes evidence
```

## Sources of truth

Use:

```text
toolchain.env                       default development image target
release tag                         immutable suite/toolchain pairing
scripts/run-tests.sh                execution order and test behavior
scripts/build-report.sh             report structure
.github/workflows/*.yml             trigger/publication lifecycle
```

Do not duplicate changing toolchain versions in this file.

## Version model

The test-suite version and toolchain version are independent. Permanent release
tags encode both and must never be moved or overwritten.

Development normally tests the mutable `:edge` image. A released test tag must
resolve and test the immutable toolchain version encoded in its own name; it
must never silently follow `:edge`.

## Release discipline

A mutable `/latest/` report is not the permanent verification record for a
released toolchain.

Required order:

1. development suite passes against `:edge`;
2. toolchain publishes an immutable release image;
3. the producer-triggered run passes against that exact immutable image;
4. only then create the matching immutable test-suite tag;
5. the tag runs the complete suite again and publishes permanent tag-named
   evidence.

Use `.github/workflows/release.yml`. Do not create temporary one-shot release
workflows or overwrite released test tags.

## Public interface coverage

Validate public commands and behavior as consumers actually use them, including
representative PNG/STL generation, Git operations, docs tooling and PNG
watermark post-processing.

Do not test implementation-private scripts when a public command exists. For
example, watermark verification must invoke `scad-image-watermark` rather than
importing its implementation.

A command existing is not enough when a practical consumer test is possible.

## BOSL2 / pybosl2 coverage

Maintain the three distinct routes:

```text
OpenSCAD   -> BOSL2 SCAD      supported/native
PythonSCAD -> pybosl2         supported comparison route
PythonSCAD -> BOSL2 SCAD      compatibility probe / expected failure when documented
```

Use equivalent small geometry where practical so behavior is comparable.

For PythonSCAD `osuse()` use the explicit `BOSL2_ROOT/std.scad` path. Do not
assume `OPENSCADPATH` resolution and do not load `shapes3d.scad` directly as the
entrypoint.

PythonSCAD may require `/opt/python-libs` to be inserted explicitly into
`sys.path` for toolchain-installed Python packages.

Never name a test script `pybosl2.py`; that would shadow the installed package.

## Compatibility XFAIL discipline

Known compatibility limitations are active probes, not historical comments.

Examples include:

- PythonSCAD -> BOSL2 SCAD runtime semantics;
- PythonSCAD crossing an OpenSCAD `object()` boundary.

Do not add compatibility shims merely to make an expected-failure probe pass.
An XFAIL is valid only when the expected failure marker/message is observed.
Unexpected success or a different failure must fail the suite and trigger a
review of the compatibility conclusion.

## Documentation tooling test

The external docsgen test must validate the published toolchain package as a
consumer.

Structured `.scad` test source begins with `File:` or `LibFile:` before API
blocks. Maintain both parse/test validation and real Markdown generation. The
generated Markdown must be non-empty and contain a known documented symbol.

Keep generated evidence under output directories; do not mutate test source
folders.

## Test execution order

Keep `scripts/run-tests.sh` grouped as:

```text
1. Toolchain / environment
2. Base functionality
3. Additional runtime tests
4. Documentation tooling
5. Library / interoperability
```

Within interoperability, run supported routes before expected incompatibilities.
Keep `scripts/build-report.sh` structurally aligned with this order so Actions
logs and published evidence tell the same story.

## Reports

Successful runs publish generated evidence to Pages:

- mutable current/development evidence under `/latest/`;
- immutable released evidence under the release tag name.

The report should show PASS/XFAIL summary first, then detailed evidence, then raw
outputs/environment diagnostics. Raw generated files should also remain
available as Actions artifacts for debugging.

## Failure discipline

Do not hide an interoperability failure with test-only bridges unless the test
explicitly exists to validate such a bridge. This repository is intended to
surface real runtime boundaries clearly.
