# Keep this filename different from the installed package name.
# A local pybosl2.py would shadow the real package during import.

import sys

# External pip packages supplied by the toolchain live outside PythonSCAD's
# embedded default sys.path.
sys.path.insert(0, "/opt/python-libs")

from pythonscad import *
from pybosl2 import cuboid

# Keep this geometry equivalent to bosl2_scad.py and the native OpenSCAD test.
part = cuboid(
    [30, 20, 10],
    rounding=3,
)

part.show()
