; Part 0: Part loader, music routine and music data

	.include "gvars.asm"
	
*	= runDemo
	jmp runDemo_
updateMusic_
	.include "mptplfox.asm" ; player routine
msx	.binary "gowno.mpc"
	
runDemo_
; init player variables
	mvx #0, zCurMsxOrd
	mva #3, rSKCTL
	sta rSKCTL+$10
; conver the mpc file back to mpt
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
