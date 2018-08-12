; DED/Huffman decoding routines
; DED format is fixed to 4-bit samples right now and will be ORed with $10 for direct write to AUDCx
; [[decodedlen]] [lenbits]..*16 [bitstream]...
; Huff format is
; [[decodedlen]] [maxlen] [numcodes]..*maxlen [codes]..*sum(numcodes) [bitstream]...
; decodes data from (zARG0) to (zARG1)
; requires 768 bytes maximum of codebook memory (currently 384)

datacountLo	= zTMP6
datacountHi	= zTMP7

deDED	.block
	jsr ded.getDecodedLen
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
	jsr ded.addNode
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
-	jsr ded.addInternal
	dec zTMP4
	bne -
+	lda zTMP1
	inc zTMP1
	cmp #1
_maxlen = *-1
	bne _nodeTableLoop
	addw #18, zARG0, ded.bitstream
	
	; time to decode the bitstream
	mva #1, zTMP0 ; force getting the first byte for the first time
	mva #8, zTMP2 ; output value
	ldy #0 ; destination index
_loop
	jsr ded.getDecodedByte
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
	.bend
	
deHuff	.block
	jsr ded.getDecodedLen
	addw #3, zARG0, _bookCounts
	ldy #2
	sty zTMP0 ; internal nodes left for this level
	lda (zARG0),y ; maxlen
	sta zTMP1
	add _bookCounts
	sta _bookCodes
	lda _bookCounts+1
	adc #0
	sta _bookCodes+1
	mva #0, zTMP2 ; nodeTable position
	sta zTMP5 ; internal nodes count
	tax ; bit length of n position
	tay ; code list position
_nodeTableLoop
	lda $ffff,x
_bookCounts = *-2
	stx zTMP3 ; back up x value
	cmp #0
	beq +
	sta zTMP4
	; add leaf node to nodeTable
-	lda $ffff,y
_bookCodes = *-2
	clc
	jsr ded.addNode
	iny
	dec zTMP0
	dec zTMP4
	bne -
+	lda zTMP0
	beq +
	sta zTMP4
	asl a ; x2
	sta zTMP0
	; add internal node to nodeTable
-	jsr ded.addInternal
	dec zTMP4
	bne -
+	ldx zTMP3
	inx
	dec zTMP1
	bne _nodeTableLoop
	; _bookCodes+y is now at the start of bitstream
	tya
	add _bookCodes
	sta ded.bitstream
	lda _bookCodes+1
	adc #0
	sta ded.bitstream+1
	
	; time to decode the bitstream
	mva #1, zTMP0 ; force getting the first byte for the first time
	ldy #0 ; destination index
_loop
	jsr ded.getDecodedByte
	sta (zARG1),y
	iny
	bne +
	inc zARG1+1
+	dec	datacountLo
	bne _loop
	dec datacountHi
	bne _loop
	rts
	.bend
	
ded	.block
getDecodedLen
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
	rts
	
getDecodedByte
	ldx #0
_loop	
	dec zTMP0
	bne ++
	; get the next byte
	lda $ffff
bitstream = *-2
	sta zTMP1
	inc bitstream
	bne +
	inc bitstream+1
+	mva #8, zTMP0
+	asl zTMP1
	lda nodeTableA,x
	bcs _1
_0
	and #2
	beq +
	lda nodeTable0,x
	tax
	bcc _loop
+	lda nodeTable0,x
	rts
_1
	and #1
	beq +
	lda nodeTable1,x
	tax
	bcs _loop
+	lda nodeTable1,x
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
	.bend
	
; 128 nodes max right now, compressed text shouldn't exceed this
	.align $80
nodeTable0	.fill 128
nodeTable1	.fill 128
nodeTableA	.fill 128
	