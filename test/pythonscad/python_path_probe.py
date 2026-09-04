import sys

from pythonscad import *

print("PYTHONSCAD_SYS_PATH_BEGIN")
for entry in sys.path:
    print(entry)
print("PYTHONSCAD_SYS_PATH_END")

# Keep the probe exportable as geometry too.
show(cube([5, 5, 5]))
