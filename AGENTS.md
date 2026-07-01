# AGENTS.md

## Project Direction

- Target MEGA65 only. Do not add C64 compatibility paths unless explicitly requested.
- Prefer MEGA65/C65 dedicated registers over legacy CIA approaches when the MEGA65 provides a better interface.
- Assembly is written for KickAssembler using the 45GS02 CPU mode.
- Use the local MEGA65 reference book and KickAssembler manual as the source of truth when hardware or assembler behavior is uncertain.

## Memory Model

- Use only the first 1MB of RAM for this project unless explicitly instructed otherwise.
- Treat memory planning as a 20-bit address-space problem. Avoid designs that require full 28-bit addressing, Attic RAM, or future larger RAM assumptions.
- Use a C65-like MAP-register procedure for memory mapping, as described in the MEGA65 book page 247 / section "The MAP Register": remap 8KB 16-bit address blocks using MAPLO/MAPHI offsets.
- This does not mean targeting C65 native compatibility. The project remains MEGA65-only; the C65-like part is the memory-mapping procedure and 20-bit addressing discipline.
- Prefer named memory-layout constants and documented regions before adding new code/data blocks.

## File Boundaries

- `src/main.asm` owns game logic, program flow, player state, frame timing, and asset placement.
- `src/gfx.asm` owns VIC-IV/video/sprite register constants and graphics macros.
- `src/input.asm` owns MEGA65 keyboard input register constants, key masks, and input-read macros.
- `src/basic_autostart.asm` owns the BASIC autostart stub.
- `res/` files are generated asset data. Avoid hand-editing generated `.asm` data unless explicitly requested.
- `convert/` scripts generate charset, sprite, and map data from source assets.

## KickAssembler Style

- Use `.const` for meaningful hardware addresses, memory layout choices, and timing values.
- Use KickAssembler macros for repeated emitted assembly code.
- Use KickAssembler `.function` only for compile-time value calculations, not runtime instruction sequences.
- Keep hardware-helper macros in the relevant hardware file; keep game-behavior macros in `src/main.asm` until a dedicated game-logic file exists.
- Prefer comments that explain hardware intent, register meaning, or game intent. Avoid comments that merely restate the instruction.

## MEGA65 Input

- Use the MEGA65/C65 keyboard matrix registers:
  - `$D614`: keyboard matrix column select; write column number `0-8`.
  - `$D613`: selected column row data; active-low, where `0 = pressed` and `1 = not pressed`.
- Avoid C64 CIA keyboard scanning for this project.
- It is fine to cache column state in RAM when that makes game logic clearer.

## Graphics And Timing

- Unlock VIC-IV registers before writing VIC-IV-specific registers.
- Keep `src/gfx.asm` focused on register definitions and reusable graphics macros.
- Prefer named constants over magic raster lines or memory addresses.
- Frame sync currently waits on `FRAME_SYNC_RASTER`, a lower-border raster line after visible drawing.

## Verification

- After assembly changes, run:

  `./make.sh build`

- `c1541` may print `libopencbm.dylib` warnings. If the PRG and D81 are produced and the program is written to the disk image, the build is acceptable.

## Working Tree

- The repo may already contain user changes. Do not revert unrelated edits.
- Preserve generated build outputs unless explicitly asked to clean them.
