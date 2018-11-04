; Part 0: Part loader, music routine and music data

	.include "gvars.asm"
	
*	= runDemo
	; util functions jump table
	jmp runDemo_
	jmp initQSTable_
	jmp disnmi_
	jmp loadSineTable_
updateMusic_
	.include "mptplfox.asm" ; player routine
msx	.binary "czujeszt.mpc"

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
	
disnmi_
	; safely turns off nmi without missing the interrupt
	ldy #5
	sta rWSYNC
-	dey
	bne -
	sty rNMIEN
	rts
	
loadSineTable_
	; fill SineTable with the data in sine_unmoved
	; sine_unmoved contains only the first π/2 region
	; but due to how sine function works it's possible to expand it to the full 2π range
	; a = destination table's page
	sta _dst0+1
	sta _dst1+1
	sta _dst2+1
	sta _dst3+1
	sta _dst4+1
	sta _dst5+1
	ldx #0
	ldy #64
-	lda _dat, x
	sta $ff00, x
_dst0 = *-2
	sta $ff40, y
_dst1 = *-2
	neg
	sta $ff80, x
_dst2 = *-2
	beq + ; don't write to dst+$100
	sta $ffc0, y
_dst3 = *-2
+	inx
	dey
	bne -
	; these two addresses are not filled by the above loop
	lda #127
	sta $ff40
_dst4 = *-2
	lda #-128
	sta $ffc0
_dst5 = *-2
	rts
_dat .block
	; sin(x*2π/256)*128
_x := 0
	.rept 64
	.byte sin(rad(_x*360.0/256.0))*128
_x := _x + 1
	.next
	.bend
	
runDemo_
	; init player variables
	; part ord
	;  1   $00
	;  2   $05
	;  3   $09
	;  4   $0b
	;  5   $11
	;  6   $15
	;  7   $23
	;  8   $25
	;  9   $30
	mvx #0, pozsng
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
	
	; count extended ram size
ext_b  = $4000
detect_ext
	lda rPORTB
	pha
	mva #$ff, rPORTB
	lda ext_b
	pha

	ldx #$0f  ;remember ext bytes (from 16 blocks of 64kb)
-	jsr setpb
	mva ext_b, bsav,x
	dex
	bpl -

	ldx #$0f  ;zeroing them (because you dont know
-	jsr setpb ;which PORTB bit combinations enable which banks)
	mva #$00, ext_b
	dex
	bpl -

	stx rPORTB ;eliminate basic memory
	stx ext_b
	stx $00	  ;required for some 256k expansions

	ldy #$00  ;loop counting 64k blocks
	ldx #$0f
-	jsr setpb
	lda ext_b ;if ext_b is non-zero, block is counted
	bne +
	dec ext_b ;otherwise mark as counted
	lda ext_b ;check if it's smarked (if not, hardware is borked)
	bpl +
	iny
+	dex
	bpl -

	ldx #$0f ;restore ext value
-	jsr setpb
	mva bsav,x, ext_b
	dex
	bpl -

	stx rPORTB ;X=$FF
	pla
	sta ext_b
	pla
	sta rPORTB
	sty z64ksOfGay
	
	ldx #0
	geq loader
loop
	sei
	jsr disnmi_
	sty rDMACTL ; turn off all DMAs for faster decompression
	; os rom swap out is done in part 1
	; uncomment this when debugging each parts
	mva #$fe, rPORTB
	mwa #defaultvbi, rNMI
	; mva #$40, rNMIEN
loader
	lda compressedPartAddresses,x
	sta zARG0
	inx
	lda compressedPartAddresses,x
	sta zARG0+1
	inx
	lda compressedPartAddresses,x
	sta zARG1
	sta _entry
	inx
	lda compressedPartAddresses,x
	sta zARG1+1
	sta _entry+1
	inx
	txa
	pha
	jsr decompress ; decompress the part
	jsr partEntry ; call the part
_entry = *-2
	pla
	tax
	jmp loop

setpb
	txa ;change bits order: %0000dcba -> %cba000d0
	lsr	     
	ror
	ror
	ror
	adc #$01 ;set bit 1 relative to C sstate
	ora #$01 ;set OS ROM control bit to default value
	sta rPORTB
	rts
	
	; keep music running while the part is being decompressed
defaultvbi
	sta nmiA
	stx nmiX
	sty nmiY
	jsr updateMusic_
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
bsav	.byte 16
	
	.cerror curVol != volume, format("curVol (%#04x) and volume (%#04x) pointers mismatch", curVol, volume)
	.cerror * > compressedPartAddresses, format("Music data is too large and goes over compressedPartAddresses by %d bytes", * - compressedPartAddresses)
