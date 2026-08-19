#!/usr/bin/env python3
"""Builds the font the screenshots are rendered with.

Noto Sans has no U+2192 (the "→" between a task's start and end dates), and a
headless Flutter test has no fontconfig to fall back through — so the arrow
came out as a tofu box. Registering a second font under the same family does
not help: Flutter treats same-family faces as weight variants and the first
match wins, it does not fall back per glyph.

So: subset DejaVu Sans down to just the codepoints Noto lacks (which makes the
merge conflict-free, since the two cmaps no longer overlap) and merge that in.
Output goes next to this script and is regenerated only when missing.
"""
import pathlib
import sys

from fontTools.merge import Merger
from fontTools.subset import Subsetter
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

HERE = pathlib.Path(__file__).parent
NOTO = pathlib.Path('/usr/share/fonts/truetype/noto')
DEJAVU = pathlib.Path('/usr/share/fonts/truetype/dejavu')

# Characters the app draws that Noto Sans does not carry.
WANTED = [
    0x2192,  # →  between a task's start and end dates
    0x2713,  # ✓  in the encouragement snackbar
    0x25CB,  # ○  the "missed" marker in exported history
]

FACES = [
    ('NotoSans-Regular.ttf', 'DayForgeSans-Regular.ttf'),
    ('NotoSans-Medium.ttf', 'DayForgeSans-Medium.ttf'),
    ('NotoSans-Bold.ttf', 'DayForgeSans-Bold.ttf'),
]


def covered(path):
    font = TTFont(path, fontNumber=0)
    chars = set()
    for table in font['cmap'].tables:
        chars |= set(table.cmap.keys())
    return chars


def build(src_name, out_name):
    out = HERE / out_name
    if out.exists():
        return out
    src = NOTO / src_name
    missing = [c for c in WANTED if c not in covered(src)]
    if not missing:
        TTFont(src).save(out)
        return out

    # Subset the donor to only what is missing, so the merge has no
    # overlapping glyphs to argue about.
    donor = TTFont(DEJAVU / 'DejaVuSans.ttf')
    sub = Subsetter()
    sub.populate(unicodes=missing)
    sub.subset(donor)
    # DejaVu ships a MATH table the merger cannot combine ("MathConstants has
    # no attribute mergeMap"). Nothing outside the core outline tables matters
    # for one arrow glyph, so drop the rest.
    keep = {'head', 'hhea', 'maxp', 'OS/2', 'hmtx', 'cmap', 'glyf', 'loca',
            'name', 'post'}
    for tag in [t for t in donor.keys() if t not in keep and t != 'GlyphOrder']:
        del donor[tag]
    # Noto is drawn on a 1000-unit em, DejaVu on 2048; the merger refuses to
    # combine faces whose unitsPerEm differ, and an unscaled merge would give
    # a double-size arrow anyway.
    src_upem = TTFont(src)['head'].unitsPerEm
    if donor['head'].unitsPerEm != src_upem:
        scale_upem(donor, src_upem)
    donor_path = HERE / f'.donor-{out_name}'
    donor.save(donor_path)

    merger = Merger()
    merged = merger.merge([str(src), str(donor_path)])
    merged.save(out)
    donor_path.unlink(missing_ok=True)
    return out


def main():
    for src_name, out_name in FACES:
        path = build(src_name, out_name)
        have = covered(path)
        ok = all(c in have for c in WANTED)
        print(f'{out_name}: {"ok" if ok else "MISSING GLYPHS"}')
        if not ok:
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
