#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
from pathlib import Path
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)


def tag(name: str) -> str:
    return f"{{{SVG}}}{name}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source_tree = ET.parse(args.source)
    source_root = source_tree.getroot()
    source_viewbox = source_root.attrib.get("viewBox")
    if not source_viewbox:
        raise SystemExit("source SVG has no viewBox")

    root = ET.Element(
        tag("svg"),
        {
            "width": "297mm",
            "height": "210mm",
            "viewBox": "0 0 297 210",
        },
    )

    defs = ET.SubElement(root, tag("defs"))
    marker = ET.SubElement(
        defs,
        tag("marker"),
        {
            "id": "arrow",
            "viewBox": "0 0 10 10",
            "refX": "5",
            "refY": "5",
            "markerWidth": "5",
            "markerHeight": "5",
            "orient": "auto-start-reverse",
        },
    )
    ET.SubElement(marker, tag("path"), {"d": "M 0 0 L 10 5 L 0 10 z"})

    style = {
        "fill": "none",
        "stroke": "black",
        "stroke-width": "0.35",
    }
    ET.SubElement(root, tag("rect"), {"x": "10", "y": "10", "width": "277", "height": "190", **style})

    nested = ET.SubElement(
        root,
        tag("svg"),
        {
            "x": "25",
            "y": "35",
            "width": "125",
            "height": "95",
            "viewBox": source_viewbox,
            "preserveAspectRatio": "xMidYMid meet",
        },
    )
    for child in source_root:
        nested.append(copy.deepcopy(child))

    dimension_style = {
        "stroke": "black",
        "stroke-width": "0.35",
        "marker-start": "url(#arrow)",
        "marker-end": "url(#arrow)",
    }
    ET.SubElement(root, tag("line"), {"x1": "35", "y1": "148", "x2": "140", "y2": "148", **dimension_style})
    ET.SubElement(root, tag("line"), {"x1": "35", "y1": "135", "x2": "35", "y2": "153", **style})
    ET.SubElement(root, tag("line"), {"x1": "140", "y1": "135", "x2": "140", "y2": "153", **style})

    text_style = {
        "font-family": "DejaVu Sans, sans-serif",
        "fill": "black",
    }
    ET.SubElement(root, tag("text"), {"x": "87.5", "y": "144", "font-size": "4", "text-anchor": "middle", **text_style}).text = "105"
    ET.SubElement(root, tag("text"), {"x": "25", "y": "25", "font-size": "5", **text_style}).text = "SCAD DRAWING PROFILE"

    title = ET.SubElement(root, tag("g"))
    ET.SubElement(title, tag("rect"), {"x": "180", "y": "165", "width": "107", "height": "35", **style})
    ET.SubElement(title, tag("line"), {"x1": "180", "y1": "180", "x2": "287", "y2": "180", **style})
    ET.SubElement(title, tag("text"), {"x": "184", "y": "176", "font-size": "5", **text_style}).text = "External drawing contract"
    ET.SubElement(title, tag("text"), {"x": "184", "y": "190", "font-size": "3.5", **text_style}).text = "OpenSCAD -> Python/SVG -> Inkscape"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(args.output, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
