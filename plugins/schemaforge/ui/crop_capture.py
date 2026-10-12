"""Crop native screenshot pixels only; never redraw, recolor or resize the UI."""
import argparse
from pathlib import Path
from PIL import Image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--rect", required=True, help="left,top,width,height in native pixels")
args = parser.parse_args()
left, top, width, height = map(int, args.rect.split(","))
with Image.open(args.source) as image:
    assert left >= 0 and top >= 0 and left + width <= image.width and top + height <= image.height
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.crop((left, top, left + width, top + height)).save(args.output)
print(args.output)
