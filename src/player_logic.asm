// Player movement and sprite helper macros.

.macro sync_player_sprite() {
		lda player_x	// copy screen X low byte to sprite hardware
		sta SPRITE0_X
		lda SPRITE_X_MSB	// preserve other sprites' X high bits
		and #%11111110		// clear sprite 0 high bit
		ldx player_x+1	// sprite 0 needs the high bit when X >= 256
		beq !+
		ora #%00000001		// set sprite 0 high bit
!:
		sta SPRITE_X_MSB
		lda player_y	// copy screen Y to sprite hardware
		sta SPRITE0_Y
}

.macro move_player_if_pressed(columnState, keyMask, spritePointer, moveRoutine) {
		lda columnState		// test cached keyboard matrix column bits
		and #keyMask		// key pressed?
		bne !+
		lda #spritePointer	// face the direction being moved
		sta SPRITE_POINTER0
		jsr moveRoutine		// update local position and room state
!:
}

move_player_left:
		// If another room exists to the left, crossing past the transition
		// threshold moves into it; otherwise the matrix edge clamps X.
		lda player_room_col
		beq move_player_left_matrix_edge
		lda player_x+1
		bne move_player_left_step
		lda player_x
		cmp #PLAYER_EXIT_LEFT_TRIGGER
		bcs move_player_left_step
		// Enter the room on the left from its right side.
		dec player_room_col
		inc room_changed
		lda #<PLAYER_ENTRY_RIGHT
		sta player_x
		lda #>PLAYER_ENTRY_RIGHT
		sta player_x+1
		rts
move_player_left_matrix_edge:
		// No room exists to the left, so only allow movement down to PLAYER_MIN_X.
		lda player_x+1
		bne move_player_left_step
		lda player_x
		cmp #PLAYER_CLAMP_LEFT_TRIGGER
		bcs move_player_left_step
		jmp clamp_player_left
move_player_left_step:
		// Normal in-room left movement, including borrow into the X high byte.
		lda player_x
		sec
		sbc #PLAYER_SPEED
		sta player_x
		bcs move_player_left_done
		dec player_x+1
move_player_left_done:
		rts
clamp_player_left:
		lda #<PLAYER_MIN_X
		sta player_x
		lda #>PLAYER_MIN_X
		sta player_x+1
		rts

move_player_right:
		// Right movement mirrors left movement, but X needs a 16-bit compare
		// because the right edge sits beyond 255.
		lda player_room_col
		cmp #(ROOM_COLUMNS - 1)
		beq move_player_right_matrix_edge
		lda player_x+1
		cmp #>PLAYER_EXIT_RIGHT_TRIGGER
		bcc move_player_right_step
		bne move_player_right_boundary
		lda player_x
		cmp #<PLAYER_EXIT_RIGHT_TRIGGER
		bcc move_player_right_step
move_player_right_boundary:
		// Enter the room on the right from its left side.
		inc player_room_col
		inc room_changed
		lda #<PLAYER_ENTRY_LEFT
		sta player_x
		lda #>PLAYER_ENTRY_LEFT
		sta player_x+1
		rts
move_player_right_matrix_edge:
		// No room exists to the right, so clamp at PLAYER_MAX_X.
		lda player_x+1
		cmp #>PLAYER_CLAMP_RIGHT_TRIGGER
		bcc move_player_right_step
		bne clamp_player_right
		lda player_x
		cmp #<PLAYER_CLAMP_RIGHT_TRIGGER
		bcc move_player_right_step
		jmp clamp_player_right
move_player_right_step:
		// Normal in-room right movement, including carry into the X high byte.
		lda player_x
		clc
		adc #PLAYER_SPEED
		sta player_x
		bcc move_player_right_done
		inc player_x+1
move_player_right_done:
		rts
clamp_player_right:
		lda #<PLAYER_MAX_X
		sta player_x
		lda #>PLAYER_MAX_X
		sta player_x+1
		rts

move_player_up:
		// Y is 8-bit, so vertical movement only needs one compare.
		lda player_room_row
		beq move_player_up_matrix_edge
		lda player_y
		cmp #PLAYER_EXIT_TOP_TRIGGER
		bcs move_player_up_step
		// Enter the room above from its bottom edge.
		dec player_room_row
		inc room_changed
		lda #PLAYER_ENTRY_BOTTOM
		sta player_y
		rts
move_player_up_matrix_edge:
		// No room exists above, so clamp at PLAYER_MIN_Y.
		lda player_y
		cmp #PLAYER_CLAMP_TOP_TRIGGER
		bcs move_player_up_step
		jmp clamp_player_top
move_player_up_step:
		lda player_y
		sec
		sbc #PLAYER_SPEED
		sta player_y
		rts
clamp_player_top:
		lda #PLAYER_MIN_Y
		sta player_y
		rts

move_player_down:
		// Down movement mirrors up movement against the bottom of the room matrix.
		lda player_room_row
		cmp #(ROOM_ROWS - 1)
		beq move_player_down_matrix_edge
		lda player_y
		cmp #PLAYER_EXIT_BOTTOM_TRIGGER
		bcc move_player_down_step
		// Enter the room below from its top edge.
		inc player_room_row
		inc room_changed
		lda #PLAYER_ENTRY_TOP
		sta player_y
		rts
move_player_down_matrix_edge:
		// No room exists below, so clamp at PLAYER_MAX_Y.
		lda player_y
		cmp #PLAYER_CLAMP_BOTTOM_TRIGGER
		bcc move_player_down_step
		jmp clamp_player_bottom
move_player_down_step:
		lda player_y
		clc
		adc #PLAYER_SPEED
		sta player_y
		rts
clamp_player_bottom:
		lda #PLAYER_MAX_Y
		sta player_y
		rts
