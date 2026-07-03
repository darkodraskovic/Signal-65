// Generated room lookup tables.

room_screen_lsb:
.for (var room = 0; room < ROOM_COLUMNS * ROOM_ROWS; room++) {
		.byte <(SCREEN_DATA + room * ROOM_SCREEN_BYTES)
}

room_screen_msb:
.for (var room = 0; room < ROOM_COLUMNS * ROOM_ROWS; room++) {
		.byte >(SCREEN_DATA + room * ROOM_SCREEN_BYTES)
}

room_screen_bank:
.for (var room = 0; room < ROOM_COLUMNS * ROOM_ROWS; room++) {
		.byte (SCREEN_DATA + room * ROOM_SCREEN_BYTES) >> 16
}

room_screen_mb: // megabyte bits
.for (var room = 0; room < ROOM_COLUMNS * ROOM_ROWS; room++) {
		.byte (SCREEN_DATA + room * ROOM_SCREEN_BYTES) >> 24
}

room_row_offset:
.for (var row = 0; row < ROOM_ROWS; row++) {
		.byte row * ROOM_COLUMNS
}
