// File: docsgen.scad
//   Minimal external consumer source for validating openscad_docsgen.
//
// FileSummary: External consumer smoke test for openscad_docsgen.
//
// Module: docsgen_consumer_smoke()
// Usage:
//   docsgen_consumer_smoke();
//   docsgen_consumer_smoke(size=12);
// Description:
//   Creates a cube so the source contains one real documented OpenSCAD module.
// Arguments:
//   size = Side length of the generated cube.
module docsgen_consumer_smoke(size = 10) {
    cube(size);
}

docsgen_consumer_smoke();
