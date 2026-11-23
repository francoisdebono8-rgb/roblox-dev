#!/usr/bin/env python3
"""(23/11, étape 5) The 8 prodigies' bundle image (512 x 512, transparent), composed from their
offer renders (offer_renders.py offers): the first four behind and raised, the last four in
front. Plain Python + Pillow, no Blender.

    python3 tools/blender/offer_bundle.py assets/renders/offers
"""
import sys
from PIL import Image

IDS = ["SetNaruto", "SetSasuke", "SetLee", "SetNeji", "SetGaara", "SetKakashi", "SetItachi", "SetMinato"]


def main(folder):
    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    ims = [Image.open("%s/%s.png" % (folder, i)).convert("RGBA") for i in IDS]
    for row, (scale, y0, xoff) in enumerate(((.42, 40, 64), (.5, 250, 0))):
        for k in range(4):
            im = ims[row * 4 + k]
            im = im.crop(im.getbbox())
            h = int(512 * scale)
            w = int(im.width * h / im.height)
            im = im.resize((w, h), Image.LANCZOS)
            cx = xoff + (512 - 2 * xoff) * (k + .5) / 4
            out.alpha_composite(im, (int(cx - w / 2), y0))
    out.save("%s/SetBundle8.png" % folder)


if __name__ == "__main__":
    main(sys.argv[1])
