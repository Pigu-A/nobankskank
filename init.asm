; entry point of this demo
	.include "gvars.asm"
	
; os memory stuff before we completely ditch it
zRAMTOP = $6a
wICCMD  = $342
wICBA   = $344
wICBL   = $348
CIOV    = $e456

*	= $02e0
	.word xexStart
	
*	= xexStart
	sei
	mva #0, rNMIEN
	lda #123 ; wait until out of screen
-	cmp rVCOUNT
	bcs -
	lda rPORTB
	pha
	and #$fe
	sta rPORTB
	; 64k xl/xe test
	mva #$72, CIOV
	cmp CIOV ; should be #$72 instead of #$4c (jmp) or #$ff
	bne notEnoughRam
	lda zRAMTOP
	cmp #$c0 ; value when booted in DOS with BASIC disabled and cart removed
	bcc removeCart
	pla
	sta rPORTB ; resore os rom for a while so blank charset won't flash while decompressing
	; move decompress routine
	_x := 0
	ldx #0
-	.rept >len(decompress_unmoved)
	lda decompress_unmoved+_x,x
	sta decompress+_x,x
	_x := _x + $100
	.next
	cpx #<len(decompress_unmoved)
	bcs +
	lda decompress_unmoved+_x,x
	sta decompress+_x,x
+	inx
	bne -
	; move compressedPartAddresses table
	ldx #NUM_PARTS*2
-	lda cpa_unmoved-1,x
	sta compressedPartAddresses-1,x
	dex
	bne	-
	; decompress part loader and jump to that
	mwa #part0_compressed, zARG0
	mwa #runDemo, zARG1
	jsr decompress
	jmp runDemo

notEnoughRam
	mwa #notEnoughRamText, wICBA
	mva #<size(notEnoughRamText), wICBL
	jmp putChar
	
removeCart
	mwa #removeCartText, wICBA
	mva #<size(removeCartText), wICBL
	jmp putChar
	
putChar
	mva #0, wICBL+1
	mva #$0b, wICCMD ; put characters
	pla
	sta rPORTB ; resore os rom and intterrupts
	mva #$40, rNMIEN
	cli
	ldx #0
	jmp CIOV ; bye
	
	.enc "atascii"
notEnoughRamText .text "Whoops! This demo needs 64k XL to run!"
removeCartText   .text "BOTB STRONG REMOVE CARTRIDGES\n"

decompress_unmoved	.logical decompress
	.include "65pkmlz.asm"
	.here

cpa_unmoved	.logical compressedPartAddresses
	; not including part 0
	.word part1_compressed
	.here
	.cerror size(cpa_unmoved) != NUM_PARTS*2, "Number of cpa_unmoved entries and NUM_PARTS mismatch"

part0_compressed .binary "0_loader_music.lz"
part1_compressed .binary "1_botb_logo.lz"