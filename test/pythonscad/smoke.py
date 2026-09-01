from pythonscad import *

model = cylinder(h=8, d=24) - cylinder(h=10, d=12).translate([0, 0, -1])

output(model)
