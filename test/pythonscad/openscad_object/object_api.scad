// Minimal OpenSCAD object-based API used only as an interoperability probe.
//
// Keep this object-based. Do not add scalar bridge wrappers merely to make
// PythonSCAD pass; the purpose is to test the real object boundary.

function object_probe_create(size = 4) =
    object(
        size = size
    );

function object_probe_size(item) =
    item.size;

module object_probe_build(item) {
    cube([object_probe_size(item), 2, 2]);
}
