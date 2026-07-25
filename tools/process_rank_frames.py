from PIL import Image
import os

src_dir = r'C:\Users\Asus\.cursor\projects\c-laragon-www-nexus-krimson-nexus-rs\assets'
out = r'C:\laragon\www\nexus_krimson\nexus_rs_app\assets\icons'


def find_src(level: int) -> str:
    for name in os.listdir(src_dir):
        if f'game_ranking_badges_lvl_{level}' in name.lower():
            return os.path.join(src_dir, name)
    return os.path.join(out, f'ic_rank_frame_{level}.png')


def make_transparent_bg(im: Image.Image, thresh=28) -> Image.Image:
    """Solo negro casi puro → transparente. Conserva plata/gris del marco 3."""
    im = im.convert('RGBA')
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            mx = max(r, g, b)
            mn = min(r, g, b)
            # negro puro / casi negro
            if mx <= thresh:
                px[x, y] = (0, 0, 0, 0)
            # blanco puro (artefactos)
            elif mn >= 250 and a > 160:
                px[x, y] = (0, 0, 0, 0)
    return im


def content_bbox(im: Image.Image, alpha_min=8):
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > alpha_min:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if maxx < 0:
        return (0, 0, w, h)
    pad = 6
    return (
        max(0, minx - pad),
        max(0, miny - pad),
        min(w, maxx + 1 + pad),
        min(h, maxy + 1 + pad),
    )


def cut_hole(im: Image.Image, hole_r_ratio: float, cy_shift: float):
    px = im.load()
    w, h = im.size
    cx, cy = w / 2, h / 2 + cy_shift * h
    hole_r = min(w, h) * hole_r_ratio
    for y in range(h):
        for x in range(w):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d < hole_r - 1.5:
                px[x, y] = (0, 0, 0, 0)
            elif d < hole_r + 1.0:
                r, g, b, a = px[x, y]
                t = (d - (hole_r - 1.5)) / 2.5
                px[x, y] = (r, g, b, int(a * max(0.0, min(1.0, t))))
    return im


def to_square(im: Image.Image) -> Image.Image:
    w, h = im.size
    side = max(w, h)
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - w) // 2, (side - h) // 2), im)
    return canvas


# level, hole ratio, cy shift
# hole ratio = radio / min(lado); diámetro del hueco ≈ 2*ratio
configs = [
    (1, 0.34, 0.02),
    (2, 0.36, 0.01),
    (3, 0.28, -0.02),  # anillo fino: hueco más chico para no comer el chrome
]

for level, hole, cy in configs:
    src = find_src(level)
    im = make_transparent_bg(Image.open(src))
    im = im.crop(content_bbox(im))
    im = to_square(im)
    side = max(320, im.size[0] * 2)  # upscale para nitidez
    im = im.resize((side, side), Image.Resampling.LANCZOS)
    im = cut_hole(im, hole, cy)
    dst = os.path.join(out, f'ic_rank_frame_{level}.png')
    im.save(dst, 'PNG')
    opaque = sum(1 for p in im.getdata() if p[3] > 20)
    print(f'OK frame{level}: {im.size} opaque_px={opaque}')

print('done')
