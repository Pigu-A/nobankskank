; global.functions including pseudo instructions

; determine if word a is 2-byte immediate value or memory address of 2-byte data
; then return the correct lower byte or upper byte
lo	.function a
	b := a ; a
	.if type(a) == address
	b := <a ; #a
	.fi
	.endf b

hi	.function a
	b := a+1 ; a
	.if type(a) == address
	b := >a ; #a
	.fi
	.endf b

; stupid 6502
add	.function a
	clc
	adc a
	.endf
	
sub	.function a
	sec
	sbc a
	.endf

mva	.function s, d
	lda s
	sta d
	.endf

mvx	.function s, d
	ldx s
	stx d
	.endf

mvy	.function s, d
	ldy s
	sty d
	.endf
	
neg .function x=-1
	.if x == -1 ; acc
	eor #$ff
	add #1
	.else ; abs/zp
	lda x
	eor #$ff
	sta x
	inc x
	.fi
	.endf

pusha .function
	pha
	txa
	pha
	tya
	pha
	.endf

popa .function
	pla
	tay
	pla
	tax
	pla
	.endf

; 16-bit expansions
mwa	.function s, d
	mva lo(s), d
	mva hi(s), d+1
	.endf

mwx	.function s, d
	mvx lo(s), d
	mvx hi(s), d+1
	.endf

mwy	.function s, d
	mvy lo(s), d
	mvy hi(s), d+1
	.endf

adcw	.function v, s, d=-1
	dd := d
	.if d == -1
	dd := s
	.fi
	lda lo(s)
	adc lo(v)
	sta dd
	lda hi(s)
	adc hi(v)
	sta dd+1
	.endf
	
addw	.function v, s, d=-1
	clc
	adcw v, s, d
	.endf

sbcw	.function v, s, d=-1
	dd := d
	.if d == -1
	dd := s
	.fi
	lda lo(s)
	sbc lo(v)
	sta dd
	lda hi(s)
	sbc hi(v)
	sta dd+1
	.endf
	
subw	.function v, s, d=-1
	sec
	sbcw v, s, d
	.endf
	
cmpw	.function a, b
	lda hi(b)
	cmp hi(b)
	bne _x
	lda lo(b)
	cmp lo(b)
_x
	.endf

tstw	.function a
	lda a
	ora a+1
	.endf

incw	.function a
	inc a
	bne _x
	inc a+1
_x
	.endf

decw	.function a
	sec
	lda a
	sbc #1
	sta a
	lda a+1
	sbc #0
	sta a+1
	.endf

rolw	.function a
	rol a
	rol a+1
	.endf

aslw	.function a
	asl a
	rol a+1
	.endf

lsrw	.function a
	lsr a+1
	ror a
	.endf

rorw	.function a
	ror a+1
	ror a
	.endf
	
; adjust a constant 2-bytes length to fit the 2 vars loop
wordloopadj	.function a
	b := a + $100
	.ifeq <a
	b := a
	.fi
	.endf b
	
; get tilemap offset from 20 chars text mode
coord20	.function x, y, o=0
	.endf y * 20 + x + o
	
; get tilemap offset from 40 chars text mode
coord40	.function x, y, o=0
	.endf y * 40 + x + o

