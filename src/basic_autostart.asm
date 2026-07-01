		* = $2001		// BASIC autostart stub: BANK 0:SYS <start address>

		.word basend		// next BASIC line
		.word 1206		// line #
		.byte $fe,$02,$30	// BANK 0
		.byte $3a,$9e		// :SYS
		.text toIntString(start)// address as string
		.byte 0			// end of line
basend:		.byte 0,0		// end of basic
