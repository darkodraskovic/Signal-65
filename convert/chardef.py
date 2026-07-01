#!/usr/bin/env python3
import argparse
from pathlib import Path

from PIL import Image

TILE_W = 8
TILE_H = 8


def pixel_on(pixel, threshold):
    r, g, b, a = pixel
    return a > 0 and (r + g + b) > threshold


def convert_png_to_chars(path, threshold):
    img = Image.open(path).convert("RGBA")
    w, h = img.size

    if w % TILE_W != 0:
        raise ValueError("image width must be divisible by 8")

    if h % TILE_H != 0:
        raise ValueError("image height must be divisible by 8")

    chars_x = w // TILE_W
    chars_y = h // TILE_H

    data = []

    for cy in range(chars_y):
        for cx in range(chars_x):
            x0 = cx * TILE_W
            y0 = cy * TILE_H

            for y in range(TILE_H):
                byte = 0

                for x in range(TILE_W):
                    px = img.getpixel((x0 + x, y0 + y))

                    if pixel_on(px, threshold):
                        byte |= 1 << (7 - x)

                data.append(byte)

    return data, w, h, chars_x, chars_y


def write_bin(path, data):
    with open(path, "wb") as f:
        f.write(bytes(data))


def write_asm(path, data):
    with open(path, "w") as f:
        for i in range(0, len(data), 8):
            chunk = data[i : i + 8]
            line = ".byte " + ", ".join(f"${b:02X}" for b in chunk)
            f.write(line + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert monochrome PNG charset to raw MEGA65/C64 character bytes."
    )

    parser.add_argument("input", help="input PNG file")
    parser.add_argument(
        "--bin",
        help="output raw binary file",
        default=None,
    )
    parser.add_argument(
        "--asm",
        help="output assembly .byte file",
        default=None,
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=128,
        help="brightness threshold, default 128",
    )

    args = parser.parse_args()

    if not args.bin and not args.asm:
        parser.error("choose at least one output format: --bin and/or --asm")

    input_path = Path(args.input)

    data, w, h, chars_x, chars_y = convert_png_to_chars(
        input_path,
        args.threshold,
    )

    if args.bin:
        bin_path = Path(args.bin)
        write_bin(bin_path, data)

    if args.asm:
        write_asm(Path(args.asm), data)

    print(f"image: {w}x{h}")
    print(f"chars: {chars_x}x{chars_y} = {chars_x * chars_y}")
    print(f"bytes: {len(data)}")

    if args.bin:
        print(f"wrote: {bin_path}")

    if args.asm:
        print(f"wrote: {args.asm}")


if __name__ == "__main__":
    main()
