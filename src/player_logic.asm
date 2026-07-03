// Player movement and sprite helper macros.

.macro sync_player_sprite() {
		lda player_screen_x	// copy screen X low byte to sprite hardware
		sta SPRITE0_X
		lda SPRITE_X_MSB	// preserve other sprites' X high bits
		and #%11111110		// clear sprite 0 high bit
		ldx player_screen_x+1	// sprite 0 needs the high bit when X >= 256
		beq !+
		ora #%00000001		// set sprite 0 high bit
!:
		sta SPRITE_X_MSB
		lda player_screen_y	// copy screen Y to sprite hardware
		sta SPRITE0_Y
}

.macro move_player_if_pressed(columnState, keyMask, spritePointer, moveRoutine) {
		lda columnState		// test cached keyboard matrix column bits
		and #keyMask		// key pressed?
		bne !+
		lda #spritePointer	// face the direction being moved
		sta SPRITE_POINTER0
		jsr moveRoutine		// update and clamp world coordinates
!:
}

.macro move_world_coord(coordAddress, clampRoutine, delta) {
		lda coordAddress	// update low byte
.if (delta > 0) {
		clc
		adc #delta
		sta coordAddress
		bcc !+
		inc coordAddress+1	// carry across 255
} else {
		sec
		sbc #(-delta)
		sta coordAddress
		bcs !+
		dec coordAddress+1	// borrow below a page boundary
}
!:
		jmp clampRoutine	// normalize to world bounds
}

.macro clamp_world_coord(coordAddress, maxValue) {
		lda coordAddress+1	// underflow wraps high byte to $ff
		bmi to_min
		cmp #>maxValue
		bcc done
		bne to_max
		lda coordAddress
		cmp #<maxValue
		bcc done
		beq done
to_max:
		lda #<maxValue
		sta coordAddress
		lda #>maxValue
		sta coordAddress+1
		rts
to_min:
		lda #$00
		sta coordAddress
		sta coordAddress+1
		rts
done:
		rts
}
