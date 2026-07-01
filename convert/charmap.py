#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path

empty_tile = 255

SCREEN_W = 40
SCREEN_H = 25
SCREEN_SIZE = 1024


def layer_label(name: str) -> str:
    label = name.lower().replace(" ", "_")
    return re.sub(r"[^a-z0-9_]", "", label)


def convert_gid(gid: int) -> int:
    if gid == 0:
        return empty_tile

    v = gid - 1

    if v < 0 or v > 255:
        raise ValueError(f"tile index out of byte range: {v}")

    return v


def tile_layers(m: dict):
    for layer in m["layers"]:
        if layer.get("type") == "tilelayer":
            yield layer


def select_layers(m: dict, names: list[str] | None):
    layers = list(tile_layers(m))

    if not names:
        return layers

    wanted = set(names)
    selected = [layer for layer in layers if layer["name"] in wanted]

    found = {layer["name"] for layer in selected}
    missing = wanted - found

    if missing:
        available = ", ".join(layer["name"] for layer in layers)
        raise ValueError(
            f"layer(s) not found: {', '.join(sorted(missing))}; available tile layers: {available}"
        )

    return selected


def screen_chunks(layer: dict, map_w: int, map_h: int) -> list[bytes]:
    if map_w % SCREEN_W != 0:
        raise ValueError(f"map width must be divisible by {SCREEN_W}")

    if map_h % SCREEN_H != 0:
        raise ValueError(f"map height must be divisible by {SCREEN_H}")

    screens_x = map_w // SCREEN_W
    screens_y = map_h // SCREEN_H

    data = layer["data"]
    chunks = []

    for sy in range(screens_y):
        for sx in range(screens_x):
            chunk = bytearray()

            for y in range(SCREEN_H):
                map_y = sy * SCREEN_H + y

                for x in range(SCREEN_W):
                    map_x = sx * SCREEN_W + x
                    gid = data[map_y * map_w + map_x]
                    chunk.append(convert_gid(gid))

            while len(chunk) < SCREEN_SIZE:
                chunk.append(0)

            chunks.append(bytes(chunk))

    return chunks


def write_bin(path: Path, layers, width: int, height: int):
    with path.open("wb") as f:
        for layer in layers:
            for chunk in screen_chunks(layer, width, height):
                f.write(chunk)


def write_asm(path: Path, layers, width: int, height: int):
    with path.open("w") as f:
        for layer in layers:
            label = layer_label(layer["name"])
            chunks = screen_chunks(layer, width, height)

            for i, chunk in enumerate(chunks):
                f.write(f"{label}_{i}:\n")

                useful = chunk[: SCREEN_W * SCREEN_H]

                for y in range(SCREEN_H):
                    row = useful[y * SCREEN_W : (y + 1) * SCREEN_W]
                    line = ", ".join(f"${v:02X}" for v in row)
                    f.write(f"    .byte {line}\n")

                padding_size = SCREEN_SIZE - SCREEN_W * SCREEN_H
                padding = ", ".join("$00" for _ in range(padding_size))
                f.write("    // padding to 1024 bytes\n")
                f.write(f"    .byte {padding}\n\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert Tiled .tmj tile layers to screenwise 40x25 binary chunks."
    )

    parser.add_argument("input", help="input Tiled .tmj file")

    parser.add_argument(
        "--bin",
        help="output raw binary file",
        default=None,
    )

    parser.add_argument(
        "-l",
        "--layer",
        action="append",
        help="tile layer name to export; can be used multiple times; default: all tile layers",
        default=None,
    )

    parser.add_argument(
        "--asm",
        help="output assembly .byte file",
        default=None,
    )

    args = parser.parse_args()

    if not args.bin and not args.asm:
        parser.error("choose at least one output format: --bin and/or --asm")

    infile = Path(args.input)

    with infile.open("r", encoding="utf-8") as f:
        m = json.load(f)

    width = m["width"]
    height = m["height"]

    layers = select_layers(m, args.layer)

    if not layers:
        raise ValueError("no tile layers found")

    if args.bin:
        bin_path = Path(args.bin)
        write_bin(bin_path, layers, width, height)

    screens_x = width // SCREEN_W
    screens_y = height // SCREEN_H
    screen_count = screens_x * screens_y

    print(f"map: {width}x{height}")
    print(f"screen chunks: {screens_x}x{screens_y} = {screen_count}")
    print(f"chunk size: {SCREEN_SIZE}")
    print(f"layers: {len(layers)}")
    print(f"selected: {', '.join(layer['name'] for layer in layers)}")
    print(f"bytes: {len(layers) * screen_count * SCREEN_SIZE}")

    if args.bin:
        print(f"wrote: {bin_path}")

    if args.asm:
        asm_path = Path(args.asm)
        write_asm(asm_path, layers, width, height)
        print(f"wrote: {asm_path}")


if __name__ == "__main__":
    main()
