p0:
	.byte %10001000
	.byte %10001000
	.byte %11101000
	.byte %10101000
	.byte %11101000
p1:
	.byte %10001110
	.byte %10001000
	.byte %11101110
	.byte %10100010
	.byte %11101110
p2:
	.byte %10001110
	.byte %10000010
	.byte %11100110
	.byte %10100010
	.byte %11101110
p3:
	.byte %10000010
	.byte %10000010
	.byte %11101110
	.byte %10101010
	.byte %11101010



; 0 to 99 in 50 bytes
; 00 to FF in 75 bytes

digits:
	; 00
	.byte %01110111
	.byte %01010101
	.byte %01010101
	.byte %01010101
	.byte %01110111
	; 11
	.byte %00010001
	.byte %00010001
	.byte %00010001
	.byte %00010001
	.byte %00010001
	; 22
	.byte %01110111
	.byte %00010001
	.byte %01110111
	.byte %01000100
	.byte %01110111
	; 33
	.byte %01110111
	.byte %00010001
	.byte %00110011
	.byte %00010001
	.byte %01110111
	; 44
	.byte %01010101
	.byte %01010101
	.byte %01110111
	.byte %00010001
	.byte %00010001
	; 55
	.byte %01110111
	.byte %01000100
	.byte %01110111
	.byte %00010001
	.byte %01110111
	; 66
	.byte %01110111
	.byte %01000100
	.byte %01110111
	.byte %01010101
	.byte %01110111
	; 77
	.byte %01110111
	.byte %00010001
	.byte %00010001
	.byte %00010001
	.byte %00010001
	; 88
	.byte %01110111
	.byte %01010101
	.byte %01110111
	.byte %01010101
	.byte %01110111
	; 99
	.byte %01110111
	.byte %01010101
	.byte %01110111
	.byte %00010001
	.byte %01110111
	; AA
	.byte %00100010
	.byte %01010101
	.byte %01110111
	.byte %01010101
	.byte %01010101
	; BB
	.byte %01100110
	.byte %01010101
	.byte %01100110
	.byte %01010101
	.byte %01100110
	; CC
	.byte %01110111
	.byte %01000100
	.byte %01000100
	.byte %01000100
	.byte %01110111
	; DD
	.byte %01100110
	.byte %01010101
	.byte %01010101
	.byte %01010101
	.byte %01100110
	; EE
	.byte %01110111
	.byte %01000100
	.byte %01100110
	.byte %01000100
	.byte %01110111
	; FF
	.byte %01110111
	.byte %01000100
	.byte %01100110
	.byte %01000100
	.byte %01000100
