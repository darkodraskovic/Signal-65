#!/usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image

SPR_W = 24
SPR_H = 21
BYTES_PER_ROW = 3
SPRITE_BYTES = 64


def pixel_on(px, threshold):
    r, g, b, a = px
    return a > 0 and (r + g + b) > threshold


def convert_sprite(img, x0, y0, threshold):
    data = []

    for y in range(SPR_H):
        for bx in range(BYTES_PER_ROW):
            byte = 0

            for bit in range(8):
                x = bx * 8 + bit
                px = img.getpixel((x0 + x, y0 + y))

                if pixel_on(px, threshold):
                    byte |= 1 << (7 - bit)

            data.append(byte)

    # C64 sprite data is 63 bytes; pad to 64 for alignment
    data.append(0)

    return bytes(data)


def write_asm(path, sprites):
    with path.open("w") as f:
        for i, sprite in enumerate(sprites):
            f.write(f"sprite_{i}:\n")
            for j in range(0, len(sprite), 8):
                chunk = sprite[j : j + 8]
                f.write("    .byte " + ", ".join(f"${b:02X}" for b in chunk) + "\n")
            f.write("\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert a monochrome C64-compatible sprite sheet to raw sprite binary."
    )

    parser.add_argument("input", help="input PNG sprite sheet")
    parser.add_argument("--bin", default=None, help="output raw binary file")
    parser.add_argument("--asm", default=None, help="output assembly .byte file")
    parser.add_argument("--threshold", type=int, default=128)

    args = parser.parse_args()

    if not args.bin and not args.asm:
        parser.error("choose at least one output format: --bin and/or --asm")

    input_path = Path(args.input)
    img = Image.open(input_path).convert("RGBA")

    w, h = img.size

    if w % SPR_W != 0:
        raise ValueError("image width must be divisible by 24")

    if h % SPR_H != 0:
        raise ValueError("image height must be divisible by 21")

    sprites_x = w // SPR_W
    sprites_y = h // SPR_H

    sprites = []

    for sy in range(sprites_y):
        for sx in range(sprites_x):
            x0 = sx * SPR_W
            y0 = sy * SPR_H
            sprites.append(convert_sprite(img, x0, y0, args.threshold))

    print(f"image: {w}x{h}")
    print(f"sprites: {sprites_x}x{sprites_y} = {len(sprites)}")
    print(f"bytes: {len(sprites) * SPRITE_BYTES}")

    if args.bin:
        bin_path = Path(args.bin)
        with bin_path.open("wb") as f:
            for sprite in sprites:
                f.write(sprite)
        print(f"wrote: {bin_path}")

    if args.asm:
        asm_path = Path(args.asm)
        write_asm(asm_path, sprites)
        print(f"wrote: {asm_path}")


if __name__ == "__main__":
    main()
