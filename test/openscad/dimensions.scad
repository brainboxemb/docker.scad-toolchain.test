// External consumer probe for the shared dimensioning library.
//
// Resolve the installed package through OPENSCADPATH, exactly as a normal
// project would. The pinned upstream demo exercises the library's real
// dimension annotations; this repository owns only the consumer wrapper and
// output assertions.
include <openscad-new-dimensions/demo/demo.scad>
