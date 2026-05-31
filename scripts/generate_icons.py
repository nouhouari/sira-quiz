#!/usr/bin/env python3
"""
Generate app_icon.png and app_icon_foreground.png for the Sîra Quiz app.

Design:
  - Background: vertical emerald gradient #084D3F → #0B6B57
  - Faint gold 8-point khatam geometric pattern (~7% opacity)
  - Centered gold (#C8A24A) open-book glyph (menu_book_rounded, codepoint 0xEF52)
  - Thin gold ring encircling the book
  - app_icon.png:         1024x1024, full-bleed (no alpha)
  - app_icon_foreground.png: 1024x1024, transparent bg, glyph ~62% of canvas
"""

import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ── Constants ─────────────────────────────────────────────────────────────────

SIZE = 1024

EMERALD_DARK = (8, 77, 63)      # #084D3F
EMERALD      = (11, 107, 87)    # #0B6B57
GOLD         = (200, 162, 74)   # #C8A24A

MATERIAL_ICONS_FONT = (
    "/Users/nourreddine/fvm/versions/stable/bin/cache/artifacts/"
    "material_fonts/MaterialIcons-Regular.otf"
)

# menu_book_rounded codepoint (verified from Flutter SDK icons.dart)
BOOK_CODEPOINT = 0xF8B4

OUTPUT_DIR = "/Users/nourreddine/Projects/quiz/assets/icon"


# ── Helpers ───────────────────────────────────────────────────────────────────

def make_gradient(size: int) -> Image.Image:
    """Vertical gradient from EMERALD_DARK (top) to EMERALD (bottom), RGBA."""
    img = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        r = int(EMERALD_DARK[0] + t * (EMERALD[0] - EMERALD_DARK[0]))
        g = int(EMERALD_DARK[1] + t * (EMERALD[1] - EMERALD_DARK[1]))
        b = int(EMERALD_DARK[2] + t * (EMERALD[2] - EMERALD_DARK[2]))
        draw.line([(0, y), (size - 1, y)], fill=(r, g, b, 255))
    return img


def draw_8pt_star(draw: ImageDraw.Draw, cx: float, cy: float, r: float,
                  color: tuple, stroke_width: float = 1.0):
    """Draw a single 8-point star outline centred at (cx, cy)."""
    points_n = 8
    inner_ratio = 0.42
    inner = r * inner_ratio

    # Outer star polygon (alternating outer/inner radii)
    star_pts = []
    for i in range(points_n * 2):
        radius = r if i % 2 == 0 else inner
        angle = (math.pi / points_n) * i - math.pi / 2
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        star_pts.append((x, y))
    draw.polygon(star_pts, outline=color + (0,), fill=None)
    draw.line(star_pts + [star_pts[0]], fill=color, width=max(1, int(stroke_width)))

    # Inner octagon connecting inner points
    oct_pts = []
    for i in range(points_n):
        angle = (math.pi / points_n) * (i * 2 + 1) - math.pi / 2
        x = cx + inner * math.cos(angle)
        y = cy + inner * math.sin(angle)
        oct_pts.append((x, y))
    draw.line(oct_pts + [oct_pts[0]], fill=color, width=max(1, int(stroke_width)))


def draw_khatam_pattern(size: int, cell_size: float = 72.0,
                        alpha: int = 18) -> Image.Image:
    """
    Render the tiled 8-point khatam pattern at very low opacity onto a
    transparent RGBA canvas of the given size.
    alpha: 0-255, ~18 ≈ 7%.
    """
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    step_x = cell_size * 2
    step_y = cell_size * 2
    cols = int(size / step_x) + 3
    rows = int(size / step_y) + 3
    color = GOLD  # will composite at low alpha

    stroke = max(1, int(cell_size * 0.022))

    for row in range(-1, rows + 1):
        for col in range(-1, cols + 1):
            cx = col * step_x + (step_x / 2 if row % 2 != 0 else 0)
            cy = row * step_y
            draw_8pt_star(draw, cx, cy, cell_size, color, stroke)

    # Reduce to target alpha
    r, g, b, a = layer.split()
    # Scale existing alpha by target fraction
    import PIL.ImageChops as chops
    a = a.point(lambda v: int(v * alpha / 255))
    layer = Image.merge("RGBA", (r, g, b, a))
    return layer


def render_book_glyph(glyph_size: int, padding: int = 0) -> Image.Image:
    """
    Render the menu_book_rounded glyph in gold on a transparent background.
    Returns an RGBA image of size (glyph_size + 2*padding) x (glyph_size + 2*padding).
    """
    canvas_size = glyph_size + 2 * padding
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    font = ImageFont.truetype(MATERIAL_ICONS_FONT, size=glyph_size)
    char = chr(BOOK_CODEPOINT)

    # Measure exact bounding box
    bbox = font.getbbox(char)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = padding + (glyph_size - text_w) // 2 - bbox[0]
    y = padding + (glyph_size - text_h) // 2 - bbox[1]

    draw.text((x, y), char, font=font, fill=GOLD + (255,))
    return img


def draw_gold_ring(draw: ImageDraw.Draw, cx: float, cy: float,
                   radius: float, ring_width: int = 6):
    """Draw a thin gold ring."""
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    for i in range(ring_width):
        r = radius - i
        b = [cx - r, cy - r, cx + r, cy + r]
        draw.arc(b, 0, 360, fill=GOLD + (255,), width=1)


def draw_gold_ring_smooth(img: Image.Image, cx: float, cy: float,
                           radius: float, ring_width: int = 8):
    """
    Draw a smooth gold ring by rendering at 2x and downsampling.
    """
    s2 = img.size[0] * 2
    big = Image.new("RGBA", (s2, s2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(big)
    cx2, cy2, r2, rw2 = cx * 2, cy * 2, radius * 2, ring_width * 2
    bbox = [cx2 - r2, cy2 - r2, cx2 + r2, cy2 + r2]
    draw.ellipse(bbox, outline=GOLD + (255,), width=rw2)
    small = big.resize(img.size, Image.LANCZOS)
    return Image.alpha_composite(img, small)


def draw_accent_stars(draw: ImageDraw.Draw, cx: float, cy: float,
                      ring_radius: float):
    """Draw four small 8-point accent stars at N/S/E/W on the ring."""
    accent_r = ring_radius * 0.06
    positions = [
        (cx, cy - ring_radius),
        (cx, cy + ring_radius),
        (cx - ring_radius, cy),
        (cx + ring_radius, cy),
    ]
    for px, py in positions:
        draw_8pt_star(draw, px, py, accent_r, GOLD, 1.5)


# ── Main generation ───────────────────────────────────────────────────────────

def generate_app_icon(output_path: str):
    """
    Full-bleed 1024x1024 icon: gradient bg + khatam + gold ring + book glyph.
    """
    # 1. Gradient background
    base = make_gradient(SIZE)

    # 2. Khatam pattern overlay (~7% opacity)
    pattern = draw_khatam_pattern(SIZE, cell_size=72.0, alpha=18)
    base = Image.alpha_composite(base, pattern)

    # 3. Gold ring — drawn AFTER book so it sits on top as a frame
    ring_radius = SIZE * 0.305   # ~312px radius — book fits cleanly inside
    cx = cy = SIZE / 2

    # 4. Book glyph — 48% of SIZE so it sits comfortably inside the ring
    glyph_size = int(SIZE * 0.48)
    book = render_book_glyph(glyph_size, padding=0)

    # Center-paste (shift book up very slightly — optical center)
    paste_x = (SIZE - book.size[0]) // 2
    paste_y = (SIZE - book.size[1]) // 2 - int(SIZE * 0.01)
    base.paste(book, (paste_x, paste_y), book)

    # 5. Gold ring ON TOP of the book (crisp frame effect)
    base = draw_gold_ring_smooth(base, cx, cy, ring_radius, ring_width=7)

    # 6. Small accent stars at ring cardinal points
    draw = ImageDraw.Draw(base)
    draw_accent_stars(draw, cx, cy, ring_radius)

    # 6. Flatten to RGB (no alpha for iOS + legacy Android)
    final = Image.new("RGB", (SIZE, SIZE), (EMERALD[0], EMERALD[1], EMERALD[2]))
    final.paste(base, mask=base.split()[3])

    final.save(output_path, "PNG", optimize=False)
    print(f"Saved: {output_path}  ({SIZE}x{SIZE} RGB)")


def generate_foreground_icon(output_path: str):
    """
    1024x1024 RGBA transparent bg, book glyph safe-zoned to ~62% of canvas.
    Android adaptive icon: glyph should stay within the inner 66% safe zone.
    We size the glyph to 52% of canvas for generous padding.
    """
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    ring_radius = SIZE * 0.280
    cx = cy = SIZE / 2

    # Book glyph at 44% of SIZE — fits cleanly within safe zone after ring
    glyph_size = int(SIZE * 0.44)
    book = render_book_glyph(glyph_size, padding=0)
    paste_x = (SIZE - book.size[0]) // 2
    paste_y = (SIZE - book.size[1]) // 2 - int(SIZE * 0.01)
    canvas.paste(book, (paste_x, paste_y), book)

    # Gold ring drawn on top of the book
    canvas = draw_gold_ring_smooth(canvas, cx, cy, ring_radius, ring_width=7)

    # Accent stars
    draw = ImageDraw.Draw(canvas)
    draw_accent_stars(draw, cx, cy, ring_radius)

    canvas.save(output_path, "PNG", optimize=False)
    print(f"Saved: {output_path}  ({SIZE}x{SIZE} RGBA transparent)")


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    icon_path = os.path.join(OUTPUT_DIR, "app_icon.png")
    fg_path   = os.path.join(OUTPUT_DIR, "app_icon_foreground.png")

    generate_app_icon(icon_path)
    generate_foreground_icon(fg_path)

    # Verify
    for p in [icon_path, fg_path]:
        img = Image.open(p)
        print(f"  Verified: {p}  size={img.size}  mode={img.mode}")

    print("\nDone.")
