from pythonscad import *

injected_design_view = globals().get("design_view", "<missing>")

parameter_probe = add_parameter(
    "design_view_parameter",
    "parameter-default",
    options=["parameter-default", "01-ring", "02-opening", "final"],
)

print(f"INJECTED_DESIGN_VIEW={injected_design_view}")
print(f"ADD_PARAMETER_VALUE={parameter_probe}")

if injected_design_view == "01-ring":
    show(cube([10, 10, 10]))
elif injected_design_view == "02-opening":
    show(sphere(r=7, fn=48))
elif injected_design_view == "final":
    show(cylinder(h=12, r=5, fn=48))
else:
    show(cube([4, 4, 4]))
