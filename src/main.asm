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

.const ROOM_COLUMNS	= 2		// generated room columns in the world grid
.const ROOM_ROWS	= 2		// generated room rows in the world grid

.const WORLD_WIDTH	= BACKGROUND_WIDTH * ROOM_COLUMNS // complete world width in pixels
.const WORLD_HEIGHT	= BACKGROUND_HEIGHT * ROOM_ROWS // complete world height in pixels
.const INITIAL_PLAYER_WORLD_X = $0068 // initial player X position in world coordinates
.const INITIAL_PLAYER_WORLD_Y = $003e // initial player Y position in world coordinates
.const PLAYER_SPEED	= $02		// pixels moved per frame

// -------------------------------------------
// Imports
// -------------------------------------------

		.import source "input.asm"
		.import source "utils.asm"
		.import source "player_logic.asm"
		.import source "room_logic.asm"
		.import source "basic_autostart.asm"

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

		lda #<INITIAL_PLAYER_WORLD_X // initial world X low byte
		sta player_world_x
		lda #>INITIAL_PLAYER_WORLD_X // initial world X high byte
		sta player_world_x+1
		lda #<INITIAL_PLAYER_WORLD_Y // initial world Y low byte
		sta player_world_y
		lda #>INITIAL_PLAYER_WORLD_Y // initial world Y high byte
		sta player_world_y+1
		jsr update_player_room
		jsr update_player_screen_pos
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

		move_player_if_pressed(key_col_1, KEY_A_MASK, SPRITE_LEFT, dec_player_world_x)
		move_player_if_pressed(key_col_2, KEY_D_MASK, SPRITE_RIGHT, inc_player_world_x)
		move_player_if_pressed(key_col_1, KEY_W_MASK, SPRITE_UP, dec_player_world_y)
		move_player_if_pressed(key_col_1, KEY_S_MASK, SPRITE_DOWN, inc_player_world_y)

		jsr update_player_room
		jsr update_player_screen_pos
		sync_player_sprite()
		rts

inc_player_world_x:
		move_world_coord(player_world_x, clamp_player_world_x, PLAYER_SPEED)

dec_player_world_x:
		move_world_coord(player_world_x, clamp_player_world_x, -PLAYER_SPEED)

inc_player_world_y:
		move_world_coord(player_world_y, clamp_player_world_y, PLAYER_SPEED)

dec_player_world_y:
		move_world_coord(player_world_y, clamp_player_world_y, -PLAYER_SPEED)

clamp_player_world_x:
		clamp_world_coord(player_world_x, WORLD_WIDTH - SPRITE_WIDTH)

clamp_player_world_y:
		clamp_world_coord(player_world_y, WORLD_HEIGHT - SPRITE_HEIGHT)

update_player_room:
		select_player_room()
		display_room()
		rts

update_player_screen_pos:
		convert_world_to_room_local(player_world_x, desired_room_col, BACKGROUND_WIDTH, player_screen_x)
		add_word_value(player_screen_x, BACKGROUND_EDGE_LEFT)

		convert_world_to_room_local(player_world_y, desired_room_row, BACKGROUND_HEIGHT, calc_word)
		add_word_value(calc_word, BACKGROUND_EDGE_TOP)
		lda calc_word		// copy screen Y low byte to sprite state
		sta player_screen_y
		rts

// -------------------------------------------
// Room Display Tables
// -------------------------------------------

		.import source "room_tables.asm"

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

player_world_x:
		.word INITIAL_PLAYER_WORLD_X // current player X in world coordinates
player_world_y:
		.word INITIAL_PLAYER_WORLD_Y // current player Y in world coordinates
player_screen_x:
		.word $0000		// current player X in sprite/screen coordinates
player_screen_y:
		.byte $00		// current player Y in sprite/screen coordinates
current_room:
		.byte $ff		// currently displayed room id; $ff forces first display update
desired_room:
		.byte $00		// room id selected from player world position
desired_room_col:
		.byte $00		// room column selected from player world position
desired_room_row:
		.byte $00		// room row selected from player world position
calc_word:
		.word $0000		// scratch word for coordinate conversion
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
