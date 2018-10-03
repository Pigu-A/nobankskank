; Part 0: Part loader, music routine and music data

	.include "gvars.asm"
	
*	= runDemo
	; util functions jump table
	jmp runDemo_
	jmp initQSTable_
updateMusic_
	.include "mptplfox.asm" ; player routine
msx	.binary "gowno.mpc"

initQSTable_
	; fill (zARG0) and (zARG0)+256 with x²/256
	; and also install it to zARG2 and zARG3
	; this is used for fast 8-bit*8-bit unsigned multiplication
	; zARG0 = destination table's page
	; zARG1 = positive entries count (anything higher than this is negative)
	mvx zARG0, _pdst1+1
	stx _ndst1+1 
	inx ; make a copy on the next page for negative offset support too
	stx _pdst2+1
	stx _ndst2+1 
	mvx
	mva #-1, zTMP2
	sta zTMP3
	mva #1, zTMP0
	mva #0, zTMP1
	tax
	tay
-	addw zTMP2, zTMP0
	sta $ff00,x
_pdst1 = *-2	
	sta $ff00,x
_pdst2 = *-2	
	cpy zARG1
	bcc + ; don't store if index y is below zARG1
	sta $ff00,y
_ndst1 = *-2	
	sta $ff00,y
_ndst2 = *-2	
+	addw #2, zTMP2
	dey
	inx
	cpx zARG1
	bne -
	mva zARG0, zARG2+1
	sta zARG3+1
	rts
	
runDemo_
	; init player variables
	mvx #0, zCurMsxOrd
	mva #3, rSKCTL
	sta rSKCTL+$10
	; convert the mpc file back to mpt
	mva msx+$1c8, lenpat
	ldx msx+$1c9
	dex
	stx tempo
	ldx #$c0 ; instrument pointers
-	lda msx-2,x
	ora msx-1,x
	beq + ; skip empty slot
	clc
	lda msx-2,x
	adc <#msx
	sta msx-2,x
	lda msx-1,x
	adc >#msx
	sta msx-1,x
+	dex
	dex
	bne -
	ldx #0 ; tuning table
-	txa
	and #$3f ; start of table
	bne +
	ldy msx+$c0,x
	jmp ++
+	tya
	clc
	adc msx+$c0,x
	sta msx+$c0,x
	tay
+	inx
	bne -
	ldx #4 ; pattern pointers
-	clc
	lda msx+$1bf,x
	adc <#msx
	sta msx+$1bf,x
	lda msx+$1c3,x
	adc >#msx
	sta msx+$1c3,x
	dex
	bne -
	
	ldx #0
-	lda compressedPartAddresses,x
	sta zARG0
	inx
	lda compressedPartAddresses,x
	sta zARG0+1
	inx
	mwa #partEntry, zARG1
	txa
	pha
	jsr decompress ; decompress the part
	jsr partEntry ; call the part
	; disable all interrupts
	mva #0, rNMIEN
	sei
	pla
	tax
	jmp -
	
	.cerror * > compressedPartAddresses, format("Music data is too large and goes over compressedPartAddresses by %d bytes", * - compressedPartAddresses)
