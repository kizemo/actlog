# -*- coding: utf-8 -*-
"""actlog 品牌应用图标生成器（Task 32 · 2026-11-11；Task 33 改名）。

母版 = [`Set I / I03`](../../design-demos/logo-set-i-bowl-overlap-2026-11-11/README.md)
用户 2026-11-11 拍板：叠 36 · 无 halo 硬压 · 碗 = 深蓝 #0E2A4A · 纸底片。

为什么不是整条 wordmark：Set I README 实测「32 行三稿全部糊成一团」「任何一稿在 32px
都读不出叠印」，而任务栏 / 托盘 / 快捷方式的实际渲染档是 16–40px ⇒ 整条字标做图标必然糊。
因此取 I03 的**签名部件「a」= 深蓝碗压墨色竖干**（正是本轮用户要求的「压住竖线」那一对部件），
等比放大居中到同一张纸底片 tile。叠量关系（碗右缘越过竖干左缘 36 / 描边 48 / 两色）
逐字继承 I03，**只改取景与缩放**，不改任何部件形状、颜色、层序。

产物（默认只落 reports/task32-icon/ 暂存，控制器可写；--apps 才写进 apps/desktop，
那是 worker 的写集，AGENTS.md §2 R1）：
  brand-icon.svg          矢量母版（1024 tile）
  brand-icon.png          1024 光栅母版（Edge 无头出图）
  app_icon.ico            9 档 16/20/24/32/40/48/64/128/256 -> windows/runner/resources
  icon.png                256                        -> assets（托盘）
  sizes.png               真尺寸取证矩阵（浅底 + 深底两排）
  manifest.txt            字节数 / sha256 / ICO 档位复读

本机坑（沿用，勿重试）：不用 Pillow 的 ICO 插件（import 会拉进坏 olefile 并 abort），
ICO 容器复用 tools/icons/ico_writer.py 的手搓写法（Task 33 从遗留的
make_app_icon.py 里独立出来，好让遗留脚本彻底零引用、不再是发布链路输入）；
出图复用 Set H 的 edge_shot。
"""
import datetime
import hashlib
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, r"F:\soft\00selfmade\practilog\tools\icons")
sys.path.insert(0, r"F:\soft\00selfmade\practilog\design-demos\logo-set-h-alog-playtriangle-2026-11-11")

from PIL import Image                                    # noqa: E402
from ico_writer import write_ico, ico_entries              # noqa: E402
import build_alog_h as H                                 # noqa: E402  edge_shot / PAPER / INK

ROOT = Path(r"F:\soft\00selfmade\practilog")
SET_I = ROOT / "design-demos" / "logo-set-i-bowl-overlap-2026-11-11"
SOURCE_SVG = SET_I / "I03-bowl36-navy-hard-plate.svg"
STAGE = ROOT / "reports" / "task32-icon"

W = 1024
NAVY = "#0E2A4A"          # I03 新增深蓝（用户当轮决定，覆盖 TOKENS.md 两色契约）
STROKE = 48               # 与 I03 逐字同值
HALF = STROKE / 2
FIT = 700                 # 部件在 tile 内的最长边目标（≈ tile 的 68%）
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)
PNG_TRAY = 256

# I03 的「a」两个部件（竖干 + 碗）。数值必须与 SOURCE_SVG 逐字一致，下面有断言。
STEM_X, STEM_Y1, STEM_Y2 = 383.0, 396.0, 535.0
BOWL_CX, BOWL_CY, BOWL_R = 313.0, 474.0, 58.0


def check_source():
    """断言取景用的几何常量确实来自 I03 纸底片母版（源稿漂移就报错，不静默出错图）。"""
    txt = SOURCE_SVG.read_text(encoding="utf-8")
    must = [
        f'x="0" y="0" width="{W}" height="{W}" rx="64" fill="{H.PAPER}"',
        f'<path d="M {STEM_X} {STEM_Y1} L {STEM_X} {STEM_Y2}"/>',
        f'<circle cx="{BOWL_CX}" cy="{BOWL_CY:.0f}" r="{BOWL_R:.0f}"/>',
        f'stroke="{H.INK}"',
        f'stroke="{NAVY}"',
    ]
    for frag in must:
        if frag not in txt:
            raise AssertionError(f"I03 母版与预期常量不符，缺：{frag}")
    # 碗必须在竖干之后绘制（硬压的 z-order），且叠量 36 仍成立
    if txt.index("L 383.0 535.0") > txt.index('cx="313.0"'):
        raise AssertionError("I03 母版层序变了：竖干画在碗之后 ⇒ 不再是硬压")
    if abs((BOWL_CX + BOWL_R + HALF) - (STEM_X - HALF + 36.0)) > 0.01:
        raise AssertionError("I03 叠量不再是 36（碗外廓右缘越过竖干左缘的距离变了）")


def crop_box():
    """「a」的着墨外廓（round cap 与碗描边各外扩 HALF）。"""
    x1 = min(STEM_X - HALF, BOWL_CX - BOWL_R - HALF)
    x2 = max(STEM_X + HALF, BOWL_CX + BOWL_R + HALF)
    y1 = min(STEM_Y1 - HALF, BOWL_CY - BOWL_R - HALF)
    y2 = max(STEM_Y2 + HALF, BOWL_CY + BOWL_R + HALF)
    return x1, y1, x2, y2


def tile_svg():
    x1, y1, x2, y2 = crop_box()
    bw, bh = x2 - x1, y2 - y1
    s = min(FIT / bw, FIT / bh)
    cx, cy = (x1 + x2) / 2.0, (y1 + y2) / 2.0
    tx, ty = W / 2.0 - cx * s, W / 2.0 - cy * s
    tf = f"translate({tx:.3f},{ty:.3f}) scale({s:.6f})"
    body = (
        f'<g transform="{tf}" fill="none" stroke-linecap="round" stroke-linejoin="round">'
        f'<path d="M {STEM_X} {STEM_Y1} L {STEM_X} {STEM_Y2}" '
        f'stroke="{H.INK}" stroke-width="{STROKE}"/>'
        f'<circle cx="{BOWL_CX}" cy="{BOWL_CY:.0f}" r="{BOWL_R:.0f}" '
        f'stroke="{NAVY}" stroke-width="{STROKE}"/>'
        f"</g>"
    )
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {W}" '
           f'width="{W}" height="{W}">'
           f'<rect x="0" y="0" width="{W}" height="{W}" rx="64" fill="{H.PAPER}"/>'
           f"{body}</svg>")
    return svg, dict(scale=s, box=(x1, y1, x2, y2), mark=(bw * s, bh * s), tf=tf)


def sizes_matrix(master, path):
    """真尺寸取证图：浅底与深底两排，各档按实际像素贴出。"""
    tiers = [16, 20, 24, 32, 40, 48, 64, 128, 256]
    row_h = 256 + 24
    pad = 24
    width = pad * 2 + sum(tiers) + pad * (len(tiers) - 1)
    canvas = Image.new("RGB", (width, row_h * 2 + pad * 3), (128, 128, 128))
    for r, bg in enumerate(((232, 232, 232), (24, 24, 24))):
        y = pad + r * (row_h + pad)
        band = Image.new("RGB", (width, row_h), bg)
        x = pad
        for t in tiers:
            im = master.resize((t, t), Image.LANCZOS).convert("RGBA")
            band.paste(im, (x, (row_h - t) // 2), im)
            x += t + pad
        canvas.paste(band, (0, y))
    canvas.save(path, format="PNG")


def sha16(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16].upper()


def main():
    argv = sys.argv[1:]
    to_apps = "--apps" in argv
    check_source()
    STAGE.mkdir(parents=True, exist_ok=True)

    svg, meta = tile_svg()
    svg_path = STAGE / "brand-icon.svg"
    svg_path.write_text(svg, encoding="utf-8")

    png_path = STAGE / "brand-icon.png"
    H.edge_shot(svg_path, png_path, W, W, bg=None)
    master = Image.open(png_path).convert("RGBA")
    if master.size != (W, W):
        raise AssertionError(f"母版尺寸不是 {W}x{W}：{master.size}")

    ico_path = STAGE / "app_icon.ico"
    written = write_ico(str(ico_path), master, ICO_SIZES)
    entries = ico_entries(str(ico_path))

    tray_path = STAGE / "icon.png"
    master.resize((PNG_TRAY, PNG_TRAY), Image.LANCZOS).save(tray_path, format="PNG")

    matrix = STAGE / "sizes.png"
    sizes_matrix(master, matrix)

    if to_apps:
        ico_dst = ROOT / "apps/desktop/windows/runner/resources/app_icon.ico"
        png_dst = ROOT / "apps/desktop/assets/icon.png"
        ico_dst.parent.mkdir(parents=True, exist_ok=True)
        png_dst.parent.mkdir(parents=True, exist_ok=True)
        import shutil
        shutil.copyfile(ico_path, ico_dst)
        shutil.copyfile(tray_path, png_dst)
        print(f"APPS ico -> {ico_dst} ({ico_dst.stat().st_size} B) sha={sha16(ico_dst)}")
        print(f"APPS png -> {png_dst} ({png_dst.stat().st_size} B) sha={sha16(png_dst)}")

    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        f"make_brand_icon.py · {stamp} · --apps={to_apps}",
        f"source      = {SOURCE_SVG}",
        f"crop box    = {meta['box']}  scale = {meta['scale']:.6f}",
        f"mark in tile = {meta['mark'][0]:.1f} x {meta['mark'][1]:.1f} of {W}",
        f"master      = {png_path} {master.size} {png_path.stat().st_size} B sha={sha16(png_path)}",
        f"ico         = {ico_path} {ico_path.stat().st_size} B sha={sha16(ico_path)}",
        f"ico tiers   = {written}",
        f"ico re-read = {entries}",
        f"tray png    = {tray_path} {tray_path.stat().st_size} B sha={sha16(tray_path)}",
        f"matrix      = {matrix} {matrix.stat().st_size} B",
        f"struct      = {struct.unpack('<HHH', ico_path.read_bytes()[:6])}",
    ]
    (STAGE / "manifest.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print("BRAND_ICON_DONE")


if __name__ == "__main__":
    main()
