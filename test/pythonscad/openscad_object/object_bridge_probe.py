from pathlib import Path

from pythonscad import *

library_file = Path(__file__).with_name("object_api.scad")
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
