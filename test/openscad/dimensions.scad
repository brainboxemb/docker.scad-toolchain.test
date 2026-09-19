// External consumer probe for the shared dimensioning library.
//
// Resolve the installed package through OPENSCADPATH, exactly as a normal
// project would. The upstream demo has a built-in 2D render mode; CI selects
// that mode with -D so the same source becomes a true SVG-ready 2D drawing.
include <openscad-new-dimensions/demo/demo.scad>
