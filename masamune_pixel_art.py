"""
Masamune Pixel Art Animation Generator
Creates a Game Boy-style pixel art animation of the cat Masamune.
Outputs: masamune_idle.gif and masamune_loop.gif (upscaled)
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np

# ── Palette ──────────────────────────────────────────────────────────────────
BG  = (15, 15, 30)        # dark navy background (retro screen feel)
W   = (240, 238, 222)     # white/cream fur
LG  = (195, 190, 185)     # light gray fur
MG  = (120, 116, 116)     # medium gray patches
DG  = (65, 60, 60)        # dark gray (outlines)
BK  = (25, 20, 20)        # near-black
EY  = (148, 168, 48)      # yellow-green iris
HL  = (255, 255, 248)     # eye highlight
PK  = (255, 152, 158)     # pink nose
PK2 = (220, 110, 118)     # darker pink nose center
WS  = (230, 228, 215)     # whisker color (slightly off-white)

PALETTE = {
    '.': BG,
    'W': W,
    'g': LG,
    'G': MG,
    'k': DG,
    'K': BK,
    'E': EY,
    'H': HL,
    'P': PK,
    'p': PK2,
    'w': WS,
}

# ── Sprite design (32 × 44 pixels) ──────────────────────────────────────────
#
# Masamune: white & gray fluffy cat, sitting, front-facing
# Inspired by the photo — gray cap on head, gray patches on back, green-gold eyes
#
# Color key:
#   .  background    W  white fur      g  light gray     G  medium gray
#   k  dark outline  K  black          E  eye iris       H  eye highlight
#   P  pink nose     p  dark nose      w  whisker
#

BASE_SPRITE = [
    # Ears
    "................kk......kk......",  #  0
    "...............kGGk....kGGk.....",  #  1
    "..............kGGGk....kGGGk....",  #  2
    ".............kGGGGkkkkkGGGGk....",  #  3
    # Head top – gray cap
    "............kGGGGGWWWWGGGGGk....",  #  4
    "...........kGGGGWWWWWWWGGGGk....",  #  5
    "..........kGGGWWWWWWWWWWGGGk....",  #  6
    ".........kGGGWWWWWWWWWWWWGGk....",  #  7
    ".........kGWWWWWWWWWWWWWWWGk....",  #  8
    # Face – eyes row
    ".........kWWWWkkWWWWkkWWWWWk....",  #  9  eye outline top
    ".........kWWWkEEkWWkEEkWWWWk....",  # 10  iris
    ".........kWWWkEHkWWkEHkWWWWk....",  # 11  highlight
    ".........kWWWWkkWWWWkkWWWWWk....",  # 12  eye outline bottom
    # Nose / mouth
    ".........kWWWWWWPpWWWWWWWWWk....",  # 13  nose
    ".........kWWWWWWWWWWWWWWWWWk....",  # 14
    # Chin / cheeks (gray sides)
    "........kGGWWWWWWWWWWWWWWGGk....",  # 15
    "........kGGGGWWWWWWWWWWGGGGk....",  # 16
    "........kkkkkkkkkkkkkkkkkkkkk...",  # 17  neck/collar line
    # Body
    ".......kWWWWWWWWWWWWWWWWWWWk....",  # 18
    "......kWWWWWWWWWWWWWWWWWWWWWk...",  # 19
    ".....kWWWWWWGGGGGGGGWWWWWWWWWk..",  # 20  gray back patch starts
    ".....kWWWWWGGGGGGGGGGWWWWWWWWk..",  # 21
    ".....kWWWWWGGGGGGGGGGWWWWWWWWk..",  # 22
    ".....kWWWWWWGGGGGGGGWWWWWWWWWk..",  # 23
    ".....kWWWWWWWWWWWWWWWWWWWWWWWk..",  # 24
    ".....kWWWWWWWWWWWWWWWWWWWWWWWk..",  # 25
    "......kWWWWWWWWWWWWWWWWWWWWWk...",  # 26
    # Paws
    ".......kWWWWkkkWWWWWkkkWWWWk....",  # 27  paw dividers
    ".......kWWWWWWWWWWWWWWWWWWk.....",  # 28
    "........kkkWWWWWWWWWWWWkkk......",  # 29  paw bottoms
    ".........kkkWWWWWWWWWkkk........",  # 30
    "..........kkkkkkkkkkkkkk........",  # 31
    # Tail (visible to the right side)
    ".............................kGk.",  # 32
    "............................kGGk.",  # 33
    "...........................kGGGk.",  # 34
    "...........................kGGGk.",  # 35
    "............................kGGk.",  # 36
    ".............................kGk.",  # 37
    "................................",  # 38
    "................................",  # 39
    "................................",  # 40
    "................................",  # 41
    "................................",  # 42
    "................................",  # 43
]

# Blink frames – only rows 9-12 change
BLINK_HALF = [
    "........kWWWWkkkWWWWkkkWWWWk....",  # eyes half-shut (top bar thicker)
    "........kWWWWkkkWWWWkkkWWWWk....",
    "........kWWWWkkkWWWWkkkWWWWk....",
    "........kWWWWkkkWWWWkkkWWWWk....",
]
BLINK_CLOSED = [
    ".........kWWWWkkWWWWkkWWWWWk....",
    ".........kWWWkkkWWWkkkWWWWWk....",
    ".........kWWWkkkWWWkkkWWWWWk....",
    ".........kWWWWkkWWWWkkWWWWWk....",
]

# Breathe frame – body rows 19-26 shift outward by 1 px (simulate chest expansion)
BREATHE_BODY = [
    ".....kWWWWWWWWWWWWWWWWWWWWWWWk..",  # row 19 expanded
    "....kWWWWWWGGGGGGGGWWWWWWWWWWWk.",  # 20
    "....kWWWWWGGGGGGGGGGWWWWWWWWWWk.",  # 21
    "....kWWWWWGGGGGGGGGGWWWWWWWWWWk.",  # 22
    "....kWWWWWWGGGGGGGGWWWWWWWWWWWk.",  # 23
    "....kWWWWWWWWWWWWWWWWWWWWWWWWWk.",  # 24
    "....kWWWWWWWWWWWWWWWWWWWWWWWWWk.",  # 25
    ".....kWWWWWWWWWWWWWWWWWWWWWWWk..",  # 26
]

SPRITE_W = 32
SPRITE_H = 44


def row_to_pixels(row_str):
    return [PALETTE[c] for c in row_str[:SPRITE_W]]


def build_frame(sprite_rows, blink_rows=None, breathe=False):
    """Render one frame as a PIL Image (1× scale)."""
    rows = list(sprite_rows)

    # Apply blink override (rows 9-12)
    if blink_rows:
        rows[9:13] = blink_rows

    # Apply breathe override (rows 19-26)
    if breathe:
        rows[19:27] = BREATHE_BODY

    img = Image.new("RGB", (SPRITE_W, SPRITE_H), BG)
    for y, row in enumerate(rows):
        px = row_to_pixels(row)
        for x, color in enumerate(px):
            img.putpixel((x, y), color)

    return img


def add_whiskers(img):
    """Draw sub-pixel-feel whiskers on the face."""
    draw = ImageDraw.Draw(img)
    # Left whiskers (rows 13-15, cols 0-8)
    whisker_color = WS
    draw.line([(0, 13), (8, 13)], fill=whisker_color)
    draw.line([(0, 14), (7, 14)], fill=whisker_color)
    draw.line([(0, 15), (6, 15)], fill=whisker_color)
    # Right whiskers (rows 13-15, cols 22-31)
    draw.line([(23, 13), (31, 13)], fill=whisker_color)
    draw.line([(24, 14), (31, 14)], fill=whisker_color)
    draw.line([(25, 15), (31, 15)], fill=whisker_color)
    return img


def upscale(img, factor=8):
    """Nearest-neighbor upscale for crisp pixel art look."""
    return img.resize(
        (img.width * factor, img.height * factor),
        Image.NEAREST
    )


def add_scanlines(img):
    """Subtle CRT scanlines for retro Game Boy feel."""
    arr = np.array(img, dtype=np.float32)
    for y in range(0, arr.shape[0], 2):
        arr[y] = arr[y] * 0.82
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def add_gb_vignette(img):
    """Slight vignette + green tint like original Game Boy screen."""
    arr = np.array(img, dtype=np.float32)
    h, w = arr.shape[:2]
    Y, X = np.ogrid[:h, :w]
    cx, cy = w / 2, h / 2
    dist = np.sqrt(((X - cx) / cx) ** 2 + ((Y - cy) / cy) ** 2)
    vignette = np.clip(1 - dist * 0.35, 0.6, 1.0)
    for c in range(3):
        arr[:, :, c] *= vignette
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def build_all_frames():
    """
    Animation sequence:
      [0-7]   idle (8 frames)
      [8-10]  breathe in (3 frames)
      [11-13] breathe out (3 frames)
      [14-16] blink half (3 frames)
      [17]    blink closed (1 frame)
      [18-20] blink open (3 frames)
      [21-28] idle (8 frames)
    """
    frames = []
    durations = []

    def add(frame, ms):
        f = add_whiskers(frame)
        frames.append(f)
        durations.append(ms)

    idle = build_frame(BASE_SPRITE)
    breathe = build_frame(BASE_SPRITE, breathe=True)
    blink_half = build_frame(BASE_SPRITE, blink_rows=BLINK_HALF)
    blink_closed = build_frame(BASE_SPRITE, blink_rows=BLINK_CLOSED)

    # Idle hold
    for _ in range(8):
        add(idle.copy(), 120)

    # Breathe in
    for _ in range(3):
        add(breathe.copy(), 100)

    # Breathe out
    for _ in range(3):
        add(idle.copy(), 100)

    # Pause
    for _ in range(4):
        add(idle.copy(), 120)

    # Blink
    add(blink_half.copy(), 60)
    add(blink_closed.copy(), 80)
    add(blink_half.copy(), 60)

    # Resume idle
    for _ in range(10):
        add(idle.copy(), 120)

    return frames, durations


def save_gif(frames, durations, path, scale=1, scanlines=False):
    scaled = []
    for f in frames:
        img = upscale(f, scale)
        if scanlines:
            img = add_scanlines(img)
        img = add_gb_vignette(img)
        scaled.append(img.convert("P", palette=Image.ADAPTIVE, colors=64))

    scaled[0].save(
        path,
        save_all=True,
        append_images=scaled[1:],
        duration=durations,
        loop=0,
        optimize=False,
        disposal=2,
    )
    print(f"  Saved: {path}  ({len(frames)} frames, {sum(durations)/1000:.1f}s loop)")


def save_sprite_sheet(frames, path, scale=6):
    """Save a sprite sheet PNG of all unique key frames."""
    key = [frames[0], frames[8], frames[14], frames[15], frames[16]]
    total_w = sum(f.width for f in key) * scale + (len(key) - 1) * 4
    sheet = Image.new("RGB", (total_w, key[0].height * scale), BG)
    x = 0
    for f in key:
        up = upscale(f, scale)
        sheet.paste(up, (x, 0))
        x += up.width + 4
    sheet.save(path)
    print(f"  Saved: {path}")


def main():
    print("Building Masamune pixel art animation...")

    frames, durations = build_all_frames()

    print("\nSaving outputs:")

    # Small 1× GIF (for web/preview)
    save_gif(frames, durations, "masamune_small.gif", scale=1)

    # Standard 8× GIF (YouTube thumbnail / preview)
    save_gif(frames, durations, "masamune_idle.gif", scale=8)

    # CRT scanline version
    save_gif(frames, durations, "masamune_crt.gif", scale=8, scanlines=True)

    # Sprite sheet
    save_sprite_sheet(frames, "masamune_spritesheet.png", scale=6)

    print("\nAll done! Files created in the current directory.")
    print("  masamune_small.gif      – 1× preview")
    print("  masamune_idle.gif       – 8× clean pixel art loop")
    print("  masamune_crt.gif        – 8× CRT scanline retro effect")
    print("  masamune_spritesheet.png– key frame sprite sheet")


if __name__ == "__main__":
    main()
