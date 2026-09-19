#!/usr/bin/env python3
"""External consumer: OpenSCAD STL -> FreeCAD refined Part -> TechDraw HLR."""

from __future__ import annotations

import os
from pathlib import Path

import FreeCAD as App
import Mesh
import Part
import TechDraw


input_path = Path(os.environ["FREECAD_HLR_INPUT"])
output_path = Path(os.environ["FREECAD_HLR_OUT"])
output_path.parent.mkdir(parents=True, exist_ok=True)

mesh = Mesh.Mesh(str(input_path))
facet_count = mesh.CountFacets
if facet_count <= 0:
    raise RuntimeError("input STL contains no mesh facets")

shape = Part.Shape()
shape.makeShapeFromMesh(mesh.Topology, 0.05)

solid = Part.makeSolid(shape)
solid = solid.removeSplitter()

if solid.isNull() or not solid.isValid():
    raise RuntimeError("mesh-to-Part conversion did not produce a valid solid")

face_count = len(solid.Faces)
if face_count >= facet_count:
    raise RuntimeError(
        "refine/removeSplitter did not reduce the STL face topology: "
        f"facets={facet_count}, faces={face_count}"
    )

direction = App.Vector(0, 0, 1)
projection = TechDraw.project(solid, direction)
visible_edges = sum(len(group.Edges) for group in projection[:2])
hidden_edges = sum(len(group.Edges) for group in projection[2:])

if visible_edges <= 0:
    raise RuntimeError("TechDraw HLR returned no visible edges")

svg = TechDraw.projectToSVG(solid, direction)
if "<path" not in svg:
    raise RuntimeError("TechDraw HLR SVG contains no projected path geometry")

marker = (
    "<!-- FREECAD_HLR_CONSUMER "
    f"mesh_facets={facet_count} "
    f"refined_faces={face_count} "
    f"visible_edges={visible_edges} "
    f"hidden_edges={hidden_edges} -->\n"
)

if "<svg" in svg:
    svg = svg.replace(">", ">\n" + marker, 1)
else:
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n'
        + marker
        + svg
        + "\n</svg>\n"
    )

output_path.write_text(svg, encoding="utf-8")

print(
    "FreeCAD STL-to-HLR consumer path validated: "
    f"mesh_facets={facet_count}, refined_faces={face_count}, "
    f"visible_edges={visible_edges}, hidden_edges={hidden_edges}"
)
