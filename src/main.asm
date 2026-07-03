// a tiny MEGA65 sprite test

		.cpu _45gs02

		.import source "gfx.asm"

// -------------------------------------------
// Constants
// -------------------------------------------

.const SPRITE_POINTER0	= $07f8		// game-chosen address for sprite 0's pointer byte
.const SPRITE_DATA	= $2400		// game-chosen sprite data address; 64-byte aligned
.const SPRITE_RIGHT	= SPRITE_DATA / $40 + 0 // first generated sprite: arrow right
.const SPRITE_UP	= SPRITE_DATA / $40 + 1 // second generated sprite: arrow up
.const SPRITE_LEFT	= SPRITE_DATA / $40 + 2 // third generated sprite: arrow left
.const SPRITE_DOWN	= SPRITE_DATA / $40 + 3 // fourth generated sprite: arrow down

.const CHARSET_DATA	= $2800		// game-chosen address for custom 8x8 character glyphs
.const SCREEN_DATA	= $2c00		// game-chosen address for generated screen maps
.const ROOM_SCREEN_BYTES = $400		// each 40x25 screen is padded to 1024 bytes
.const FRAME_SYNC_RASTER = $fa		// lower-border raster line just below the 40x25 text area

.const ROOM_COLUMNS	= 2		// generated room columns in the room matrix
.const ROOM_ROWS	= 2		// generated room rows in the room matrix

.const PLAYER_SPEED	= $02		// pixels moved per frame
.const PLAYER_MIN_X	= BACKGROUND_EDGE_LEFT // leftmost local sprite X inside a room
.const PLAYER_MAX_X	= BACKGROUND_EDGE_RIGHT - SPRITE_WIDTH // rightmost local sprite X inside a room
.const PLAYER_MIN_Y	= BACKGROUND_EDGE_TOP // topmost local sprite Y inside a room
.const PLAYER_MAX_Y	= BACKGROUND_EDGE_BOTTOM - SPRITE_HEIGHT // bottommost local sprite Y inside a room
.const PLAYER_HALF_WIDTH = SPRITE_WIDTH >> 1 // room changes when half the sprite crosses horizontally
.const PLAYER_HALF_HEIGHT = SPRITE_HEIGHT >> 1 // room changes when half the sprite crosses vertically
.const PLAYER_EXIT_LEFT_TRIGGER = PLAYER_MIN_X - PLAYER_HALF_WIDTH + PLAYER_SPEED - 1
.const PLAYER_EXIT_RIGHT_TRIGGER = BACKGROUND_EDGE_RIGHT - PLAYER_HALF_WIDTH - PLAYER_SPEED + 1
.const PLAYER_EXIT_TOP_TRIGGER = PLAYER_MIN_Y - PLAYER_HALF_HEIGHT + PLAYER_SPEED - 1
.const PLAYER_EXIT_BOTTOM_TRIGGER = BACKGROUND_EDGE_BOTTOM - PLAYER_HALF_HEIGHT - PLAYER_SPEED + 1
.const PLAYER_CLAMP_LEFT_TRIGGER = PLAYER_MIN_X + PLAYER_SPEED - 1
.const PLAYER_CLAMP_RIGHT_TRIGGER = PLAYER_MAX_X - PLAYER_SPEED + 1
.const PLAYER_CLAMP_TOP_TRIGGER = PLAYER_MIN_Y + PLAYER_SPEED - 1
.const PLAYER_CLAMP_BOTTOM_TRIGGER = PLAYER_MAX_Y - PLAYER_SPEED + 1
.const PLAYER_ENTRY_LEFT = PLAYER_MIN_X - PLAYER_HALF_WIDTH // enter with half sprite before left edge
.const PLAYER_ENTRY_RIGHT = BACKGROUND_EDGE_RIGHT - PLAYER_HALF_WIDTH // enter with half sprite past right edge
.const PLAYER_ENTRY_TOP = PLAYER_MIN_Y - PLAYER_HALF_HEIGHT // enter with half sprite above top edge
.const PLAYER_ENTRY_BOTTOM = BACKGROUND_EDGE_BOTTOM - PLAYER_HALF_HEIGHT // enter with half sprite below bottom edge
.const INITIAL_PLAYER_X = $0080 // initial player X coordinate
.const INITIAL_PLAYER_Y = $70	// initial player Y coordinate

// -------------------------------------------
// Imports
// -------------------------------------------

		.import source "input.asm"
		.import source "basic_autostart.asm"

// -------------------------------------------
// Startup
// -------------------------------------------

		* = $2011
		.import source "room_logic.asm"
		.import source "player_logic.asm"

start:
		sei			// disable KERNAL IRQs while we own keyboard scanning

		lda #$02		// choose border color
		sta BORDER_COLOR	// apply border color
		lda #$05		// choose background color
		sta BACKGROUND_COLOR	// apply background color

		gfx_unlock_vic4()	// make VIC-IV registers visible before changing video mode
		gfx_set_40_column_text() // make the 40x25 map line up with the display
		gfx_init_vic4_sprites(SPRITE_POINTER0, SPRITE_POINTER0 >> 16)
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

		lda #<INITIAL_PLAYER_X // initial player X low byte
		sta player_x
		lda #>INITIAL_PLAYER_X // initial player X high byte
		sta player_x+1
		lda #INITIAL_PLAYER_Y // initial player Y
		sta player_y
		jsr display_current_room
		sync_player_sprite()
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

		move_player_if_pressed(key_col_1, KEY_A_MASK, SPRITE_LEFT, move_player_left)
		move_player_if_pressed(key_col_2, KEY_D_MASK, SPRITE_RIGHT, move_player_right)
		move_player_if_pressed(key_col_1, KEY_W_MASK, SPRITE_UP, move_player_up)
		move_player_if_pressed(key_col_1, KEY_S_MASK, SPRITE_DOWN, move_player_down)

		lda room_changed
		beq sync_player_after_input
		lda #$00
		sta room_changed
		jsr display_current_room
sync_player_after_input:
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
		.word INITIAL_PLAYER_X // current player X coordinate
player_y:
		.byte INITIAL_PLAYER_Y // current player Y coordinate
player_room_col:
		.byte $00		// player room column in the room matrix
player_room_row:
		.byte $00		// player room row in the room matrix
room_changed:
		.byte $00		// nonzero when movement changed the current room
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
		.import source "../res/maps/char_map_0.asm"
