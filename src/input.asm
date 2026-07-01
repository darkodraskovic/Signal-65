// MEGA65 keyboard input registers.

.const KEY_MATRIX_DATA	= $d613		// selected C65 matrix column row bits; 0 = pressed
.const KEY_MATRIX_SELECT = $d614	// C65 matrix column select; write column number 0-8

// column 1 rows, bits 0-7: 3, W, A, 4, Z, S, E, left shift.
// column 2 rows, bits 0-7: 5, R, D, 6, C, F, T, X.

.const KEY_A_MASK	= %00000100	// A row bit when column 1 is selected
.const KEY_D_MASK	= %00000100	// D row bit when column 2 is selected
.const KEY_W_MASK	= %00000010	// W row bit when column 1 is selected
.const KEY_S_MASK	= %00100000	// S row bit when column 1 is selected

// MEGA65 keyboard input macros.

.macro input_read_column(columnSelect, columnState) {
		lda #columnSelect	// select C65 keyboard matrix column
		sta KEY_MATRIX_SELECT
		lda KEY_MATRIX_DATA	// read selected column row bits
		sta columnState		// keep column bits for key tests
}
