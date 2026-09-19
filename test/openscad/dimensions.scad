// External consumer probe for the shared dimensioning library.
//
// Resolve the installed package through OPENSCADPATH, exactly as a normal
// project would. The pinned upstream demo is 3D, so project it to a true 2D
// drawing before SVG export. This exercises the real upstream dimension
// geometry while keeping the suite-owned output deterministic.
projection(cut = false) {
    include <openscad-new-dimensions/demo/demo.scad>
}
