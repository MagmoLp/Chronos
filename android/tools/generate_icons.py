#!/usr/bin/env python3
"""Generates Chronos' Android launcher and notification icons.

Usage (Pillow required, see docs/ANDROID_BUILD.md):
    git show v1.0.0:android/app/src/main/res/drawable/ic_launcher_foreground.png > /tmp/source.png
    python3 android/tools/generate_icons.py /tmp/source.png [--preview DIR]

Outputs (relative to android/app/src/main/res):
  mipmap-<dpi>/ic_launcher_foreground.png  adaptive foreground, 108 dp canvas, mark in the 66 dp safe zone
  mipmap-<dpi>/ic_launcher.png             legacy square icon (API 24/25), 48 dp
  mipmap-<dpi>/ic_launcher_round.png       legacy round icon (API 24/25), 48 dp
  drawable/ic_launcher_monochrome.xml      themed-icon layer (Android 13+), vector
  drawable/ic_stat_chronos.xml             notification small icon, vector, 24 dp

The source is the detailed 2048 x 2048 neon hourglass of v1 (transparent background). The
background layer is the solid brand navy @color/ic_launcher_background (#001F3F).
The monochrome and notification icons share one simple vector hourglass (GLYPH below), because
the detailed artwork does not survive being reduced to a single-colour silhouette.
"""

from __future__ import annotations

import argparse
import math
import os
import sys

from PIL import Image, ImageDraw

RES = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'app', 'src', 'main', 'res')

DENSITIES = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}
NAVY = (0x00, 0x1F, 0x3F, 255)

# Adaptive icon geometry (dp).
CANVAS_DP = 108.0  # full layer
VISIBLE_DP = 72.0  # what launcher masks show at most
MARK_RADIUS_DP = 32.0  # farthest opaque pixel of the mark from the centre (safe zone: 33 dp)
LEGACY_DP = 48.0
LEGACY_SHAPE_DP = 44.0

# --- Vector hourglass, 24 x 24 viewport --------------------------------------------------------
# Each entry: (kind, path) with kind 'fill' or ('stroke', width). Only M, H, V, L, C, A, Z with
# absolute coordinates are used, so that the preview rasteriser below can draw them.
GLYPH = [
    ('fill', 'M6.2,2 H17.8 A1.2,1.2 0 0 1 17.8,4.4 H6.2 A1.2,1.2 0 0 1 6.2,2 Z'),
    ('fill', 'M6.2,19.6 H17.8 A1.2,1.2 0 0 1 17.8,22 H6.2 A1.2,1.2 0 0 1 6.2,19.6 Z'),
    (('stroke', 1.6), 'M7.4,4.4 C7.4,8.6 10.6,10.2 10.6,12 C10.6,13.8 7.4,15.4 7.4,19.6'),
    (('stroke', 1.6), 'M16.6,4.4 C16.6,8.6 13.4,10.2 13.4,12 C13.4,13.8 16.6,15.4 16.6,19.6'),
    ('fill', 'M9.4,7.2 H14.6 C14,8.5 12.9,9.5 12,10.5 C11.1,9.5 10,8.5 9.4,7.2 Z'),
    ('fill', 'M12,15.4 C13.3,16.4 15.2,17.5 15.5,19.6 H8.5 C8.8,17.5 10.7,16.4 12,15.4 Z'),
    (('stroke', 0.9), 'M12,11.6 V14.2'),
]

# The glyph spans x 5..19 and y 2..22 of its 24 viewport; its farthest point from (12, 12) is
# about 12.2 units. Scale 2.5 keeps it inside the 33 dp safe-zone radius of the 108 dp layer.
MONO_SCALE = 2.5
MONO_TRANSLATE = 54 - 12 * MONO_SCALE


def _tokens(path):
    out, num = [], ''
    for ch in path.replace(',', ' '):
        if ch.isalpha() or ch == ' ':
            if num.strip():
                out.append(float(num))
            num = ''
            if ch.isalpha():
                out.append(ch)
        else:
            num += ch
    if num.strip():
        out.append(float(num))
    return out


def _flatten(path, steps=24):
    """Returns a list of polylines (lists of (x, y)) for an SVG-like path."""
    toks, i = _tokens(path), 0
    polys, cur, pos, start = [], [], (0.0, 0.0), (0.0, 0.0)
    while i < len(toks):
        cmd = toks[i]
        i += 1
        if cmd == 'M':
            if cur:
                polys.append(cur)
            pos = start = (toks[i], toks[i + 1])
            i += 2
            cur = [pos]
        elif cmd == 'L':
            pos = (toks[i], toks[i + 1])
            i += 2
            cur.append(pos)
        elif cmd == 'H':
            pos = (toks[i], pos[1])
            i += 1
            cur.append(pos)
        elif cmd == 'V':
            pos = (pos[0], toks[i])
            i += 1
            cur.append(pos)
        elif cmd == 'C':
            p0 = pos
            p1, p2, p3 = (toks[i], toks[i + 1]), (toks[i + 2], toks[i + 3]), (toks[i + 4], toks[i + 5])
            i += 6
            for s in range(1, steps + 1):
                t = s / steps
                mt = 1 - t
                cur.append((
                    mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0],
                    mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1],
                ))
            pos = p3
        elif cmd == 'A':
            # Only half-circle arcs (rx == ry, endpoints on a diameter) are used in GLYPH.
            r, _, _, _, sweep, x, y = toks[i:i + 7]
            i += 7
            cx, cy = (pos[0] + x) / 2, (pos[1] + y) / 2
            a0 = math.atan2(pos[1] - cy, pos[0] - cx)
            a1 = math.atan2(y - cy, x - cx)
            if sweep and a1 <= a0:
                a1 += 2 * math.pi
            if not sweep and a1 >= a0:
                a1 -= 2 * math.pi
            for s in range(1, steps + 1):
                a = a0 + (a1 - a0) * s / steps
                cur.append((cx + r * math.cos(a), cy + r * math.sin(a)))
            pos = (x, y)
        elif cmd == 'Z':
            cur.append(start)
            pos = start
        else:
            raise ValueError(f'unsupported path command {cmd}')
    if cur:
        polys.append(cur)
    return polys


def render_glyph(size_px, fg=(255, 255, 255, 255), scale=None, offset=0.0, supersample=8):
    """Rasterises GLYPH (viewport 24) into a transparent square image, for previews only."""
    big = size_px * supersample
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = (big / 24.0) if scale is None else scale * big
    off = offset * big
    for kind, path in GLYPH:
        for poly in _flatten(path):
            pts = [(off + x * s, off + y * s) for x, y in poly]
            if kind == 'fill':
                d.polygon(pts, fill=fg)
            else:
                w = kind[1] * s
                d.line(pts, fill=fg, width=max(1, round(w)))
                for x, y in pts:
                    d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=fg)
    return img.resize((size_px, size_px), Image.LANCZOS)


def _vector_paths(indent):
    lines = []
    for kind, path in GLYPH:
        if kind == 'fill':
            lines.append(f'{indent}<path\n'
                         f'{indent}    android:fillColor="#FFFFFFFF"\n'
                         f'{indent}    android:pathData="{path}" />')
        else:
            lines.append(f'{indent}<path\n'
                         f'{indent}    android:strokeColor="#FFFFFFFF"\n'
                         f'{indent}    android:strokeWidth="{kind[1]}"\n'
                         f'{indent}    android:strokeLineCap="round"\n'
                         f'{indent}    android:strokeLineJoin="round"\n'
                         f'{indent}    android:pathData="{path}" />')
    return '\n'.join(lines)


def write_vectors():
    notif = f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Notification small icon (status bar): white hourglass on transparent, 24 dp.
     Generated by android/tools/generate_icons.py. Kept from resource shrinking by res/raw/keep.xml. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
{_vector_paths('    ')}
</vector>
'''
    mono = f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Monochrome layer of the adaptive launcher icon (Android 13+ themed icons).
     Same hourglass as ic_stat_chronos, scaled into the 66 dp safe zone of the 108 dp canvas.
     Generated by android/tools/generate_icons.py. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="{MONO_SCALE}"
        android:scaleY="{MONO_SCALE}"
        android:translateX="{MONO_TRANSLATE:g}"
        android:translateY="{MONO_TRANSLATE:g}">
{_vector_paths('        ')}
    </group>
</vector>
'''
    with open(os.path.join(RES, 'drawable', 'ic_stat_chronos.xml'), 'w') as f:
        f.write(notif)
    with open(os.path.join(RES, 'drawable', 'ic_launcher_monochrome.xml'), 'w') as f:
        f.write(mono)


def _mark(source):
    """Crops the mark and returns (image, max distance of opaque pixels from its centre)."""
    box = source.split()[3].point(lambda v: 255 if v > 32 else 0).getbbox()
    mark = source.crop(box)
    a = mark.split()[3].point(lambda v: 255 if v > 32 else 0).resize(
        (max(1, mark.width // 4), max(1, mark.height // 4)), Image.NEAREST)
    cx, cy = mark.width / 2, mark.height / 2
    px, maxd = a.load(), 0.0
    for y in range(a.height):
        for x in range(a.width):
            if px[x, y]:
                maxd = max(maxd, math.hypot(x * 4 + 2 - cx, y * 4 + 2 - cy))
    return mark, maxd


def foreground(source, size_px):
    """Adaptive foreground: transparent 108 dp canvas with the mark centred in the safe zone."""
    mark, maxd = _mark(source)
    k = MARK_RADIUS_DP * (size_px / CANVAS_DP) / maxd
    scaled = mark.resize((round(mark.width * k), round(mark.height * k)), Image.LANCZOS)
    canvas = Image.new('RGBA', (size_px, size_px), (0, 0, 0, 0))
    canvas.alpha_composite(scaled, ((size_px - scaled.width) // 2, (size_px - scaled.height) // 2))
    return canvas


def legacy(source, size_px, round_shape):
    """Legacy (pre-API 26) icon: navy shape with the mark, as a launcher mask would show it."""
    ss = 4
    shape_px = round(size_px * ss * LEGACY_SHAPE_DP / LEGACY_DP)
    # Render the adaptive composition so that its 72 dp visible area covers the shape.
    comp_px = round(shape_px * CANVAS_DP / VISIBLE_DP)
    comp = Image.new('RGBA', (comp_px, comp_px), NAVY)
    comp.alpha_composite(foreground(source, comp_px))
    left = (comp_px - shape_px) // 2
    comp = comp.crop((left, left, left + shape_px, left + shape_px))
    mask = Image.new('L', comp.size, 0)
    md = ImageDraw.Draw(mask)
    if round_shape:
        md.ellipse((0, 0, comp.width - 1, comp.height - 1), fill=255)
    else:
        md.rounded_rectangle((0, 0, comp.width - 1, comp.height - 1), radius=comp.width * 0.18, fill=255)
    shaped = Image.new('RGBA', comp.size, (0, 0, 0, 0))
    shaped.paste(comp, (0, 0), mask)
    out = Image.new('RGBA', (size_px * ss, size_px * ss), (0, 0, 0, 0))
    out.alpha_composite(shaped, ((out.width - comp.width) // 2, (out.height - comp.height) // 2))
    return out.resize((size_px, size_px), Image.LANCZOS)


def write_previews(source, folder):
    os.makedirs(folder, exist_ok=True)
    for px in (24, 48, 96):
        render_glyph(px).save(os.path.join(folder, f'glyph_{px}.png'))
    size = 432
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse((72, 72, 360, 360), fill=255)
    comp = Image.new('RGBA', (size, size), NAVY)
    comp.alpha_composite(foreground(source, size))
    shown = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    shown.paste(comp, (0, 0), mask)
    shown.crop((72, 72, 360, 360)).save(os.path.join(folder, 'adaptive_circle.png'))
    themed = Image.new('RGBA', (size, size), (210, 228, 255, 255))
    themed.alpha_composite(render_glyph(size, fg=(20, 50, 90, 255), scale=MONO_SCALE / 108.0,
                                        offset=MONO_TRANSLATE / 108.0))
    themed_shown = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    themed_shown.paste(themed, (0, 0), mask)
    themed_shown.crop((72, 72, 360, 360)).save(os.path.join(folder, 'themed_circle.png'))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('source', help='2048 x 2048 RGBA source artwork (transparent background)')
    parser.add_argument('--preview', help='also write preview PNGs into this directory')
    args = parser.parse_args()

    source = Image.open(args.source).convert('RGBA')
    for name, factor in DENSITIES.items():
        folder = os.path.join(RES, f'mipmap-{name}')
        os.makedirs(folder, exist_ok=True)
        foreground(source, round(CANVAS_DP * factor)).save(
            os.path.join(folder, 'ic_launcher_foreground.png'), optimize=True)
        legacy(source, round(LEGACY_DP * factor), False).save(
            os.path.join(folder, 'ic_launcher.png'), optimize=True)
        legacy(source, round(LEGACY_DP * factor), True).save(
            os.path.join(folder, 'ic_launcher_round.png'), optimize=True)
    write_vectors()
    if args.preview:
        write_previews(source, args.preview)
    return 0


if __name__ == '__main__':
    sys.exit(main())
