# -*- coding: utf-8 -*-
"""actlog 「aag」品牌图标生成器（Task 48 · 2026-11-20）。

用户给了两张设计稿，本脚本把设计稿加工成 Flutter / Windows 直接可用的资产。
本脚本是**幂等**的：产物字节只由两个源 PNG 与本文件里的常量决定（无时间戳、
无随机量、无环境相关字段），重复执行逐字节相同。

源（只读，**不得修改**）：
  log_design_brightbg.png   240x240 RGBA  「aag」黑字标 + 透明底（alpha 可用）
  log_design_darkbg.png     240x240 RGB   「aag」白字标 + 暖墨深褐 #4B2D2D 方块底（无 alpha）

产物（写集见 Task 48 派工书 §3，本脚本只写这些）：
  apps/desktop/assets/brand_mark.png        顶栏 · 浅色主题；裁到墨迹 bbox；PNG 颜色类型 6
  apps/desktop/assets/brand_mark_dark.png   顶栏 · 暗色主题；与上一份同 bbox / 同缩放 /
                                            同 alpha，**仅 RGB 换白**；颜色类型 6
  apps/desktop/assets/icon.png              托盘；darkbg 整幅缩到 256x256；不透明；颜色类型 6
  apps/desktop/windows/runner/resources/app_icon.ico
                                            9 档 16/20/24/32/40/48/64/128/256，全 32bpp DIB
  reports/task48-ico-preview-16.png         从 ico 的第 16 档解码导出（原生像素，不放大）
  reports/task48-ico-preview-32.png         同上，第 32 档
  reports/task48-ico-preview-256.png        同上，第 256 档
  reports/task48-brand-mark-preview.png     黑字标铺浅灰底（目视用）
  reports/task48-brand-mark-dark-preview.png 白字标铺深底（目视用）

几何口径：
  * brand_mark 的取景框 = brightbg 里 alpha > 0 的像素包围盒（实测 (5,81)-(236,157)
    ⇒ 231x76）。231 与 76 互质 ⇒ 任何整数高度 h 上只有 h=76（w=231）能**逐字**等于
    bbox 宽高比。派工书 §4.2 的「高度 64」是建议值，而「长宽比必须等于墨迹 bbox
    的宽高比（不许拉伸变形）」是硬约束 ⇒ 取 bbox 原始尺寸、零重采样（既精确又无
    插值毛边）。
  * brand_mark_dark 由同一 bbox、同一像素网格派生：alpha 通道逐字照搬，RGB 全置 255；
    因此两张图的宽高与 alpha 逐像素完全一致。
  * icon.png 与 app_icon.ico 的母版 = darkbg **整幅**（它本身就是铺满的方形 tile，
    角像素就是底色，天然满足「不透明、不圆角、不留透明边」）。
  * ico 容器复用同目录 ico_writer.py 的 write_ico / ico_entries（手搓 BMP-DIB 容器）；
    **不用** Pillow 的 ICO 插件 —— 本机 import 它会拉进坏掉的 olefile 并直接 abort。

不改 pubspec.yaml：那是配置，只有一次性的手工新增（`- assets/brand_mark_dark.png`），
脚本重复执行不碰它，也不删任何文件（AGENTS.md §2 R4）。
"""

from __future__ import annotations

import argparse
import hashlib
import struct
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from ico_writer import ico_entries, write_ico  # noqa: E402

DEFAULT_ROOT = HERE.parents[1]          # tools/icons/make_aag_icon.py -> 仓库根

SRC_BRIGHT_NAME = "log_design_brightbg.png"
SRC_DARK_NAME = "log_design_darkbg.png"

ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)   # 与旧 ico 档位完全一致
TRAY_SIZE = 256
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
PREVIEW_LIGHT_BG = (235, 235, 235)
PREVIEW_DARK_BG = (31, 31, 31)


# --------------------------------------------------------------------------- #
# 小工具
# --------------------------------------------------------------------------- #
def sha16(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:16].upper()


def png_ihdr(path: Path) -> tuple[int, int, int]:
    """(宽, 高, PNG 颜色类型)。第 25 字节 = IHDR 的 bit depth 之后那个 color type。"""
    blob = path.read_bytes()
    if blob[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"不是 PNG：{path}")
    if blob[12:16] != b"IHDR":
        raise AssertionError(f"首个 chunk 不是 IHDR：{path}")
    width, height = struct.unpack(">II", blob[16:24])
    return width, height, blob[25]


def alpha_bytes(img: Image.Image) -> bytes:
    return img.getchannel("A").tobytes()


def rgb_set(img: Image.Image) -> list[tuple[int, int, int]]:
    """非完全透明像素上出现过的 RGB 取值（去重排序）。"""
    raw = img.convert("RGBA").tobytes()
    return sorted({(raw[i], raw[i + 1], raw[i + 2])
                   for i in range(0, len(raw), 4) if raw[i + 3] > 0})


# --------------------------------------------------------------------------- #
# 资产构建
# --------------------------------------------------------------------------- #
def load_bright(src: Path) -> Image.Image:
    img = Image.open(src)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    return img


def ink_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    box = img.getchannel("A").getbbox()
    if box is None:
        raise AssertionError("brightbg 没有任何 alpha > 0 的像素，取不到墨迹 bbox")
    return box


def build_brand_mark(bright: Image.Image, box, ink) -> Image.Image:
    """裁到墨迹 bbox，保留原 alpha，把 RGB 统一成 ink（黑 / 白）。"""
    crop = bright.crop(box)
    out = Image.new("RGBA", crop.size, ink + (255,))
    out.putalpha(crop.getchannel("A"))     # 只换 RGB，alpha 逐字照搬
    return out


def build_tray_tile(dark: Image.Image) -> Image.Image:
    return dark.resize((TRAY_SIZE, TRAY_SIZE), Image.LANCZOS)


# --------------------------------------------------------------------------- #
# ICO 解码（导出预览用；不用 Pillow 的 ICO 插件）
# --------------------------------------------------------------------------- #
def decode_ico_frame(ico_path: Path, want: int) -> Image.Image:
    """从手搓的 ICO 里取第 want 档，还原成可存 PNG 的 RGBA。

    ico_writer.bmp_entry 写的是 BITMAPINFOHEADER + bottom-up BGRA + 1bpp AND mask，
    biHeight 存的是「图像 + 掩码」两段之和。这里按同一口径反着读。
    """
    blob = ico_path.read_bytes()
    for width, height, _planes, bits, size, offset in ico_entries(str(ico_path)):
        if width != want:
            continue
        if bits != 32:
            raise AssertionError(f"第 {want} 档位深不是 32：{bits}")
        entry = blob[offset : offset + size]
        (
            _bi_size, bi_w, bi_h2, _planes2, bi_bits, bi_comp, _img_size,
            _xppm, _yppm, _used, _imp,
        ) = struct.unpack("<IiiHHIIiiII", entry[:40])
        if bi_bits != 32 or bi_comp != 0:
            raise AssertionError("DIB 不是 32bpp 未压缩")
        h = bi_h2 // 2
        if (bi_w, h) != (width, height):
            raise AssertionError(f"DIB 尺寸 {bi_w}x{h} 与目录项 {width}x{height} 不一致")
        pixels = entry[40 : 40 + bi_w * h * 4]
        mask_off = 40 + bi_w * h * 4
        mask_row = ((bi_w + 31) // 32) * 4
        mask = entry[mask_off : mask_off + mask_row * h]

        out = bytearray(bi_w * h * 4)
        for y in range(h):
            src_row = pixels[(h - 1 - y) * bi_w * 4 : (h - y) * bi_w * 4]   # bottom-up
            mrow = mask[(h - 1 - y) * mask_row : (h - y) * mask_row]
            for x in range(bi_w):
                b, g, r, a = src_row[x * 4 : x * 4 + 4]
                if a == 0:
                    # 32bpp 里 alpha=0 时回到 AND mask：mask 位为 1 ⇒ 透明
                    bit = (mrow[x >> 3] >> (7 - (x & 7))) & 1
                    a = 0 if bit else 255
                i = (y * bi_w + x) * 4
                out[i : i + 4] = bytes((r, g, b, a))
        return Image.frombytes("RGBA", (bi_w, h), bytes(out))
    raise AssertionError(f"ico 里没有 {want} 这一档")


def flatten_on(img: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGB", img.size, bg)
    canvas.paste(img, (0, 0), img)
    return canvas


# --------------------------------------------------------------------------- #
# 主流程
# --------------------------------------------------------------------------- #
def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="actlog aag brand icon generator")
    ap.add_argument("--src-dir", default=str(DEFAULT_ROOT), help="two design PNGs live here")
    ap.add_argument("--out-root", default=str(DEFAULT_ROOT), help="repo root to write products into")
    args = ap.parse_args(argv)

    src_dir = Path(args.src_dir).resolve()
    out_root = Path(args.out_root).resolve()

    src_bright = src_dir / SRC_BRIGHT_NAME
    src_dark = src_dir / SRC_DARK_NAME
    for p in (src_bright, src_dark):
        if not p.is_file():
            raise AssertionError(f"源文件不存在：{p}")

    assets = out_root / "apps" / "desktop" / "assets"
    res = out_root / "apps" / "desktop" / "windows" / "runner" / "resources"
    reports = out_root / "reports"
    for d in (assets, res, reports):
        d.mkdir(parents=True, exist_ok=True)

    p_brand = assets / "brand_mark.png"
    p_brand_dark = assets / "brand_mark_dark.png"
    p_tray = assets / "icon.png"
    p_ico = res / "app_icon.ico"

    bright = load_bright(src_bright)
    dark = Image.open(src_dark)
    if dark.mode != "RGBA":
        dark = dark.convert("RGBA")
    if bright.size != dark.size:
        raise AssertionError(f"两张源图尺寸不同：{bright.size} vs {dark.size}")

    box = ink_bbox(bright)
    mark = build_brand_mark(bright, box, BLACK)
    mark_dark = build_brand_mark(bright, box, WHITE)
    tile = build_tray_tile(dark)

    mark.save(p_brand, format="PNG")
    mark_dark.save(p_brand_dark, format="PNG")
    tile.save(p_tray, format="PNG")
    write_ico(str(p_ico), dark, ICO_SIZES)     # 母版 = darkbg 整幅方形 240x240

    # ---- 预览导出（R5：不能只看数据不看画面） ----
    prev = {}
    for size in (16, 32, 256):
        frame = decode_ico_frame(p_ico, size)
        path = reports / f"task48-ico-preview-{size}.png"
        frame.save(path, format="PNG")
        prev[f"ico{size}"] = path
    path = reports / "task48-brand-mark-preview.png"
    flatten_on(mark, PREVIEW_LIGHT_BG).save(path, format="PNG")
    prev["mark"] = path
    path = reports / "task48-brand-mark-dark-preview.png"
    flatten_on(mark_dark, PREVIEW_DARK_BG).save(path, format="PNG")
    prev["mark_dark"] = path

    # ---- 断言：不满足就是产出坏资产 ----
    for p in (p_brand, p_brand_dark, p_tray):
        w, h, ctype = png_ihdr(p)
        if ctype != 6:
            raise AssertionError(f"{p.name} 的 PNG 颜色类型是 {ctype}，必须是 6（RGBA）")
    if mark.size != mark_dark.size:
        raise AssertionError("brand_mark 与 brand_mark_dark 尺寸不同")
    if alpha_bytes(mark) != alpha_bytes(mark_dark):
        raise AssertionError("brand_mark 与 brand_mark_dark 的 alpha 通道不一致")
    if png_ihdr(p_tray)[:2] != (TRAY_SIZE, TRAY_SIZE):
        raise AssertionError("icon.png 不是 256x256")
    if min(alpha_bytes(tile)) != 255:
        raise AssertionError("icon.png 存在非不透明像素")

    entries = ico_entries(str(p_ico))
    if sorted(e[0] for e in entries) != sorted(ICO_SIZES):
        raise AssertionError(f"ico 档位不是 {ICO_SIZES}：{[e[0] for e in entries]}")
    if any(e[3] != 32 for e in entries):
        raise AssertionError("ico 有非 32bpp 条目")

    # ---- 幂等自证：同一进程内再构建一次，逐字节比 ----
    again = [
        build_brand_mark(bright, box, BLACK).tobytes(),
        build_brand_mark(bright, box, WHITE).tobytes(),
        build_tray_tile(dark).tobytes(),
    ]
    first = [mark.tobytes(), mark_dark.tobytes(), tile.tobytes()]
    idem = all(a == b for a, b in zip(first, again))

    # ---- 实测回读（报告里的数字全部来自这里） ----
    print(f"SRC_BRIGHT  {src_bright} {bright.size[0]}x{bright.size[1]} {src_bright.stat().st_size} B")
    print(f"SRC_DARK    {src_dark} {dark.size[0]}x{dark.size[1]} {src_dark.stat().st_size} B")
    print(f"INK_BBOX    {box} w={box[2] - box[0]} h={box[3] - box[1]} "
          f"ratio={(box[2] - box[0]) / (box[3] - box[1]):.6f}")
    print("")
    for name, p in (("brand_mark.png", p_brand), ("brand_mark_dark.png", p_brand_dark),
                    ("icon.png", p_tray), ("app_icon.ico", p_ico)):
        print(f"PRODUCT {name:22s} bytes={p.stat().st_size:7d} sha16={sha16(p)} path={p}")
    print("")
    for name, p, img in (("brand_mark.png", p_brand, mark),
                         ("brand_mark_dark.png", p_brand_dark, mark_dark),
                         ("icon.png", p_tray, tile)):
        w, h, ctype = png_ihdr(p)
        print(f"PNG {name:22s} {w}x{h} color_type={ctype} has_alpha=1")
    print("")
    a1, a2 = alpha_bytes(mark), alpha_bytes(mark_dark)
    diff = sum(1 for x, y in zip(a1, a2) if x != y)
    print(f"ALPHA_DIFF_PIXELS {diff}")
    print(f"MARK_GEOMETRY_EQUAL {mark.size == mark_dark.size}")
    print(f"MARK_BLACK_RGB {mark.getpixel((mark.size[0] // 2, mark.size[1] // 2))[:3]}")
    print(f"MARK_DARK_RGB  {mark_dark.getpixel((mark_dark.size[0] // 2, mark_dark.size[1] // 2))[:3]}")
    # 非透明像素的 RGB 取值集合（应分别只有一种）
    print(f"MARK_RGB_SET {rgb_set(mark)}")
    print(f"MARK_DARK_RGB_SET {rgb_set(mark_dark)}")
    print("")
    print("ICO_ENTRIES (w, h, planes, bits, bytes, offset)")
    for e in entries:
        print(f"  {e[0]:3d} x {e[1]:3d} planes={e[2]} bits={e[3]} bytes={e[4]:7d} offset={e[5]}")
    print(f"ICO_TIERS_REREAD {[e[0] for e in entries]}")
    print(f"ICO_TIERS_OK {sorted(e[0] for e in entries) == sorted(ICO_SIZES)}")
    print(f"ICO_ALL_32BPP {all(e[3] == 32 for e in entries)}")
    print("")
    corners = [(0, 0), (TRAY_SIZE - 1, 0), (0, TRAY_SIZE - 1), (TRAY_SIZE - 1, TRAY_SIZE - 1)]
    print(f"TRAY_CORNERS " + " ".join(f"{c}:{tile.getpixel(c)[3]}" for c in corners))
    print(f"TRAY_MIN_ALPHA {min(alpha_bytes(tile))}")
    print("")
    print(f"IDEMPOTENT_INPROC {1 if idem else 0}")
    print("")
    print("PREVIEWS")
    for key, p in prev.items():
        w, h, ctype = png_ihdr(p)
        print(f"  {p} {w}x{h} color_type={ctype} {p.stat().st_size} B exists={p.is_file()}")
    print("AAG_ICON_DONE")
    return 0 if idem else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))