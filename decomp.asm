; LZ decompressing routine
; by Pigu, converted from Pokemon Crystal decompress code

LZ_END = #$ff ; Compressed data is terminated with $ff.

; A typical control command consists of:

LZ_CMD = #%11100000 ; command id (bits 5-7)
LZ_LEN = #%00011111 ; length n   (bits 0-4)

; Additional parameters are read during command execution.


; Commands:

LZ_LITERAL   = #0 << 5 ; Read literal data for n bytes.
LZ_ITERATE   = #1 << 5 ; Write the same byte for n bytes.
LZ_ALTERNATE = #2 << 5 ; Alternate two bytes for n bytes.
LZ_ZERO      = #3 << 5 ; Write 0 for n bytes.


; Another class of commands reuses data from the decompressed output.
LZ_RW        = #1 << 7

; These commands take a signed offset to start copying from.
; Wraparound is simulated.
; Positive offsets (15-bit) are added to the start address.
; Negative offsets (7-bit) are subtracted from the current position.

LZ_REPEAT    = #4 << 5 ; Repeat n bytes from the offset.
LZ_FLIP      = #5 << 5 ; Repeat n bitflipped bytes.
LZ_REVERSE   = #6 << 5 ; Repeat n bytes in reverse.


; If the value in the count needs to be larger than 5 bits,
; LZ_LONG can be used to expand the count to 10 bits.
LZ_LONG      = #7 << 5

; A new control command is read in bits 2-4.
; The top two bits of the length are bits 0-1.
; Another byte is read containing the bottom 8 bits.
LZ_LONG_HI   = #%00000011

; In other words, the structure of the command becomes
; 111xxxyy yyyyyyyy
; x: the new control command
; y: the length

; Memory used:

tlen   = zTMP0
;tmpdst .word ?
buffer = zTMP2 ; preferrably in zeropage

;src and dst must be in zeropage
src    = zARG0 ; source address
dst    = zARG1 ; destination address

; This function decompresses lz-compressed data from [src] to [dst].
decompress_	.block
	; Save the output address
	; for rewrite commands.
	lda dst
	sta tmpdstL
	lda dst+1
	sta tmpdstH
	ldy #0

main
	lda (src),y
	cmp LZ_END
	bne +
	rts
+
	and LZ_CMD

	cmp LZ_LONG
	bne short

long
; The count is now 10 bits.

	; Read the next 3 bits.
	; %00011100 -> %11100000
	lda (src),y
	clc
	asl a
	asl a ; << 3
	asl a

; This is our new control code.
	and LZ_CMD
	sta buffer

	lda (src),y
	iny
	and LZ_LONG_HI
	sta tlen
	lda (src),y
	iny

	; read at least 1 byte
	clc
	adc #1
	tax
	bcc command
	inc tlen
	jmp command

short
	sta buffer

	lda (src),y
	iny
	and LZ_LEN
	tax
	lda #0
	sta tlen

	; read at least 1 byte
	inx


command
	; Modify loop counts to support 8 bit loop counters
	inc tlen
	lda LZ_RW
	and buffer
	bne rewrite

	lda buffer
	cmp LZ_ITERATE
	beq iter
	cmp LZ_ALTERNATE
	beq alt
	cmp LZ_ZERO
	beq zero

; Read literal data for (tlen)x bytes.
literal
	jsr updatesrc
	jsr copy
	jmp updatesrcdst

copy
-	dec tlen
	beq +
-	lda (src),y
	sta (dst),y
	iny
	bne -
	inc src+1
	inc dst+1
	jmp --
+	txa
	beq --
-	lda (src),y
	sta (dst),y
	iny
	dex
	bne -
-	rts

iter
; Write the same byte for (tlen)x bytes.
	lda (src),y
	iny
	pha
	jsr updatesrc
	pla
zeroentrypoint
-	dec tlen
	beq +
-	sta (dst),y
	iny
	bne -
	inc dst+1
	jmp --
+	inx
	dex
	beq updatedst
-	sta (dst),y
	iny
	dex
	bne -
	jmp updatedst

alt
; Alternate two bytes for (tlen)x bytes.
	stx tlen+1
	ldx #0
	lda (src),y
	iny
	sta buffer
	lda (src),y
	iny
	sta buffer+1
	jsr updatesrc

-	dec tlen
	beq +
-	lda buffer,x
	sta (dst),y
	txa
	eor #1
	tax
	iny
	bne -
	inc dst+1
	jmp --
+	lda tlen+1
	beq updatedst
-	lda buffer,x
	sta (dst),y
	iny
	txa
	eor #1
	tax
	dec tlen+1
	bne -
	jmp updatedst


zero
; Write 0 for (tlen)x bytes.
	jsr updatesrc
	lda #0
	jmp zeroentrypoint

rewrite
; Repeat decompressed data from output.
	jsr updatesrc
	lda src
	pha
	lda src+1
	pha
	lda (src),y
	bpl positive

negative
; src = dst - (a & #$7f) - 1
	and #$7f
	sta buffer+1
	clc
	lda dst
	sbc buffer+1
	sta src
	lda dst+1
	sta src+1
	bcs ok
	dec src+1
	jmp ok

positive
; Positive offsets are two bytes.
; add to starting output address
	pha
	iny
	lda (src),y
	clc
	adc #0
tmpdstL = *-1
	sta src
	pla
	adc #0
tmpdstH = *-1
	sta src+1
	dey

ok
	lda buffer

	cmp LZ_FLIP
	beq flip
	cmp LZ_REVERSE
	beq reverse

; Since LZ_LONG is command 7,
; only commands 0-6 are passed in.
; This leaves room for an extra command 7.
; However, lengths longer than 768
; would be interpreted as LZ_END.

; More practically, LZ_LONG is not recursive.
; For now, it defaults to LZ_REPEAT.


repeat
; Copy decompressed data for (tlen)x bytes.
	jsr copy
	jmp donerw

flip
; Copy bitflipped decompressed data for (tlen)x bytes.
-	dec tlen
	beq +
-	jsr flip_
	bne -
	inc src+1
	inc dst+1
	jmp --
+	txa
	beq donerw
-	jsr flip_
	dex
	bne -
	jmp donerw

flip_
	lda (src),y
	sta buffer+1
	lda #0
.rept 8
	ror buffer+1 ; sorry pre-1976 cpus
	rol a
.next
	sta (dst),y
	iny
	rts

reverse
; Copy reversed decompressed data for (tlen)x bytes.
	txa
	sta tlen+1
	dec src+1
	inc src
	bne +
	inc src+1
+
-	dec tlen
	beq +
-	tya
	eor #$ff
	tay
	lda (src),y
	tax
	tya
	eor #$ff
	tay
	txa
	sta (dst),y
	iny
	bne -
	dec src+1
	inc dst+1
	jmp --
+	lda tlen+1
	beq donerw
-	tya
	eor #$ff
	tay
	lda (src),y
	tax
	tya
	eor #$ff
	tay
	txa
	sta (dst),y
	iny
	dec tlen+1
	bne -

donerw
	pla
	sta src+1
	pla
	sta src
	tya
	pha
	ldy #0
	lda (src),y
	bmi negofs
	iny ; positive offset is two bytes
negofs
	iny
	jsr updatesrc
	pla
	tay
	jmp updatedst

updatesrc
; update (src) = (src) + y, set y to 0 then return
	clc
	tya
	adc src
	sta src
	bcc +
	inc src+1
+	ldy #0
	rts

updatesrcdst
; update (src) = (src) + y
	clc
	tya
	adc src
	sta src
	bcc updatedst
	inc src+1

updatedst
; update (dst) = (dst) + y, set y to 0 then go to main
	clc
	tya
	adc dst
	sta dst
	bcc +
	inc dst+1
+	ldy #0
	jmp main
	.bend
	
; DED decoding routine
; DED format is fixed to 4-bit samples right now and will be ORed with $10 for direct write to AUDCx
; [[decodedlen]] [lenbits]..*16 [bitstream]...
; decodes data from (zARG0) to (zARG1)

datacountLo	.byte ?
datacountHi	.byte ?

deDED_	.block
	; get len from (zARG0) to datacount and adjust for two-level loop
	ldy #1
	lda (zARG0),y ; lenHi
	tax
	dey
	lda (zARG0),y ; lenLo
	beq +
	inx
+	sta datacountLo
	stx datacountHi
	lda #2
	sta zTMP3 ; internal nodes left for this level
	add zARG0
	sta _lenbits
	lda zARG0+1
	adc #0
	sta _lenbits+1
	lda #1
	sta zTMP1 ; current level
	mva #0, zTMP2 ; nodeTable position
	sta zTMP5 ; internal nodes count
_nodeTableLoop
	ldy #0
-	lda $ffff,y
_lenbits = *-2
	cmp _maxlen
	bcc +
	sta _maxlen
+	cmp zTMP1
	bne +
	; add leaf node to nodeTable
	tya
	clc
	jsr addNode
	dec zTMP3
+	iny
	cpy #16
	bne -
	lda zTMP3
	beq +
	sta zTMP4
	asl a ; x2
	sta zTMP3
	; add internal node to nodeTable
-	jsr addInternal
	dec zTMP4
	bne -
+	lda zTMP1
	inc zTMP1
	cmp #1
_maxlen = *-1
	bne _nodeTableLoop
	addw #18, zARG0, _bitstream
	
	; time to decode the bitstream
	mva #1, zTMP0 ; force getting the first byte for the first time
	mva #8, zTMP2 ; output value
	ldy #0 ; destination index
_loop
	ldx #0
_loop2
	dec zTMP0
	bne ++
	; get the next byte
	lda $ffff
_bitstream = *-2
	sta zTMP1
	inc _bitstream
	bne +
	inc _bitstream+1
+	mva #8, zTMP0
+	asl zTMP1
	lda nodeTableA,x
	bcs _1
_0
	and #2
	beq +
	lda nodeTable0,x
	tax
	bcc _loop2
+	lda nodeTable0,x
	rts
_1
	and #1
	beq +
	lda nodeTable1,x
	tax
	bcs _loop2
+	lda nodeTable1,x
	add zTMP2 ; apply delta
	and #15
	sta zTMP2
	ora #$10 ; force output
	sta (zARG1),y
	iny
	bne +
	inc zARG1+1
+	dec	datacountLo
	bne _loop
	dec datacountHi
	bne _loop
	rts
	
	; add a node then increase nodeTable position
addInternal
	inc zTMP5
	lda zTMP5
	sec
addNode
	; a = value/destination
	; carry = end/jump
	php
	pha
	lda zTMP2
	inc zTMP2
	lsr a
	tax
	pla
	bcs +
	sta nodeTable0,x
	bcc ++
+	sta nodeTable1,x
+	plp
	rol nodeTableA,x
	rts
	
	.align 16
; 16 nodes max right now, 4-bit wave shouldn't exceed this
nodeTable0	.fill 16
nodeTable1	.fill 16
nodeTableA	.fill 16
	.bend
	
	.cerror (deDED-decompress) != (deDED_-decompress_), format("decompress and deDED subroutine distance in gvars.asm (%d) and decomp.asm (%d) mismatch", deDED-decompress, deDED_-decompress_)
	.cerror * > runDemo, format("decomp code is too large and goes over runDemo by %d bytes", * - runDemo)
	