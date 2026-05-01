"""
Masamune YouTube Video Generator
Takes the pixel art frames and produces a looping MP4 for YouTube.
Output: masamune_youtube.mp4 (60 seconds, 1920×1080, 30 fps)
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import imageio.v3 as iio
from masamune_pixel_art import build_all_frames, upscale, add_scanlines, add_gb_vignette, add_whiskers, BG

TARGET_W = 1920
TARGET_H = 1080
FPS = 30
DURATION_SEC = 60  # 1-minute loop


def build_youtube_frame(pil_img, scale=14):
    """
    Center the pixel art on a 1920×1080 canvas.
    Adds a dark retro background with subtle grid lines.
    """
    sprite = upscale(pil_img, scale)
    sprite = add_gb_vignette(sprite)

    # Background canvas
    canvas = Image.new("RGB", (TARGET_W, TARGET_H), BG)

    # Subtle grid pattern (retro CRT feel)
    arr = np.array(canvas, dtype=np.uint8)
    for y in range(0, TARGET_H, 4):
        arr[y, :] = np.clip(arr[y, :].astype(int) + 6, 0, 255)
    for x in range(0, TARGET_W, 4):
        arr[:, x] = np.clip(arr[:, x].astype(int) + 4, 0, 255)
    canvas = Image.fromarray(arr)

    # Paste centered sprite
    sx, sy = sprite.size
    ox = (TARGET_W - sx) // 2
    oy = (TARGET_H - sy) // 2
    canvas.paste(sprite, (ox, oy))

    # Subtle scanlines over whole frame
    arr2 = np.array(canvas, dtype=np.float32)
    for y in range(0, TARGET_H, 2):
        arr2[y] = arr2[y] * 0.88
    canvas = Image.fromarray(arr2.clip(0, 255).astype(np.uint8))

    return canvas


def frames_to_numpy(pil_frames):
    return [np.array(f.convert("RGB")) for f in pil_frames]


def main():
    print("Building animation frames...")
    frames, durations = build_all_frames()
    frames = [add_whiskers(f) for f in frames]

    print("Composing YouTube frames (1920×1080)...")
    yt_frames = [build_youtube_frame(f) for f in frames]

    # Build timed frame sequence at 30 fps
    sequence = []
    for pil_frame, ms in zip(yt_frames, durations):
        count = max(1, round((ms / 1000) * FPS))
        arr = np.array(pil_frame.convert("RGB"))
        for _ in range(count):
            sequence.append(arr)

    loop_len = len(sequence)
    total_frames = DURATION_SEC * FPS
    # Tile the loop to fill the full duration
    full_sequence = []
    while len(full_sequence) < total_frames:
        full_sequence.extend(sequence)
    full_sequence = full_sequence[:total_frames]

    out_path = "masamune_youtube.mp4"
    print(f"Writing {out_path}  ({total_frames} frames @ {FPS} fps = {DURATION_SEC}s)...")

    with iio.imopen(out_path, "w", plugin="pyav") as writer:
        writer.init_video_stream("libx264", fps=FPS)
        for frame_arr in full_sequence:
            writer.write_frame(frame_arr)

    print(f"\nDone!  {out_path}  ({DURATION_SEC}s loop, 1920×1080, {FPS}fps)")
    print("YouTube upload tip: use this as the visual track, then add your Suno 8-bit music in a video editor.")


if __name__ == "__main__":
    main()
