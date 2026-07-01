// a tiny MEGA65 sprite test

		.cpu _45gs02

.const SPRITE_POINTER0	= $07f8		// game-chosen address for sprite 0's pointer byte
.const SPRITE_DATA	= $2100		// game-chosen sprite data address; 64-byte aligned
.const CHARSET_DATA	= $2800		// game-chosen address for custom 8x8 character glyphs
.const SCREEN_DATA	= $2c00		// game-chosen address for generated screen maps

		.import source "gfx.asm"
		.import source "basic_autostart.asm"

// -------------------------------------------

		* = $2011
start:
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

		lda #$80		// sprite 0 X position
		sta SPRITE0_X		// move sprite 0 horizontally
		lda #$70		// sprite 0 Y position
		sta SPRITE0_Y		// move sprite 0 vertically
		lda #$11		// sprite 0 color
		sta SPRITE0_COLOR	// apply sprite 0 color

		lda #SPRITE_DATA / $40	// sprite pointer value: $2100 / $40 = $84
		sta SPRITE_POINTER0	// store sprite 0 pointer byte at $07f8

		lda #%00000001		// enable only sprite 0
		sta SPRITE_ENABLE	// bit 0 on means sprite 0 visible

done:
		jmp *			// wait forever with background and sprite visible

		* = SPRITE_DATA		// generated sprite data starts at $2100
		.import source "../res/gfx/sprites_hires_4x4.asm"

		* = CHARSET_DATA	// generated custom charset starts at $2800

charset_hires_16x8:
		.import source "../res/gfx/chars_hires_16x8.asm"

		* = SCREEN_DATA		// generated screen maps start at $2c00
		.import source "../res/maps/char_map_1.asm"
