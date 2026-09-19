#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess

import drawsvg as draw


def export_with_inkscape(source: Path, output: Path, export_type: str) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "inkscape",
            str(source),
            "--export-area-page",
            f"--export-type={export_type}",
            f"--export-filename={output}",
        ],
        check=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--png", type=Path)
    parser.add_argument("--pdf", type=Path)
    args = parser.parse_args()

    if not args.source.is_file():
        raise SystemExit(f"source SVG does not exist: {args.source}")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    sheet = draw.Drawing(297, 210, origin=(0, 0))

    line_style = {"stroke": "black", "stroke_width": 0.35, "fill": "none"}
    text_style = {"fill": "black", "font_family": "DejaVu Sans"}

    sheet.append(draw.Rectangle(10, 10, 277, 190, **line_style))
    sheet.append(
        draw.Image(
            25,
            35,
            125,
            95,
            path=str(args.source),
            embed=True,
            mime_type="image/svg+xml",
        )
    )

    sheet.append(draw.Line(35, 148, 140, 148, **line_style))
    sheet.append(draw.Line(35, 135, 35, 153, **line_style))
    sheet.append(draw.Line(140, 135, 140, 153, **line_style))
    sheet.append(
        draw.Text(
            "105",
            4,
            87.5,
            144,
            center=True,
            **text_style,
        )
    )

    sheet.append(draw.Text("SCAD DRAWING PROFILE", 5, 25, 25, **text_style))

    sheet.append(draw.Rectangle(180, 165, 107, 35, **line_style))
    sheet.append(draw.Line(180, 180, 287, 180, **line_style))
    sheet.append(
        draw.Text(
            "External drawing contract",
            5,
            184,
            176,
            **text_style,
        )
    )
    sheet.append(
        draw.Text(
            "OpenSCAD -> Python/drawsvg -> Inkscape",
            3.5,
            184,
            190,
            **text_style,
        )
    )

    sheet.save_svg(str(args.output))

    if args.png is not None:
        export_with_inkscape(args.output, args.png, "png")
    if args.pdf is not None:
        export_with_inkscape(args.output, args.pdf, "pdf")


if __name__ == "__main__":
    main()
