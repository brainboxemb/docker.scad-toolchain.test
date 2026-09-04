import os
from pathlib import Path

from pythonscad import *

# PythonSCAD executes source through its embedded runtime and does not provide
# Python's normal script-file variable. The verification harness therefore
# supplies the SCAD source path explicitly.
library_file = Path(os.environ["OPENSCAD_OBJECT_PROBE_SCAD"])

if not library_file.is_file():
    raise FileNotFoundError(f"OpenSCAD object probe library not found: {library_file}")

library = osuse(str(library_file))

item = library.object_probe_create(4)

# Current PythonSCAD behavior: an OpenSCAD experimental object() result does
# not cross the interoperability layer as a usable Python-side object.
#
# Emit one stable marker for the XFAIL harness. If a future PythonSCAD release
# makes this work, this script completes and the outer harness treats that as
# an unexpected success that requires review.
if item is None:
    raise RuntimeError("PYTHONSCAD_OPENSCAD_OBJECT_XFAIL")

try:
    size = library.object_probe_size(item)
except Exception as exc:
    raise RuntimeError("PYTHONSCAD_OPENSCAD_OBJECT_XFAIL") from exc

if size is None:
    raise RuntimeError("PYTHONSCAD_OPENSCAD_OBJECT_XFAIL")

show(cube([float(size), 2, 2]))
