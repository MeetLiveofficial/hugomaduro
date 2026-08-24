"""Crop and export ranking podium assets (frame + banner) from Downloads."""
from PIL import Image

src_dir = r"C:\Users\Asus\Downloads\ranking"
out_dir = r"C:\laragon\www\nexus_krimson\nexus_rs_app\assets\icons"
MAX_SIDE = 900


def content_bbox(im, a=12, pad=8):
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > a:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    return (
        max(0, minx - pad),
        max(0, miny - pad),
        min(w, maxx + 1 + pad),
        min(h, maxy + 1 + pad),
    )


def knock_near_black(im, thresh=10):
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and max(r, g, b) <= thresh:
                px[x, y] = (0, 0, 0, 0)
    return im


for i in (1, 2, 3):
    im = Image.open(fr"{src_dir}\{i}.png").convert("RGBA")
    im = knock_near_black(im)
    im = im.crop(content_bbox(im))
    w, h = im.size
    scale = MAX_SIDE / max(w, h)
    if scale < 1:
        im = im.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
    dst = fr"{out_dir}\ic_rank_podium_{i}.png"
    im.save(dst, "PNG", optimize=True, compress_level=9)
    print(f"OK podium {i}: {im.size} -> {dst}")
