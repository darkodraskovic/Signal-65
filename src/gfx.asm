// MEGA65 / VIC-IV graphics registers.

.const VIC_KEY		= $d02f		// VIC-IV key register for MEGA65 knock sequences

.const BORDER_COLOR	= $d020		// screen border color register
.const BACKGROUND_COLOR	= $d021		// main background color register
.const COLOR_RAM	= $d800		// first 1024 color entries for 40x25 text mode

.const BACKGROUND_WIDTH	= 320		// 40 columns * 8 pixels
.const BACKGROUND_HEIGHT = 200		// 25 rows * 8 pixels
.const BACKGROUND_EDGE_LEFT = $18	// 40-column display left edge in sprite coordinates
.const BACKGROUND_EDGE_TOP = $32	// 25-row display top edge in sprite coordinates
.const BACKGROUND_EDGE_RIGHT = BACKGROUND_EDGE_LEFT + BACKGROUND_WIDTH // first pixel past the right edge
.const BACKGROUND_EDGE_BOTTOM = BACKGROUND_EDGE_TOP + BACKGROUND_HEIGHT // first pixel past the bottom edge

.const SPRITE_WIDTH	= $18		// standard hires sprite width: 24 pixels
.const SPRITE_HEIGHT	= $15		// standard sprite height: 21 pixels

.const VICIII_MODE	= $d031		// VIC-III mode register; bit 7 selects 80-column text

.const SCRNPTRLSB	= $d060		// low byte of screen map address
.const SCRNPTRMSB	= $d061		// middle byte of screen map address
.const SCRNPTRBNK	= $d062		// upper byte of screen map address
.const SCRNPTRMB	= $d063		// mega-byte bits of screen map address

.const CHARPTRLSB	= $d068		// low byte of character set address
.const CHARPTRMSB	= $d069		// middle byte of character set address
.const CHARPTRBNK	= $d06a		// upper byte of character set address

.const SPRPTRADRLSB	= $d06c		// low byte of sprite pointer table address
.const SPRPTRADRMSB	= $d06d		// middle byte of sprite pointer table address
.const SPRPTRBNK	= $d06e		// upper bits of sprite pointer table address
.const SPRITE_ENABLE	= $d015		// sprite enable bits; bit 0 enables sprite 0

.const SPRITE0_X	= $d000		// sprite 0 horizontal position register
.const SPRITE0_Y	= $d001		// sprite 0 vertical position register
.const SPRITE_X_MSB	= $d010		// sprite X high bits; bit 0 belongs to sprite 0
.const SPRITE0_COLOR	= $d027		// sprite 0 color register

.const RASTER		= $d012		// low byte of current raster line

// MEGA65 / VIC-IV graphics macros.

.macro gfx_unlock_vic4() {
		lda #$47		// first MEGA65 VIC-IV knock byte: "G"
		sta VIC_KEY		// write it to $d02f
		lda #$53		// second MEGA65 VIC-IV knock byte: "S"
		sta VIC_KEY		// VIC-IV extended registers are now accessible
}

.macro gfx_init_vic4_sprites(spritePointerAddress, spritePointerBank) {
		gfx_unlock_vic4()	// make VIC-IV registers visible before writing $d06c-$d06e

		lda #<spritePointerAddress // sprite pointer table address low byte
		sta SPRPTRADRLSB	// set $d06c
		lda #>spritePointerAddress // sprite pointer table address high byte
		sta SPRPTRADRMSB	// set $d06d
		lda #spritePointerBank	// sprite pointer table address bank bits
		sta SPRPTRBNK		// set $d06e; bit 7 remains 0 for 8-bit sprite pointers
}

.macro gfx_set_40_column_text() {
		lda VICIII_MODE		// read current VIC-III text-mode flags
		and #%01111111		// clear H640 so the map is interpreted as 40 columns
		sta VICIII_MODE		// apply 40-column text mode
}

.macro gfx_set_charset_address(charsetAddress) {
		lda #<charsetAddress	// character set address low byte
		sta CHARPTRLSB		// set $d068
		lda #>charsetAddress	// character set address middle byte
		sta CHARPTRMSB		// set $d069
		lda #charsetAddress >> 16 // character set address upper byte
		sta CHARPTRBNK		// set $d06a
}
