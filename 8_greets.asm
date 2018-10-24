; Part 8: greets over 3d bridge
	.include "gvars.asm"
	
VDSLST = $200
SDMCTL = $22f
SDLSTL = $230
GPRIOR = $26f

*	= partEntry
start
	mva #$0f, rCOLPM0
	sta rCOLPM1
	sta rCOLPM2
	sta rCOLPM3
	; clear player/missile data
	lda #0
	ldy #0
-	sta missile,y
	sta player0,y
	sta player1,y
	sta player2,y
	sta player3,y
	iny
	bne -
	ldx #$44
	jsr settextpos
	mva >#(missile-$300), rPMBASE
	mva #$01, GPRIOR ; all players above pf
	; mva #$3e, SDMCTL ; enable player, missile and dlist dma, normal pf, single line player
	mva #$1c, SDMCTL
	mva #$03, rGRACTL ; turn on player & missile
	jsr disnmi
	mwa #vbi, rNMI
	mva #$40, rNMIEN ; vblank

loop
	mva #0, rCOLBK
	lda #120 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	sta rCOLBK
	lda #-3
xpos = *-1
	add #3
	sta xpos
	tax
	bcc done
	jsr drawtext
	mva #-1, oldsiz ; force redraw
	ldx #0
	stx zTMP2
done
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	and #3
	tay
	lda sizs,y
	cmp oldsiz
	sta oldsiz
	beq +
	tay
	; clear pm data, begin and end are from the last text redraw
	lda #0
	ldx zTMP2
-	sta missile,x
	sta player0,x
	sta player1,x
	sta player2,x
	sta player3,x
	inx
	cpx #1
_clearlast = *-1
	bne -
	; redraw the text from buffer
	mva #6, zTMP0
	mwa #missile, zARG0
	lda #64
ypos = *-1
	sub yofs,y
	sta zTMP2
	mva skips,y, _skipamt
	ldx #0
	clc
_copytopm
	mva #8, zTMP1
	ldy zTMP2
_copytopm2
	lda txtbuf,x
	bcc *+2
_skipamt = *-1
	.rept 4
	sta (zARG0),y
	iny
	.next
	inx
	dec zTMP1
	bne _copytopm2
	inc zARG0+1
	dec zTMP0
	bne _copytopm
	sty _clearlast
	
+	ldx xpos
	ldy #0
oldsiz = *-1
	jsr settextpos
	jmp loop
sizs	.byte 0, 1, 2, 1
yofs	.byte 4, 8, 16
skips	.byte 9, 6, 0

vbi
	sta nmiA
	stx nmiX
	sty nmiY
	; mwa SDLSTL, rDLISTL
	mva SDMCTL, rDMACTL
	jsr updateMusic
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
settextpos
_p = [15,12,9,6,3,0,0,3]
_d = [rHPOSM3,rHPOSM2,rHPOSM1,rHPOSM0,rHPOSP0,rHPOSP1,rHPOSP2,rHPOSP3]
_x := 0
	.rept 8
	txa
	.if _x < 6
	sub _xofs+_p[_x],y
	bcs +
	.else
	add _xofs+_p[_x],y
	bcc +
	.fi
	lda #0 ; out of screen
+	sta _d[_x]
_x := _x + 1
	.next
	lda _sizex,y
	sta rSIZEP0
	sta rSIZEP1
	sta rSIZEP2
	sta rSIZEP3
	sta rSIZEM
	rts
_sizex	.byte %00000000, %01010101, %11111111
_xofs	.char  4,  8, 16
		.char 12, 24, 48
		.char 14, 28, 56
		.char 16, 32, 64
		.char 18, 36, 72
		.char 20, 40, 80
		
drawtext
	; clear the buffer
	lda #0
	ldy #8-1
-	sta txtbuf,y
	sta txtbuf+8,y
	sta txtbuf+16,y
	sta txtbuf+24,y
	sta txtbuf+32,y
	dey
	bpl -
	; draw the text
	ldx #0 ; char
_loop
	stx zTMP0
	ldy #0
greetpos = *-1
	lda greets,y
	beq _skip ; no need to render space
	lsr a
	ldy #$f0
	bcc +
	ldy #$0f
	.rept 8
	inx
	.next
+	sty _maskl
	sty _maskr
	asl a
	asl a
	asl a ;x8
	tay
	mva #8, zTMP1 ; height
	mva _shamt,x, _shl
	sta _shr
	clc
	lda _shpos,x
	bmi _left
_right
	tax
-	mva #0, zTMP2
	lda font,y
	and #0
_maskr = *-1
	bcc *+2
_shr = *-1
	.rept 4
	lsr a
	ror zTMP2
	.next
	ora txtbuf,x
	sta txtbuf,x
	lda zTMP2
	ora txtbuf+8,x
	sta txtbuf+8,x
	inx
	iny
	dec zTMP1
	bne -
_skip
	inc greetpos
	ldx zTMP0
	inx
	cpx #8
	bne _loop
	rts
	
_left
	eor #$ff
	tax
-	mva #0, zTMP2
	lda font,y
	and #0
_maskl = *-1
	bcc *+2
_shl = *-1
	.rept 4
	asl a
	rol zTMP2
	.next
	ora txtbuf,x
	sta txtbuf,x
	lda zTMP2
	ora txtbuf-8,x
	sta txtbuf-8,x
	inx
	iny
	dec zTMP1
	bne -
	inc greetpos
	ldx zTMP0
	inx
	cpx #8
	bne _loop
	rts
	; + = right, - = left
_shpos	.char  0,-9,  8,-17, 16, 24,-33, 32 ; upper nybble
		.char -1, 0, -9,  8, 16,-25, 24,-33 ; lower nybble
_shamt	.byte 12, 3,  6,  9,  0,  9,  6,  3 ; (4-shifts)*3
		.byte  0, 9,  6,  3, 12,  3,  6,  9

	.enc "greets"
greets
	.text "chip=win"
	.text " titan  "
	.text "8static "
	.text "fairlght"
	.text " kulor  "
	.text "trilobit"
	.text "bitprtns"
	.text "btslyadm"
	.text "hooy-prg"
	.text "#atari8 "
	.text "atariage"
	.text " ctrix  "
	.text "sibcrew "
	.text "  dhs   "
	.text "chkpoint"
	.text "  sfmx  "
	.text " lamers "
	.text "  rmc   "
	.text "  vlk   "
	.text " mskty  "
	.text "tppdevs "
	
	.align $800
	.union
	.struct
font	.binary "gfx/font_greets.c.1bpp"
txtbuf	.fill 8*5
dlist	.byte $7,$e,$5,$7
	.ends
	.fill $300
	.endu
missile	.fill $100
player0	.fill $100
player1	.fill $100
player2	.fill $100
player3	.fill $100
	.warn format("Part 8's memory usage: %#04x - %#04x", start, *)
