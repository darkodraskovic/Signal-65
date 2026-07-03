// Room selection, display, and room-local coordinate helper macros.

.macro select_room_axis(worldCoord, halfSpriteSize, roomSize, roomCount, roomIndex) {
		copy_word(worldCoord, calc_word)
		add_word_value(calc_word, halfSpriteSize)
loop:
		lda roomIndex
		cmp #(roomCount - 1)
		beq done
		lda calc_word+1
		cmp #>roomSize
		bcc done
		bne next_room
		lda calc_word
		cmp #<roomSize
		bcc done
next_room:
		subtract_word_value(calc_word, roomSize)
		inc roomIndex
		jmp loop
done:
}

.macro calculate_room_id(roomCol, roomRow, roomId) {
		ldx roomRow
		lda room_row_offset,x
		clc
		adc roomCol
		sta roomId
}

.macro select_player_room() {
		lda #$00
		sta desired_room_col
		sta desired_room_row

		select_room_axis(player_world_x, SPRITE_WIDTH / 2, BACKGROUND_WIDTH, ROOM_COLUMNS, desired_room_col)
		select_room_axis(player_world_y, SPRITE_HEIGHT / 2, BACKGROUND_HEIGHT, ROOM_ROWS, desired_room_row)
		calculate_room_id(desired_room_col, desired_room_row, desired_room)
}

.macro convert_world_to_room_local(worldCoord, roomIndex, roomSize, localCoord) {
		copy_word(worldCoord, localCoord)
		ldx roomIndex
		beq done
subtract_room_size:
		subtract_word_value(localCoord, roomSize)
		dex
		bne subtract_room_size
done:
}

.macro display_room() {
		lda desired_room
		cmp current_room
		beq done
		sta current_room
		tax
		lda room_screen_lsb,x
		sta SCRNPTRLSB
		lda room_screen_msb,x
		sta SCRNPTRMSB
		lda room_screen_bank,x
		sta SCRNPTRBNK
		lda room_screen_mb,x
		sta SCRNPTRMB
done:
}
