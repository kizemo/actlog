"""LEGACY icon generator - HISTORICAL ARTEFACT, DO NOT USE (Task 33, 2026-11-11).

    >>> THIS FILE IS NOT AN INPUT OF THE RELEASE CHAIN. <<<
    >>> DO NOT RUN IT TO PRODUCE A SHIPPED ICON. <<<

What it used to be:
    the original PractiLog application icon generator - a green gradient
    rounded tile (seed green 0xFF2E8B57 family) with a white checkmark
    ("know -> do").  This is exactly the "old icon" the user kept seeing in
    the taskbar / top-left corner, and Task 32 (brand icon Set I / I03)
    replaced it.

Why it is kept at all:
    project rule R4 forbids deleting files; renaming + marking it legacy is
    the sanctioned way to retire a script.

What changed in Task 33:
    1. the file was renamed  make_app_icon.py -> make_app_icon_legacy.py;
    2. its OUTPUT PATHS were moved out of the release tree.  It used to write
       straight into
           apps/desktop/assets/icon.png
           apps/desktop/windows/runner/resources/app_icon.ico
       which are the files the shipped app actually loads.  Now it writes into
       tools/icons/_legacy_output/ , so it can never overwrite a shipped icon
       even by accident;
    3. the ICO container writer moved to ico_writer.py , so the release chain
       (make_brand_icon.py) no longer imports this module - this file now has
       ZERO inbound references.

The only brand icon source of truth is:
    tools/icons/make_brand_icon.py   (Set I / I03, deep-navy bowl over the
    ink stem, see design-demos/logo-set-i-bowl-overlap-2026-11-11/)

Usage (from repo root) - for archaeology only, never for shipping:
    python tools/icons/make_app_icon_legacy.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

from ico_writer import write_ico

MASTER = 1024
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)

TOP = (58, 168, 118)
BOTTOM = (28, 104, 68)
WHITE = (255, 255, 255, 255)

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# LEGACY OUTPUT DIRECTORY - deliberately NOT the release asset paths.
LEGACY_OUT_DIR = os.path.join(REPO_ROOT, "tools", "icons", "_legacy_output")
PNG_OUT = os.path.join(LEGACY_OUT_DIR, "legacy_icon.png")
ICO_OUT = os.path.join(LEGACY_OUT_DIR, "legacy_app_icon.ico")

# The paths this script used to own. Kept as constants only so the header of
# the file documents what was moved; nothing writes to them any more.
RELEASE_PNG_OUT = os.path.join(
    REPO_ROOT, "apps", "desktop", "assets", "icon.png"
)
RELEASE_ICO_OUT = os.path.join(
    REPO_ROOT, "apps", "desktop", "windows", "runner", "resources", "app_icon.ico"
)


def _rounded_tile(size: int) -> Image.Image:
    """Vertical-gradient rounded square with transparent corners."""
    gradient = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(gradient)
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(
            round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)
        ) + (255,)
        draw.line([(0, y), (size, y)], fill=color)

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=round(size * 0.22), fill=255
    )

    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile.paste(gradient, (0, 0), mask)
    return tile


def _checkmark(size: int) -> Image.Image:
    """White checkmark with round caps, drawn on a transparent layer."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    width = round(size * 0.115)
    radius = width / 2
    points = [
        (size * 0.275, size * 0.525),
        (size * 0.435, size * 0.680),
        (size * 0.745, size * 0.335),
    ]
    draw.line(points, fill=WHITE, width=width, joint="curve")
    for x, y in points:
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=WHITE)
    return layer


def _compose(size: int) -> Image.Image:
    tile = _rounded_tile(size)
    tile.alpha_composite(_checkmark(size))
    return tile


def main() -> None:
    master = _compose(MASTER)

    os.makedirs(LEGACY_OUT_DIR, exist_ok=True)

    master.resize((256, 256), Image.LANCZOS).save(PNG_OUT, format="PNG")
    written = write_ico(ICO_OUT, master, ICO_SIZES)

    print("LEGACY ARTIFACT - not a release input.")
    print(f"png  -> {PNG_OUT} ({os.path.getsize(PNG_OUT)} bytes)")
    print(f"ico  -> {ICO_OUT} ({os.path.getsize(ICO_OUT)} bytes)")
    print(f"ico entries (size, bytes): {written}")
    print(f"release paths left untouched: {RELEASE_PNG_OUT} / {RELEASE_ICO_OUT}")
    print("BRAND_ICON_SOURCE=tools/icons/make_brand_icon.py")


if __name__ == "__main__":
    main()
