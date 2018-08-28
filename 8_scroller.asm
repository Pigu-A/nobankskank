; Part 8: text scroller
	.include "gvars.asm"

VDSLST = $200
SDMCTL = $22f
SDLSTL = $230
GPRIOR = $26f
COLOR  = $2c0

SCROLL_SPEED = 3 ; please don't exceed 16
TEXT_Y = 64 ; starting y position of text

*	= $02e0
	.word start
	
*	= $2000
start
	lda <#dlist
	sta SDLSTL
	lda >#dlist
	sta SDLSTL+1
	mva #$0e, COLOR
	sta COLOR+1
	mva #$0c, COLOR+2
	sta COLOR+3
	mva #$1e, COLOR+4
	mva >#(player0-$200), rPMBASE
	mva #$01, GPRIOR ; all players above pf
	mva #$2a, SDMCTL ; enable player and dlist dma, normal pf, double line player
	mva #$02, rGRACTL ; turn on player
	
	; the current function for character x position table is
	; (x/128)³*32+x/2+124 for x = [-128,-127,..,128]
	; since (x/128)³*32 always increase by only 0 and 1 for this range of x
	; and x/2 increases constantly as repeating {0,1} sequence
	; we can compress the change of this function in bit table format
	; (-1 or 2 results can be smoothed out to the adjacent change)
	lda #28 ; f(-128)
	ldx #1 ; force getting the first byte for the first time
	ldy #0
-	dex
	bne +
	ldx chrxLUT_packed
_bs = *-2
	stx zTMP0
	inc _bs
	.if pagecross(chrxLUT_packed)
	bne _sk
	inc _bs+1
_sk	
	.fi
	ldx #4
+	asl zTMP0
	adc #0
	sta chrxLUT,y
	iny
	asl zTMP0
	adc #1
	sta chrxLUT,y
	iny
	bne -
	
	; unpack bounceLUT
	lda #116 ; f(0)
	ldx #0
-	sub bounceLUT,x ; apply delta
	sta bounceLUT,x
	inx
	cpx #54
	bne -
	ldy #52 ; loop back
-	lda bounceLUT,y
	sta bounceLUT,x
	inx
	dey
	cpy #9
	bne -
	
	mwa #wordloopadj(size(text)), chrc
	mwa VDSLST, olddli
	mva #$40, rNMIEN
	
loop
; balleOf logo
	lda #63 ; wait until it's not upper part
-	cmp rVCOUNT
	bne -
	lda #$1e
logoh = *-1
	add #$10
	cmp #$fe
	bne +
	lda #$1e
+	sta logoh
	sta COLOR+4
	lda #1
logoy = *-1
	add #4
	cmp #97
	bcc +
	lda #9
+	sta logoy
	tax
	lda bounceLUT,x
	sta zTMP3 ; zTMP0-2 are currently used by an interrupt
	ldy #0
	jsr battleOf_blank
	lda #$4c ; lms
	sta dlist_battleOf,y
	iny
	lda <#battleOf
	sta dlist_battleOf,y
	iny
	lda >#battleOf
	sta dlist_battleOf,y
	iny
	lda #111
	sub zTMP3
	sta zTMP3 ; actual lines left
	lda #$0c
	ldx #31 ; battleOf height - 1
-	sta dlist_battleOf,y
	iny
	dec zTMP3
	beq +
	dex
	bne -
	lda zTMP3
	jsr battleOf_blank
+	lda #$81 ; jump + int
	sta dlist_battleOf,y
	iny
	lda <#dlist_grid
	sta dlist_battleOf,y
	iny
	lda >#dlist_grid
	sta dlist_battleOf,y
	
; text scroller
	lda #120 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	; lda #1
	; eor framecnt
	; sta framecnt
	; beq loop
	mwa #dli1, VDSLST
	mva <#rHPOSP0, pyrdst1
	mva <#rHPOSP3, pyrdst2
	mva #0,zTMP2
	mva #$c0, rNMIEN
	inc framecnt
	lda framecnt
	and #63
	tax
	lda chryLUT,x
	ldx chry ; save for text shifting
	sta chry
	sta zTMP1
	add #TEXT_Y
	sta pyrY
	lda chrx
	sub #SCROLL_SPEED
	sta zTMP0
	sta chrx
	
shifttext
	txa ; get old y pos back
	sub chry
	beq placetext ; no y shifting
	bmi _down
	sta zTMP4 ; save for zero filling
	ldy chry
	mva #$e8, _cmd1 ; inx
	lda #$c8 ; iny
	jmp _skip
_down
	eor #$ff ; make offset positive
	sta zTMP4
	inc zTMP4
	txa
	add #39
	tax
	lda chry
	adc #39
	tay
	mva #$ca, _cmd1 ; dex
	lda #$88 ; dey
_skip
	sta _cmd2
	sta _cmd3
	mva #40, zTMP3
-	lda player0+TEXT_Y,x
	sta player0+TEXT_Y,y
	lda player1+TEXT_Y,x
	sta player1+TEXT_Y,y
	lda player2+TEXT_Y,x
	sta player2+TEXT_Y,y
	lda player3+TEXT_Y,x
	sta player3+TEXT_Y,y
	inx
_cmd1 = *-1
	iny
_cmd2 = *-1
	dec zTMP3
	bne -
	ldx zTMP4
	lda #0
-	sta player0+TEXT_Y,y
	sta player1+TEXT_Y,y
	sta player2+TEXT_Y,y
	sta player3+TEXT_Y,y
	iny
_cmd3 = *-1
	dex
	bne -
	
placetext
	lda txtcnt
	sub #SCROLL_SPEED
	sta txtcnt
	bcs loop
	adc #16
	sta txtcnt
	mva >#player0, pyrdst+1
	mva #0, pyrdst
	lda chrx
	eor #$ff
	add #1
	bpl +
	inc pyrdst+1 ; use last two players
	lda chrx ; get negative value back
	add #16
+	lsr a
	lsr a
	and #$fc
	tax
	and #4 ; odd tile?
	beq +
	mva #$80, pyrdst
+	txa
	add #0
pyrY = *-1
	tax
	lda chrc+1
	beq ++
	lda text
txtptr = *-2
	inc txtptr
	bne +
	inc txtptr+1
+	dec chrc
	bne +
	dec chrc+1
+	mvy #0, zTMP4
	.rept 3
	asl a
	rol zTMP4
	.next
	tay
	lda zTMP4
	add >#font
	sta zTMP4
	mva <#font, zTMP3
	mva #8, zTMP5
-	lda (zTMP3),y
	sta player0,x
pyrdst = *-2
	inx
	iny
	dec zTMP5
	bne -
	jmp loop
	
chrx	.byte 0
chry	.byte 9
chrc	.word 0
framecnt	.byte 0
txtcnt	.byte 0

battleOf_blank
	ldx #$70 ; 8 blank lines
-	sub #8
	bcc +
	pha
	txa
	sta dlist_battleOf,y
	pla
	iny
	bcs -
+	adc #8
	beq +
	tax
	lda dlistblankcodes-1,x
	sta dlist_battleOf,y
	iny
+	rts

dli1
	sta nmiA
	dec zTMP1
	bne skipdli
	mva #4,zTMP1
	mwa #dli2, VDSLST
	stx nmiX
	ldx zTMP0
	lda chrxLUT,x
	sta rHPOSP0
	jmp dli2_
	
dli2
	sta nmiA
	dec zTMP1
	bne skipdli
	mva #4,zTMP1
	stx nmiX
	lda pyrdst1
	eor #1
	sta pyrdst1
	ora #2
	sta pyrdst2
	lda zTMP0
	add	zTMP2
	tax
	lda chrxLUT,x
	sta rHPOSP1
pyrdst1 = *-2
	lda zTMP0
	sub	zTMP2
	tax
	lda chrxLUT,x
	sta rHPOSP3
pyrdst2 = *-2
dli2_
	lda zTMP2
	add #16
	bvc + ; = 128
	mwa #dli3, VDSLST
+	sta zTMP2
skipdli_x
	ldx nmiX
skipdli
	lda nmiA
	jmp *
olddli = *-2

dli3
	sta nmiA
	dec zTMP1
	bne skipdli
	mva #$40, rNMIEN ; no more tiles below
	stx nmiX
	lda zTMP0
	add #128
	tax
	lda chrxLUT,x
	sta rHPOSP2
	jmp skipdli_x
	
dlistblankcodes
	.byte $00, $10, $20, $30, $40, $50, $60 ; still faster than left shifting 4 times
	
bounceLUT	.block
	; (53-(x/4))²*80/121 stored in a delta form instead to allow more compression
	.byte 0, 5, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 3, 3, 4, 3
	.byte 3, 3, 3, 3, 2, 3, 3, 2, 3, 2, 2, 3, 2, 2, 2, 1
	.byte 2, 2, 2, 1, 2, 1, 1, 1, 2, 1, 0, 1, 1, 1, 0, 1
	.byte 0, 1, 0, 0, 0, 0
	.bend

chrxLUT_packed	.block
	.byte %10111010, %11101010, %10101010, %10101010, %10101000, %10100010, %00100010, %00100010
	.byte %00001000, %00100000, %00000010, %00000000, %00000000, %00000000, %00000000, %00000010
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %10000000, %00100000, %00100010
	.byte %00001000, %10001000, %10100010, %10001010, %10101010, %10101010, %10101110, %10111010
	.bend
	
	.fill 44-32 ; bounceLUT needs more 44 bytes when unpacked - chrxLUT_packed size
	
chryLUT .block
_x := 0
	.rept 64
	.byte (sin(rad(_x*360.0/64.0))+1.0)*8+1
_x := _x + 1
	.next
	.bend

text	.binary "scroller/data.bin"
battleOf	.binary "gfx/battleOf.1bpp"

	.align $800
dlist_grid
	.byte $00
	.fill 55, $90 ; blank lines for now
	.byte $41 ; jvb
	.word dlist
dlist
	.byte $70 ; 8 blank lines
dlist_battleOf
	; this part is auto-generated
	
	.align $200
player0	.fill $80
player1	.fill $80
player2	.fill $80
player3	.fill $80

chrxLUT	.fill 256
font	.binary "scroller/font_gen.1bpp"
	