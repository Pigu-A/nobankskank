; Part 0: Part loader, music routine and music data

	.include "gvars.asm"
	
*	= runDemo
	jmp runDemo_
updateMusic_
	.include "mptplfox.asm" ; player routine
msxptr	.binary "RAVETARI.MPT", 2
msx = msxptr + 4
	
runDemo_
; init player variables
	mvx #0, zCurMsxOrd
	dex ; #$ff
	stx zCurMsxRow
	mva #3, rSKCTL
; patch the mpt file to reflect the new address
	mva msx+$1c8, lenpat
	ldx msx+$1c9
	dex
	stx tempo
	; zTMP0 = newaddr - oldaddr
	subw msxptr, #msx, zTMP0
	ldx #$c0 ; instrument pointers
-	lda msx-2,x
	ora msx-1,x
	beq + ; skip empty slot
	clc
	lda msx-2,x
	adc zTMP0
	sta msx-2,x
	lda msx-1,x
	adc zTMP1
	sta msx-1,x
+	dex
	dex
	bne -
	ldx #4 ; pattern pointers
-	clc
	lda msx+$1bf,x
	adc zTMP0
	sta msx+$1bf,x
	lda msx+$1c3,x
	adc zTMP1
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
	pla
	tax
	jmp -
	
	.cerror * > compressedPartAddresses, "Music data too large and goes over compressedPartAddresses by ", * - compressedPartAddresses, " bytes"
