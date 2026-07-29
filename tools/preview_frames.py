from PIL import Image

for i in (1, 2, 3):
    im = Image.open(
        rf'C:\laragon\www\nexus_krimson\nexus_rs_app\assets\icons\ic_rank_frame_{i}.png'
    )
    w, h = im.size
    chk = Image.new('RGBA', (w, h), (200, 200, 200, 255))
    px = chk.load()
    for y in range(h):
        for x in range(w):
            if ((x // 16) + (y // 16)) % 2 == 0:
                px[x, y] = (160, 160, 160, 255)
    chk.alpha_composite(im)
    out = rf'C:\laragon\www\nexus_krimson\nexus_rs_app\tools\preview_frame_{i}.jpg'
    chk.convert('RGB').save(out, quality=90)
    print('saved', out)
