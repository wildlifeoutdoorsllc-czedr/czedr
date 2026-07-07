#!/usr/bin/env python3
"""Generate App Store icons — full C mark, centered on brand dark #2a2a2c."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "images" / "Czedr-auth-logo.png"
OUT = ROOT / "Czedr" / "Images.xcassets" / "AppIcon.appiconset"
BG = (42, 42, 44, 255)


def content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    rgb = img.convert("RGB")
    w, h = rgb.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b = rgb.getpixel((x, y))
            if r + g + b > 90 or max(r, g, b) > 75:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    return min_x, min_y, max_x + 1, max_y + 1


def drop_muddy_grey(img: Image.Image) -> Image.Image:
    """Remove charcoal wedges that disappear on dark icons and look like glitches."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            if r > 120 or (r > 80 and r >= g + 8):
                continue
            if max(r, g, b) - min(r, g, b) > 35:
                continue
            if r < 115 and g < 115 and b < 120:
                px[x, y] = (r, g, b, 0)
    return img


def extract_c_mark(img: Image.Image) -> Image.Image:
    x0, y0, x1, y1 = content_bbox(img)
    mark = img.crop((x0, y0, x1, y1))
    rgb = mark.convert("RGB")
    mw, mh = mark.size
    cut = mh
    for y in range(int(mh * 0.5), mh):
        row = [rgb.getpixel((x, y)) for x in range(0, mw, 3)]
        text_like = sum(1 for r, g, b in row if min(r, g, b) > 200)
        if text_like > len(row) * 0.4:
            cut = max(int(mh * 0.45), y - 10)
            break
    mark = mark.crop((0, 0, mw, cut)).convert("RGBA")
    return drop_muddy_grey(mark)


def trim_transparent(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def make_icon(size: int) -> Image.Image:
    mark = trim_transparent(extract_c_mark(Image.open(SRC)))
    canvas = Image.new("RGBA", (size, size), BG)
    pad = int(size * 0.10)
    target = size - pad * 2
    mw, mh = mark.size
    scale = min(target / mw, target / mh)
    nw, nh = max(1, int(mw * scale)), max(1, int(mh * scale))
    mark = mark.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.paste(mark, (x, y), mark)
    return canvas.convert("RGB")


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing {SRC}")
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = {
        "Icon-1024.png": 1024,
        "Icon-60@3x.png": 180,
        "Icon-60@2x.png": 120,
        "Icon-40@2x.png": 80,
        "Icon-29@2x.png": 58,
        "Icon-20@2x.png": 40,
    }
    for name, px in sizes.items():
        make_icon(px).save(OUT / name, format="PNG", optimize=True)
        print(f"Wrote {name} ({px}px)")


if __name__ == "__main__":
    main()
