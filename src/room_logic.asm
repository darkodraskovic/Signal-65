display_current_room:
		// Convert matrix coordinates to a linear room id:
		// room_id = player_room_row * ROOM_COLUMNS + player_room_col.
		lda player_room_col
		ldx player_room_row
!:
		cpx #$00
		beq !+
		clc
		adc #ROOM_COLUMNS
		dex
		bne !-
!:

		// Each room map is $400 bytes, so room_id * $400 means
		// adding room_id * 4 to the screen address middle byte.
		asl
		asl
		clc
		adc #>SCREEN_DATA
		sta SCRNPTRMSB
		lda #<SCREEN_DATA
		sta SCRNPTRLSB
		lda #(SCREEN_DATA >> 16)
		adc #$00
		sta SCRNPTRBNK
		lda #(SCREEN_DATA >> 24)
		sta SCRNPTRMB
		rts
