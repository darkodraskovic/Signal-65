// Generic 16-bit helper macros.

.macro copy_word(sourceAddress, targetAddress) {
		lda sourceAddress
		sta targetAddress
		lda sourceAddress+1
		sta targetAddress+1
}

.macro add_word_value(targetAddress, value) {
		lda targetAddress
		clc
		adc #<value
		sta targetAddress
		lda targetAddress+1
		adc #>value
		sta targetAddress+1
}

.macro subtract_word_value(targetAddress, value) {
		lda targetAddress
		sec
		sbc #<value
		sta targetAddress
		lda targetAddress+1
		sbc #>value
		sta targetAddress+1
}
