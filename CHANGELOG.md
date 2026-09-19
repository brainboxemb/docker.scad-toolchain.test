# Changelog

This file records the functional history of released
`docker.scad-toolchain.test` suite versions and their immutable qualification
records.

The test-suite version and the toolchain version are independent. A permanent
qualification tag therefore encodes both:

```text
test-v<test-suite-version>-toolchain-v<toolchain-version>
```

Mutable development targets such as `:edge` belong in `toolchain.env` and are
not release-history entries here.

## Version overview

| Test-suite version | Main change |
| --- | --- |
| `v0.6.1` | Report drawing dependencies/image size and qualify drawsvg composition |
| `v0.6.0` | Three-profile qualification with code-driven Inkscape drawing publication |
| `v0.5.1` | Functional external consumer coverage for `openscad-new-dimensions` SVG drawings |
| `v0.5.0` | Profile-aware external validation for the OpenSCAD-focused and full runtime image family |

## v0.6.1

### Changed

- Add the drawing runtime's Inkscape and drawsvg versions, plus the full
  runtime's Shapely version, to the existing runtime-version list.
- Replace the raw ElementTree drawing fixture with readable drawsvg authoring;
  the suite-owned Python script also invokes Inkscape for PNG/PDF export.
- Add compressed Docker image size per profile to the existing profile summary.
- Retain each profile's `scad-toolchain-info` output as source evidence for
  profile-specific version reporting.

### Qualification target

```text
test-v0.6.1-toolchain-v0.6.1
```

## v0.6.0

### Added

- External qualification for the dedicated
  `ghcr.io/brainboxemb/scad-toolchain-drawing` runtime profile.
- A real code-driven technical-drawing consumer path:
  `OpenSCAD -> Python/SVG composition -> Inkscape -> PNG/PDF`.
- Assertions that Inkscape is present only in the drawing profile.
- Three-profile image metrics and combined report evidence.

### Changed

- The shared OpenSCAD-facing contract now runs against OpenSCAD-focused,
  drawing and full/PythonSCAD profiles.
- The current runtime contract no longer requires
  `openscad-new-dimensions`; its v0.5.1 qualification remains historical
  immutable evidence.

### Qualification target

```text
test-v0.6.0-toolchain-v0.6.0
```

## v0.5.1

### Added

- Public-path and exact-commit checks for the installed
  `openscad-new-dimensions` library in both runtime profiles.
- A suite-owned OpenSCAD consumer wrapper that resolves the pinned library and
  executes its real dimensioning demo in the upstream 2D render mode used for SVG export.
- Non-empty SVG export assertions plus retained SVG evidence in the combined
  HTML report.

### Versioning note

`test-v0.5.0-toolchain-v0.5.1` remains valid evidence for the unchanged
v0.5.0 suite contract. It does **not** retroactively prove the new dimension
consumer path because that test did not exist in v0.5.0.

Adding that functional coverage changes suite behavior, so the test-suite
version advances to v0.5.1.

### Qualification target

```text
test-v0.5.1-toolchain-v0.5.1
```

## v0.5.0

### Added

- Separate consumer validation for the OpenSCAD-focused runtime and the
  full/dual runtime.
- Shared public-contract coverage for OpenSCAD, Git, SCons, BOSL2,
  documentation tooling and image watermarking.
- Full-runtime coverage for PythonSCAD, pybosl2 and documented compatibility
  XFAIL probes.
- Combined HTML evidence with mutable `/latest/` publication and immutable
  tag-named reports.
- Independent test-suite/toolchain release tags so one released suite revision
  can qualify more than one immutable toolchain release.

### Immutable qualification records

The same released `v0.5.0` suite has qualified these immutable toolchain
releases:

| Qualification tag | Result |
| --- | --- |
| `test-v0.5.0-toolchain-v0.5.0` | PASS |
| `test-v0.5.0-toolchain-v0.5.1` | PASS |

The `v0.5.1` toolchain qualification reuses the unchanged `v0.5.0` test-suite
source and proves that the newer runtime still satisfies the v0.5.0 contract.
The dedicated external dimension-library coverage begins with suite v0.5.1.

## Earlier immutable records

Earlier released verification tags remain the authoritative historical records:

```text
test-v0.1.0-toolchain-v0.1.1
test-v0.1.1-toolchain-v0.1.2
test-v0.1.2-toolchain-v0.1.2
test-v0.2.0-toolchain-v0.2.0
test-v0.3.0-toolchain-v0.3.0
test-v0.4.0-toolchain-v0.4.0
test-v0.4.1-toolchain-v0.4.1
test-v0.4.2-toolchain-v0.4.1
```

Detailed evidence for released qualifications is published by the tagged test
workflow and retained on GitHub Pages.
