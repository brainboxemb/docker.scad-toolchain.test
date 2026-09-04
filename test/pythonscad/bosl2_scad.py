from pythonscad import *

# This deliberately consumes the SCAD implementation rather than pybosl2.
# shapes3d.scad directly defines cuboid(), while its own includes resolve via
# OPENSCADPATH from the toolchain image.
bosl2 = osuse("BOSL2/shapes3d.scad")

part = bosl2.cuboid(
    [30, 20, 10],
    rounding=3,
)

part.show()
