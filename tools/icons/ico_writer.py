"""ICO container writer (shared by the brand icon generator).

Why this module exists (Task 33, 2026-11-11):
    The hand-rolled ICO writer used to live inside make_app_icon.py, the
    LEGACY green-tile icon generator.  Task 33 requires the legacy generator
    to stop being an input of the release chain, and the release chain is
    make_brand_icon.py (the only brand icon source of truth, Set I / I03).
    Keeping the writer here means make_brand_icon.py depends on this module
    instead of on the legacy generator, so the legacy file has ZERO inbound
    references and can never influence a shipped icon.

The code is moved verbatim from make_app_icon.py, so the produced .ico bytes
are unchanged.

Pillow's ICO plugin is deliberately NOT used: on this machine importing it
pulls a broken `olefile` and aborts the whole save.
"""

from __future__ import annotations

import struct

from PIL import Image


def bmp_entry(img: Image.Image) -> bytes:
    """One 32-bit BMP (DIB) entry: header + bottom-up BGRA pixels + AND mask."""
    width, height = img.size
    header = struct.pack(
        "<IiiHHIIiiII",
        40,          # biSize
        width,       # biWidth
        height * 2,  # biHeight (image + mask)
        1,           # biPlanes
        32,          # biBitCount
        0,           # biCompression
        width * height * 4,
        0, 0, 0, 0,
    )
    rgba = img.convert("RGBA").tobytes()
    rows = []
    for y in range(height - 1, -1, -1):
        row = rgba[y * width * 4 : (y + 1) * width * 4]
        bgra = bytearray()
        for x in range(width):
            r, g, b, a = row[x * 4 : x * 4 + 4]
            bgra += bytes((b, g, r, a))
        rows.append(bytes(bgra))
    mask_row_bytes = ((width + 31) // 32) * 4
    mask = b"\x00" * (mask_row_bytes * height)
    return header + b"".join(rows) + mask


def write_ico(path: str, master: Image.Image, sizes: tuple[int, ...]) -> list:
    """Assemble a classic (BMP-compressed) .ico container by hand."""
    images = [master.resize((s, s), Image.LANCZOS) for s in sizes]
    datas = [bmp_entry(im) for im in images]

    header = struct.pack("<HHH", 0, 1, len(images))
    offset = 6 + 16 * len(images)
    entries = []
    for size, data in zip(sizes, datas):
        entries.append(
            struct.pack(
                "<BBBBHHII",
                0 if size >= 256 else size,
                0 if size >= 256 else size,
                0, 0, 1, 32,
                len(data),
                offset,
            )
        )
        offset += len(data)

    with open(path, "wb") as fh:
        fh.write(header)
        for entry in entries:
            fh.write(entry)
        for data in datas:
            fh.write(data)
    return list(zip(sizes, [len(d) for d in datas]))


def ico_entries(path: str) -> list:
    """Re-read the .ico header by hand (no Pillow) to prove what we wrote."""
    with open(path, "rb") as fh:
        blob = fh.read()
    reserved, kind, count = struct.unpack("<HHH", blob[:6])
    out = []
    for i in range(count):
        off = 6 + 16 * i
        w, h, _, _, planes, bits, size, offset = struct.unpack(
            "<BBBBHHII", blob[off : off + 16]
        )
        out.append((w or 256, h or 256, planes, bits, size, offset))
    assert reserved == 0 and kind == 1, "bad ICO header"
    assert count == len(out)
    for _, _, _, _, size, offset in out:
        assert offset + size <= len(blob), "ICO entry out of range"
    return out


# Backward-compatible aliases (the old private names).
_write_ico = write_ico
_ico_entries = ico_entries
