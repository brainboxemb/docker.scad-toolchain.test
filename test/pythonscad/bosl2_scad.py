import os
from pathlib import Path

from pythonscad import *

# BOSL2 is intended to be entered through std.scad. std.scad establishes the
# standard constants/dependencies and then includes shapes3d.scad and the rest
# of the normal BOSL2 module set.
bosl2_root = Path(os.environ["BOSL2_ROOT"])
bosl2_file = bosl2_root / "std.scad"

if not bosl2_file.is_file():
    raise FileNotFoundError(f"BOSL2 std.scad not found: {bosl2_file}")

bosl2 = osuse(str(bosl2_file))

# Keep this geometry equivalent to the native OpenSCAD and pybosl2 tests.
part = bosl2.cuboid(
    [30, 20, 10],
    rounding=3,
)

part.show()
