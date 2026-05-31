#!/usr/bin/env python3
"""Generate App Store icons from Czedr-auth-logo.png on dark background."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "images" / "Czedr-auth-logo.png"
OUT = ROOT / "payooxe" / "Images.xcassets" / "AppIcon.appiconset"
BG = (42, 42, 44, 255)  # matches app #2a2a2c


def crop_c_mark(img: Image.Image) -> Image.Image:
    """Stylized C from dark auth logo (top of lockup)."""
    w, h = img.size
    top = img.crop((int(w * 0.08), 0, int(w * 0.92), int(h * 0.42)))
    return top.convert("RGBA")


def make_icon(size: int) -> Image.Image:
    mark = crop_c_mark(Image.open(SRC))
    canvas = Image.new("RGBA", (size, size), BG)
    pad = int(size * 0.14)
    target = size - pad * 2
    mw, mh = mark.size
    scale = min(target / mw, target / mh)
    nw, nh = int(mw * scale), int(mh * scale)
    mark = mark.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2 - int(size * 0.02)
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
