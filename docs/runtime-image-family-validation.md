# Runtime image family validation

Status: **draft change request support for Migration 005**

Cross-project tracker: `brainboxemb/brainboxemb.meta#55`

Related architecture change request: `brainboxemb/brainboxemb.meta#59`

Toolchain implementation change request: `brainboxemb/docker.scad-toolchain#6`

## Purpose

Extend the external consumer-validation suite from one all-inclusive SCAD image to a related two-profile runtime family without splitting this repository.

The intended profiles are:

- `openscad`: OpenSCAD-focused runtime for OpenSCAD, BOSL2, documentation tooling, watermark/Pillow, SCons and required system/runtime tools;
- `full`: the same OpenSCAD contract plus PythonSCAD, pybosl2, Shapely and the existing interoperability/XFAIL probes.

## Required test relationship

The full image is a superset, so shared OpenSCAD-facing tests must run against **both** profiles.

| Capability | openscad | full |
| --- | --- | --- |
| OpenSCAD PNG/STL | required | required |
| OpenSCAD -> BOSL2 | required | required |
| docsgen/mdimggen | required | required |
| watermark/Pillow | required | required |
| SCons OpenSCAD consumer | required | required |
| Git/tooling basics | required | required |
| PythonSCAD PNG/STL | not required | required |
| PythonSCAD define/path probes | not required | required |
| PythonSCAD -> pybosl2 | not required | required |
| PythonSCAD interoperability XFAIL probes | not required | required |

## Evidence/reporting intent

Keep one test repository and one release relationship, but publish/report results separately per runtime profile and include a combined summary.

Development evidence should make it easy to compare:

- functional status per profile;
- exact image/version tested;
- compressed/pull measurements supplied by the toolchain qualification;
- supported capabilities;
- documented PythonSCAD XFAIL boundaries.

## Guardrails

- Do not weaken the current full-runtime test contract.
- Do not silently skip PythonSCAD tests on the full image.
- Do not require PythonSCAD from the OpenSCAD profile.
- Keep immutable release evidence tied to exact immutable image versions.
- Do not split this external validation into a second repository unless evidence shows one suite cannot remain understandable.
