"""Rıza Bey tanıtım reel'i — REEL-SENARYO.md'ye göre düz çizim animasyon.
Kullanım: python3 render.py cikti.mp4
"""
import math
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

W, H, FPS = 720, 1280, 30
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
_fonts = {}


def font(size, bold=True):
    key = (size, bold)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(BOLD if bold else REG, size)
    return _fonts[key]


SKY_TOP, SKY_BOT = (120, 190, 240), (190, 228, 250)
GRASS = (108, 191, 90)
GRASS_DARK = (92, 170, 76)
ROAD = (90, 90, 96)
YELLOW = (255, 210, 63)
RED = (230, 57, 70)
GREEN = (46, 196, 102)
DARK = (34, 34, 40)
WHITE = (255, 255, 255)
BLUE = (52, 120, 246)


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def lerp(a, b, t):
    return a + (b - a) * t


# ---------- çizim yardımcıları ----------

def background(img, horizon=820):
    d = ImageDraw.Draw(img)
    for y in range(horizon):
        t = y / horizon
        c = tuple(int(lerp(SKY_TOP[i], SKY_BOT[i], t)) for i in range(3))
        d.line([(0, y), (W, y)], fill=c)
    d.rectangle([0, horizon, W, H], fill=GRASS)
    for i in range(0, W, 80):
        d.rectangle([i, horizon, i + 40, H], fill=GRASS_DARK)
    d.rectangle([0, horizon + 120, W, horizon + 220], fill=ROAD)
    for x in range(0, W, 90):
        d.rectangle([x + 10, horizon + 166, x + 60, horizon + 174], fill=WHITE)


def tree(d, x, y, s=1.0):
    d.rectangle([x - 8 * s, y - 40 * s, x + 8 * s, y], fill=(110, 80, 50))
    d.ellipse([x - 45 * s, y - 120 * s, x + 45 * s, y - 30 * s], fill=(52, 140, 60))
    d.ellipse([x - 30 * s, y - 140 * s, x + 25 * s, y - 80 * s], fill=(66, 160, 72))


def house(d, x, y, w=200, h=160, color=(245, 230, 200)):
    d.rectangle([x, y - h, x + w, y], fill=color, outline=DARK, width=3)
    d.polygon([(x - 20, y - h), (x + w / 2, y - h - 90), (x + w + 20, y - h)], fill=(196, 72, 60), outline=DARK)
    d.rectangle([x + w / 2 - 22, y - 70, x + w / 2 + 22, y], fill=(120, 80, 50))
    for wx in (x + 20, x + w - 60):
        d.rectangle([wx, y - h + 25, wx + 40, y - h + 65], fill=(170, 210, 240), outline=DARK, width=2)


def school(d, x, y, w=260, h=220):
    d.rectangle([x, y - h, x + w, y], fill=(240, 200, 120), outline=DARK, width=3)
    d.rectangle([x - 10, y - h - 20, x + w + 10, y - h], fill=(200, 90, 60), outline=DARK)
    tw = d.textlength("OKUL", font=font(34))
    d.text((x + w / 2 - tw / 2, y - h + 10), "OKUL", font=font(34), fill=DARK)
    for i in range(3):
        wx = x + 25 + i * 80
        d.rectangle([wx, y - h + 60, wx + 50, y - h + 110], fill=(170, 210, 240), outline=DARK, width=2)
    d.rectangle([x + w / 2 - 30, y - 90, x + w / 2 + 30, y], fill=(120, 80, 50))


def person(d, x, y, s=1.0, shirt=(70, 130, 220), bag=True, phone=False):
    # y = ayak hizası
    leg = 50 * s
    d.line([(x - 10 * s, y), (x, y - leg)], fill=DARK, width=int(8 * s))
    d.line([(x + 10 * s, y), (x, y - leg)], fill=DARK, width=int(8 * s))
    d.rounded_rectangle([x - 24 * s, y - leg - 70 * s, x + 24 * s, y - leg], radius=int(12 * s), fill=shirt)
    if bag:
        d.rounded_rectangle([x - 36 * s, y - leg - 64 * s, x - 18 * s, y - leg - 14 * s], radius=int(6 * s), fill=RED)
    hy = y - leg - 70 * s
    d.ellipse([x - 22 * s, hy - 46 * s, x + 22 * s, hy - 2 * s], fill=(240, 200, 160), outline=DARK, width=2)
    d.chord([x - 23 * s, hy - 48 * s, x + 23 * s, hy - 14 * s], 180, 360, fill=(70, 45, 30))
    if phone:
        d.rounded_rectangle([x + 20 * s, y - leg - 52 * s, x + 36 * s, y - leg - 24 * s], radius=3, fill=DARK)
    return (x + 28 * s, y - leg - 40 * s)  # telefonun konumu


def cloud(d, cx, cy, s=1.0, fill=WHITE):
    for dx, dy, r in [(-90, 10, 60), (-30, -30, 80), (50, -10, 70), (100, 20, 50), (0, 30, 60)]:
        d.ellipse([cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], fill=fill)


def pin(d, x, y, s=1.0, color=RED):
    d.ellipse([x - 16 * s, y - 46 * s, x + 16 * s, y - 14 * s], fill=color)
    d.polygon([(x - 13 * s, y - 24 * s), (x + 13 * s, y - 24 * s), (x, y)], fill=color)
    d.ellipse([x - 6 * s, y - 36 * s, x + 6 * s, y - 24 * s], fill=WHITE)


def phone(d, x, y, w, h, title=None):
    d.rounded_rectangle([x, y, x + w, y + h], radius=int(w * 0.12), fill=DARK)
    m = max(6, int(w * 0.05))
    d.rounded_rectangle([x + m, y + m * 2, x + w - m, y + h - m * 2], radius=int(w * 0.06), fill=(250, 250, 252))
    if title:
        f = font(max(14, int(w * 0.11)))
        tw = d.textlength(title, font=f)
        d.text((x + w / 2 - tw / 2, y + m * 2 + 6), title, font=f, fill=DARK)
    return (x + m, y + m * 2, x + w - m, y + h - m * 2)


def outlined_text(d, cx, cy, text, size, fill=WHITE, stroke=6):
    f = font(size)
    tw = d.textlength(text, font=f)
    d.text((cx - tw / 2, cy - size / 2), text, font=f, fill=fill, stroke_width=stroke, stroke_fill=(0, 0, 0))


def title_card(d, lines, y=70, size=46, alpha_t=1.0):
    f = font(size)
    widths = [d.textlength(l, font=f) for l in lines]
    bw = max(widths) + 60
    bh = len(lines) * (size + 14) + 40
    x0 = W / 2 - bw / 2
    off = (1 - ease(alpha_t)) * -300
    d.rounded_rectangle([x0, y + off, x0 + bw, y + bh + off], radius=14, fill=(40, 40, 48))
    for i, l in enumerate(lines):
        d.text((W / 2 - widths[i] / 2, y + 20 + i * (size + 14) + off), l, font=f, fill=WHITE)


def label(d, cx, cy, text, t, size=52, color=YELLOW):
    if t <= 0:
        return
    s = 0.6 + 0.4 * ease(t * 3)
    outlined_text(d, cx, cy, text, int(size * s), fill=color, stroke=5)


def overlay_alpha(img, draw_fn):
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(ov))
    img.alpha_composite(ov)


def dashed(d, p0, p1, color, width=6, dash=18, gap=14, phase=0.0):
    x0, y0 = p0
    x1, y1 = p1
    L = math.hypot(x1 - x0, y1 - y0)
    if L == 0:
        return
    ux, uy = (x1 - x0) / L, (y1 - y0) / L
    pos = -phase % (dash + gap)
    pos -= dash + gap
    while pos < L:
        a, b = max(0, pos), min(L, pos + dash)
        if b > a:
            d.line([(x0 + ux * a, y0 + uy * a), (x0 + ux * b, y0 + uy * b)], fill=color, width=width)
        pos += dash + gap


def along(path, u):
    """path üzerinde 0..1 arası nokta."""
    segs = [(path[i], path[i + 1]) for i in range(len(path) - 1)]
    lens = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in segs]
    total = sum(lens)
    dist = clamp(u) * total
    for (a, b), L in zip(segs, lens):
        if dist <= L:
            k = dist / L if L else 0
            return (lerp(a[0], b[0], k), lerp(a[1], b[1], k))
        dist -= L
    return path[-1]


# ---------- harita (telefon içi) ----------

def map_screen(img, box, t, path, dot_u, show_zone=False, zone_t=0.0, notif_t=0.0):
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(img)
    d.rectangle(box, fill=(238, 234, 222))
    # park ve nehir
    d.rounded_rectangle([x0 + 30, y0 + 520, x0 + 200, y0 + 700], radius=20, fill=(170, 220, 150))
    d.polygon([(x1, y0 + 120), (x1 - 90, y0 + 260), (x1 - 60, y0 + 420), (x1, y0 + 470)], fill=(160, 205, 240))
    # sokaklar
    for gx in range(int(x0) + 60, int(x1), 140):
        d.line([(gx, y0), (gx, y1)], fill=WHITE, width=18)
    for gy in range(int(y0) + 90, int(y1), 160):
        d.line([(x0, gy), (x1, gy)], fill=WHITE, width=18)
    # ev
    hx, hy = path[0]
    d.rounded_rectangle([hx - 26, hy - 26, hx + 26, hy + 26], radius=8, fill=(196, 72, 60))
    d.text((hx - 10, hy - 16), "⌂", font=font(28), fill=WHITE)
    # okul
    sx, sy = path[-1]
    if show_zone:
        r = 110 * ease(zone_t * 2)
        overlay_alpha(img, lambda o: o.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(46, 196, 102, 70), outline=(46, 196, 102, 255), width=5))
        d = ImageDraw.Draw(img)
    d.rounded_rectangle([sx - 30, sy - 30, sx + 30, sy + 30], radius=8, fill=(240, 170, 60))
    d.text((sx - 13, sy - 18), "O", font=font(30), fill=DARK)
    # rota
    done = []
    steps = 60
    for i in range(steps + 1):
        u = i / steps * dot_u
        done.append(along(path, u))
    if len(done) > 1:
        d.line(done, fill=BLUE, width=8, joint="curve")
    px, py = along(path, dot_u)
    pr = 26 + 10 * math.sin(t * 6)
    overlay_alpha(img, lambda o: o.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(52, 120, 246, 70)))
    d = ImageDraw.Draw(img)
    d.ellipse([px - 16, py - 16, px + 16, py + 16], fill=BLUE, outline=WHITE, width=4)
    # bildirim
    if notif_t > 0:
        off = lerp(-160, 0, ease(notif_t * 3))
        d.rounded_rectangle([x0 + 16, y0 + 16 + off, x1 - 16, y0 + 126 + off], radius=18, fill=WHITE, outline=(200, 200, 205), width=2)
        d.ellipse([x0 + 34, y0 + 42 + off, x0 + 90, y0 + 98 + off], fill=GREEN)
        d.text((x0 + 46, y0 + 46 + off), "✓", font=font(40), fill=WHITE)
        d.text((x0 + 106, y0 + 34 + off), "Rıza Bey", font=font(24), fill=(120, 120, 128))
        d.text((x0 + 106, y0 + 66 + off), "FM okula vardı", font=font(32), fill=DARK)


# ---------- sahneler ----------

def s_hook(img, t, dur):
    background(img)
    d = ImageDraw.Draw(img)
    tree(d, 640, 820, 1.1)
    school(d, 40, 820)
    kx = lerp(170, 470, ease(t / dur))
    person(d, kx, 900, 1.3, bag=True, phone=True)
    title_card(d, ["Çocuğumun konumu", "telefonuma nasıl", "geliyor?"], y=90, size=50, alpha_t=t * 2)


def s_wrong(img, t, dur):
    background(img)
    d = ImageDraw.Draw(img)
    house(d, 40, 820)
    # modem
    mx, my = 200, 780
    d.rounded_rectangle([mx - 34, my - 22, mx + 34, my + 10], radius=6, fill=DARK)
    d.line([(mx - 20, my - 22), (mx - 30, my - 60)], fill=DARK, width=4)
    d.line([(mx + 20, my - 22), (mx + 30, my - 60)], fill=DARK, width=4)
    kx = lerp(330, 620, ease((t - 1.0) / 5.0))
    ph = person(d, kx, 900, 1.3, phone=True)
    broken = t > 4.6
    if not broken:
        d.ellipse([mx + 18, my - 12, mx + 28, my - 2], fill=GREEN if int(t * 4) % 2 else (20, 120, 60))
        dashed(d, ph, (mx, my - 10), GREEN, phase=t * 60)
    else:
        d.ellipse([mx + 18, my - 12, mx + 28, my - 2], fill=RED)
        midx, midy = (ph[0] + mx) / 2, (ph[1] + my) / 2
        dashed(d, (mx, my - 10), (midx - 30, midy), RED)
        dashed(d, (midx + 30, midy), ph, RED)
        d.line([(midx - 22, midy - 22), (midx + 22, midy + 22)], fill=RED, width=10)
        d.line([(midx - 22, midy + 22), (midx + 22, midy - 22)], fill=RED, width=10)
        label(d, W / 2, 300, "BAĞLANTI YOK", t - 4.6, size=60, color=RED)
    label(d, W / 2, 190, "EVDEKİ SUNUCU", t - 0.3)


def s_cloud(img, t, dur):
    background(img)
    d = ImageDraw.Draw(img)
    cs = ease(t * 1.5)
    cloud(d, W / 2, 260, 1.15 * cs)
    if t > 0.7:
        label(d, W / 2, 265, "BULUT", t - 0.7, size=56)
    b1 = phone(d, 60, 620, 190, 340, "FM")
    b2 = phone(d, 470, 620, 190, 340, "Maps")
    pin(d, (b1[0] + b1[2]) / 2, (b1[1] + b1[3]) / 2 + 40, 1.5)
    pin(d, (b2[0] + b2[2]) / 2, (b2[1] + b2[3]) / 2 + 40, 1.5, BLUE)
    label(d, 155, 1010, "KONUM", t - 1.5, size=44)
    if t > 2.0:
        up = [(155, 620), (W / 2 - 40, 330)]
        down = [(W / 2 + 40, 330), (565, 620)]
        dashed(d, up[0], up[1], WHITE, width=5, phase=t * 50)
        dashed(d, down[0], down[1], WHITE, width=5, phase=t * 50)
        for k in range(4):
            u = ((t - 2.0) * 0.6 + k / 4) % 1.0
            p = along(up, u * 2) if u < 0.5 else along(down, (u - 0.5) * 2)
            d.ellipse([p[0] - 13, p[1] - 13, p[0] + 13, p[1] + 13], fill=YELLOW, outline=DARK, width=2)
    if t > 6.5:
        label(d, W / 2, 520, "HER YERDE", t - 6.5, size=50, color=WHITE)


MAP_PATH_REL = [(0.22, 0.23), (0.22, 0.48), (0.62, 0.48), (0.62, 0.72), (0.78, 0.72)]


def big_phone(img):
    d = ImageDraw.Draw(img)
    return phone(d, 110, 140, 500, 960)


def to_abs(box, rel):
    x0, y0, x1, y1 = box
    return [(lerp(x0, x1, a), lerp(y0, y1, b)) for a, b in rel]


def s_map(img, t, dur):
    img.paste((150, 200, 240), [0, 0, W, H])
    box = big_phone(img)
    path = to_abs(box, MAP_PATH_REL)
    u = 0.65 * ease(t / (dur - 1))
    map_screen(img, box, t, path, u)
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    d.rounded_rectangle([x0 + 16, y1 - 140, x1 - 16, y1 - 16], radius=18, fill=WHITE, outline=(200, 200, 205), width=2)
    d.ellipse([x0 + 34, y1 - 118, x0 + 114, y1 - 38], fill=BLUE)
    d.text((x0 + 56, y1 - 104), "FM", font=font(30), fill=WHITE)
    d.text((x0 + 132, y1 - 120), "FM · Yolda", font=font(32), fill=DARK)
    batt = int(lerp(78, 74, t / dur))
    d.text((x0 + 132, y1 - 78), f"Pil %{batt}  ·  şimdi", font=font(26, False), fill=(110, 110, 118))
    label(d, W / 2, 1180, "CANLI HARİTA", t - 0.5)


def s_zone(img, t, dur):
    img.paste((150, 200, 240), [0, 0, W, H])
    box = big_phone(img)
    path = to_abs(box, MAP_PATH_REL)
    u = lerp(0.65, 1.0, ease((t - 0.5) / 3.5))
    notif = t - 4.3 if t > 4.3 else 0
    map_screen(img, box, t, path, u, show_zone=True, zone_t=t, notif_t=notif)
    d = ImageDraw.Draw(img)
    label(d, W / 2, 1180, "GÜVENLİ BÖLGE", t - 0.3)


def s_trust(img, t, dur):
    background(img)
    d = ImageDraw.Draw(img)
    tree(d, 80, 820, 1.2)
    person(d, 200, 1000, 2.2, phone=False, bag=True)
    box = phone(d, 330, 330, 330, 600)
    x0, y0, x1, y1 = box
    off = lerp(-140, 0, ease(t * 2))
    d.rounded_rectangle([x0 + 12, y0 + 40 + off, x1 - 12, y0 + 150 + off], radius=16, fill=(235, 240, 250), outline=(200, 200, 210), width=2)
    pin(d, x0 + 50, y0 + 120 + off, 1.0)
    d.text((x0 + 80, y0 + 56 + off), "FM", font=font(22), fill=(110, 110, 118))
    d.text((x0 + 80, y0 + 86 + off), "Konum", font=font(26), fill=DARK)
    d.text((x0 + 80, y0 + 116 + off), "paylaşılıyor", font=font(26), fill=DARK)
    label(d, W / 2, 200, "AÇIK VE GÖRÜNÜR", t - 1.0, size=50)


def mascot(d, cx, cy, s, t):
    bob = math.sin(t * 6) * 12
    cy += bob
    d.polygon([(cx - 140 * s, cy - 40 * s), (cx, cy - 170 * s), (cx + 140 * s, cy - 40 * s)], fill=(196, 72, 60), outline=DARK)
    d.rounded_rectangle([cx - 110 * s, cy - 40 * s, cx + 110 * s, cy + 150 * s], radius=int(24 * s), fill=YELLOW, outline=DARK, width=4)
    for ex in (-45, 45):
        d.ellipse([cx + (ex - 20) * s, cy + 10 * s, cx + (ex + 20) * s, cy + 50 * s], fill=WHITE, outline=DARK, width=3)
        d.ellipse([cx + (ex - 8) * s, cy + 22 * s, cx + (ex + 8) * s, cy + 40 * s], fill=DARK)
    d.arc([cx - 50 * s, cy + 40 * s, cx + 50 * s, cy + 110 * s], 20, 160, fill=DARK, width=6)
    pin(d, cx + 150 * s, cy - 60 * s, 1.6 * s)


def s_end(img, t, dur):
    background(img)
    d = ImageDraw.Draw(img)
    house(d, 470, 820, 200, 150)
    mascot(d, W / 2 - 60, 560, 1.0 * (0.5 + 0.5 * ease(t * 2)), t)
    outlined_text(d, W / 2, 180, "Artık biliyorsun!", 60, fill=WHITE)
    if t > 1.2:
        a = ease((t - 1.2) * 2)
        d.rounded_rectangle([90, 1050 + 60 * (1 - a), W - 90, 1170 + 60 * (1 - a)], radius=20, fill=DARK)
        tw = d.textlength("Rıza Bey · Aile Konum", font=font(40))
        d.text((W / 2 - tw / 2, 1085 + 60 * (1 - a)), "Rıza Bey · Aile Konum", font=font(40), fill=WHITE)


SCENES = [
    (s_hook, 4.0, "Çocuğun okuldan çıktı. Nerede olduğunu nasıl bilirsin?"),
    (s_wrong, 9.0, "Konum sadece evdeki sunucuya giderse çocuk evden çıkınca sinyal kopar"),
    (s_cloud, 10.0, "FM konumu mobil veriyle buluta gönderir. Maps buluttan okur. Evde okulda yolda"),
    (s_map, 8.0, "Haritada canlı görürsün. Pil azalınca da haber verir"),
    (s_zone, 8.0, "Okula ya da eve girip çıkınca bildirim gelir"),
    (s_trust, 6.0, "Çocuk da bilir: paylaşım açık ve görünür"),
    (s_end, 5.0, ""),
]


def subtitle(img, words, t, dur):
    if not words:
        return
    span = (dur - 0.3) / len(words)
    i = min(len(words) - 1, int(t / span))
    d = ImageDraw.Draw(img)
    w = words[i].strip(".,:?")
    pop = 0.85 + 0.15 * ease((t - i * span) / 0.12)
    outlined_text(d, W / 2, 1080 if words is not None else 0, w, int(66 * pop))


def frames():
    for fn, dur, text in SCENES:
        words = text.split()
        n = int(dur * FPS)
        for f in range(n):
            t = f / FPS
            img = Image.new("RGBA", (W, H), (255, 255, 255, 255))
            fn(img, t, dur)
            if fn not in (s_map, s_zone):
                subtitle(img, words, t, dur)
            else:
                subtitle_top(img, words, t, dur)
            if t < 0.25:
                fade = int(255 * (1 - t / 0.25))
                img.alpha_composite(Image.new("RGBA", (W, H), (255, 255, 255, fade)))
            yield img.convert("RGB").tobytes()


def subtitle_top(img, words, t, dur):
    span = (dur - 0.3) / len(words)
    i = min(len(words) - 1, int(t / span))
    d = ImageDraw.Draw(img)
    pop = 0.85 + 0.15 * ease((t - i * span) / 0.12)
    outlined_text(d, W / 2, 70, words[i].strip(".,:?"), int(60 * pop))


def main(out):
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium", "-movflags", "+faststart", out]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for fr in frames():
        p.stdin.write(fr)
    p.stdin.close()
    p.wait()


if __name__ == "__main__":
    main(sys.argv[1])
