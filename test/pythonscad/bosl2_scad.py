import os
from pathlib import Path

from pythonscad import *

# osuse() expects a real filesystem path; it does not resolve this source
# through OpenSCAD's OPENSCADPATH.
bosl2_root = Path(os.environ["BOSL2_ROOT"])
bosl2_file = bosl2_root / "shapes3d.scad"

if not bosl2_file.is_file():
    raise FileNotFoundError(f"BOSL2 source not found: {bosl2_file}")

bosl2 = osuse(str(bosl2_file))

# Keep this geometry equivalent to the native OpenSCAD and pybosl2 tests.
part = bosl2.cuboid(
    [30, 20, 10],
    rounding=3,
)

part.show()
