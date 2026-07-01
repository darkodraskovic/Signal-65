// a tiny MEGA65 sprite test

		.cpu _45gs02

// -------------------------------------------
// Constants
// -------------------------------------------

.const SPRITE_POINTER0	= $07f8		// game-chosen address for sprite 0's pointer byte
.const SPRITE_DATA	= $2200		// game-chosen sprite data address; 64-byte aligned
.const SPRITE_RIGHT	= SPRITE_DATA / $40 + 0 // first generated sprite: arrow right
.const SPRITE_UP	= SPRITE_DATA / $40 + 1 // second generated sprite: arrow up
.const SPRITE_LEFT	= SPRITE_DATA / $40 + 2 // third generated sprite: arrow left
.const SPRITE_DOWN	= SPRITE_DATA / $40 + 3 // fourth generated sprite: arrow down

.const CHARSET_DATA	= $2800		// game-chosen address for custom 8x8 character glyphs
.const SCREEN_DATA	= $2c00		// game-chosen address for generated screen maps
.const FRAME_SYNC_RASTER = $fa		// lower-border raster line just below the 40x25 text area

// -------------------------------------------
// Imports
// -------------------------------------------

		.import source "gfx.asm"
		.import source "input.asm"
		.import source "basic_autostart.asm"

// -------------------------------------------
// Game Logic Macros
// -------------------------------------------

.macro move_player_if_pressed(columnState, keyMask, positionAddress, delta, spritePointer) {
		lda columnState		// test cached keyboard matrix column bits
		and #keyMask		// key pressed?
		bne done
.if (delta < 0) {
		dec positionAddress
} else {
		inc positionAddress
}
		lda #spritePointer
		sta SPRITE_POINTER0
done:
}

.macro sync_player_sprite() {
		lda player_x		// copy remembered player X to sprite hardware
		sta SPRITE0_X
		lda player_y		// copy remembered player Y to sprite hardware
		sta SPRITE0_Y
}

// -------------------------------------------
// Startup
// -------------------------------------------

		* = $2011
start:
		sei			// disable KERNAL IRQs while we own keyboard scanning

		lda #$02		// choose border color
		sta BORDER_COLOR	// apply border color
		lda #$05		// choose background color
		sta BACKGROUND_COLOR	// apply background color

		gfx_unlock_vic4()	// make VIC-IV registers visible before changing video mode
		gfx_set_40_column_text() // make the 40x25 map line up with the display
		gfx_init_vic4_sprites(SPRITE_POINTER0, SPRITE_POINTER0 >> 16)
		gfx_set_screen_address(screen_map_1_0) // display the first generated screen map
		gfx_set_charset_address(charset_hires_16x8) // use the generated custom charset

		ldx #$00		// start at color RAM offset 0
		lda #$01		// choose foreground color for every map cell
fill_color:
		sta COLOR_RAM,x		// color cells $d800-$d8ff
		sta COLOR_RAM+$100,x	// color cells $d900-$d9ff
		sta COLOR_RAM+$200,x	// color cells $da00-$daff
		sta COLOR_RAM+$300,x	// color cells $db00-$dbff
		inx			// advance to the next color RAM byte
		bne fill_color		// loop until all 1024 color bytes are filled

		lda #$80		// initial player X position
		sta player_x		// remember player X in RAM
		sta SPRITE0_X		// move sprite 0 horizontally
		lda #$70		// initial player Y position
		sta player_y		// remember player Y in RAM
		sta SPRITE0_Y		// move sprite 0 vertically
		lda #$11		// sprite 0 color
		sta SPRITE0_COLOR	// apply sprite 0 color

		lda #SPRITE_RIGHT	// start with the right-facing arrow sprite
		sta SPRITE_POINTER0	// store sprite 0 pointer byte at $07f8

		lda #%00000001		// enable only sprite 0
		sta SPRITE_ENABLE	// bit 0 on means sprite 0 visible

// -------------------------------------------
// Main Loop
// -------------------------------------------

main_loop:
		jsr wait_frame		// update movement once per video frame
		jsr read_wasd		// poll WASD and move the player sprite
		jmp main_loop		// keep the game running

// -------------------------------------------
// Input And Movement
// -------------------------------------------

read_wasd:
		input_read_column(1, key_col_1) // read column 1: W/A/S
		input_read_column(2, key_col_2) // read column 2: D

		move_player_if_pressed(key_col_1, KEY_A_MASK, player_x, -1, SPRITE_LEFT)
		move_player_if_pressed(key_col_2, KEY_D_MASK, player_x, 1, SPRITE_RIGHT)
		move_player_if_pressed(key_col_1, KEY_W_MASK, player_y, -1, SPRITE_UP)
		move_player_if_pressed(key_col_1, KEY_S_MASK, player_y, 1, SPRITE_DOWN)

		sync_player_sprite()
		rts

// -------------------------------------------
// Frame Timing
// -------------------------------------------

wait_frame:
		lda #FRAME_SYNC_RASTER	// choose a stable line after visible drawing
wait_raster_line:
		cmp RASTER		// has the raster reached that line?
		bne wait_raster_line	// no, keep waiting
wait_raster_leave:
		cmp RASTER		// are we still on that same line?
		beq wait_raster_leave	// yes, wait so we only return once
		rts			// one frame has passed

// -------------------------------------------
// Game State
// -------------------------------------------

player_x:
		.byte $80		// current player X position
player_y:
		.byte $70		// current player Y position
key_col_1:
		.byte $ff		// cached MEGA65 keyboard matrix column 1
key_col_2:
		.byte $ff		// cached MEGA65 keyboard matrix column 2

// -------------------------------------------
// Asset Data
// -------------------------------------------

		* = SPRITE_DATA		// generated sprite data starts at SPRITE_DATA
		.import source "../res/gfx/sprites_hires_4x4.asm"

		* = CHARSET_DATA	// generated custom charset starts at $2800

charset_hires_16x8:
		.import source "../res/gfx/chars_hires_16x8.asm"

		* = SCREEN_DATA		// generated screen maps start at $2c00
		.import source "../res/maps/char_map_1.asm"
