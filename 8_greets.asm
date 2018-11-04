; Part 8: greets over 3d bridge
	.include "gvars.asm"
	
SDMCTL = $22f
SDLSTL = $230
GPRIOR = $26f
buf_Screen = $a000

DURATION = 95

*	= partEntry
start
	; mva >#QSTable, zARG0
	; mva #192, zARG1
	; jsr initQSTable
	
	; clear screen and copy the bridge data
	; lda #0
	; ldx #36
; -	sta buf_Screen,x
	; sta buf_Screen+$1000,x
	; dex
	; bpl -
	; ldx #0
; _loop
	; ldy #0
; -	lda bridgegfx,y
; _src = *-2
	; sta buf_Screen+37,y
; _dst = *-2
	; iny
	; cpy #12
	; bne -
	; lda #0
; -	sta buf_Screen+37,y
; _dst2 = *-2
	; iny
	; cpy #46
	; bne -
	; addw #12, _src
	; cpx #87
	; beq +
	; addb #46, _dst
	; sta _dst2
	; adcb #0, _dst+1
	; sta _dst2+1
	; inx
	; cpx #128
	; bne _loop
	; geq ++
; +	mva #<(buf_Screen+$1025), _dst
	; sta _dst2
	; mva #>(buf_Screen+$1025), _dst+1
	; sta _dst2+1
	; inx
	; gne _loop
; +
	mva #$0f, rCOLPM0
	sta rCOLPM1
	sta rCOLPM2
	sta rCOLPM3
	; clear player/missile data and buffers
	lda #0
	ldy #0
-	sta missile,y
	sta player0,y
	sta player1,y
	sta player2,y
	sta player3,y
	; sta scrols,y
	sta bgcols2,y
	iny
	bne -
	ldx #$44
	jsr settextpos
    mwa #dlist, SDLSTL
	mva >#(missile-$300), rPMBASE
	mva #$01, GPRIOR ; all players above pf
	mva #$3e, SDMCTL ; enable player, missile and dlist dma, normal pf, single line player
	mva #$03, rGRACTL ; turn on player & missile
	jsr disnmi
	mwa #vbi, rNMI
	mva #$c0, rNMIEN ; dlist + vblank

loop
	lda #120 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	jsr scene0 ; update scene-specific variables
scefunc = *-2
	ldx #DURATION
frame = *-1
	inx
	stx frame
	cpx #DURATION
	bcc done
	jsr drawtext
	mva #128, xpos
	mva #96, ypos
	ldx #0
	stx frame
	stx zTMP2
	stx xposd
	stx yposd
	; generate new x,y position
	ldy #0
	lda rRANDOM
	bpl +
	dey
+	sty txtdXH
	asl a
	rol txtdXH ; x1
	sta txtdXL
	ldy #0
	lda rRANDOM
	bpl +
	dey
+	sty txtdYH
	sta txtdYL ; x.5
done
	; calculate the position
	lda #0
xposd = *-1
	add #0
txtdXL = *-1
	sta xposd
	lda xpos
	adc #0
txtdXH = *-1
	sta xpos
	lda #0
yposd = *-1
	add #0
txtdYL = *-1
	sta yposd
	lda ypos
	adc #0
txtdYH = *-1
	sta ypos
	; calculate the size
	cpx #DURATION/2
	lda #0
	bcc +
	cpx #DURATION*3/4
	lda #1
	bcc +
	lda #2
+	sta siz
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
	lda #96
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
	
+	ldx #0
xpos = *-1
	ldy #0
siz = *-1
	jsr settextpos
	
updatebridge
	ldx brypos
	ldy #3
-	dex
	bpl +
	ldx #$7f
+	lda rRANDOM
	and #$17
	add #$b8
	sta bgcols2,x
	sta bgcols2+$80,x
	dey
	bne -
	stx brypos
	jmp loop
yofs	.byte 4, 8, 16
skips	.byte 9, 6, 0

vbi
	bit rNMIST
	bpl +
	jmp dli1
VDSLST = *-2
+
	sta nmiA
	stx nmiX
	sty nmiY
	mwa SDLSTL, rDLISTL
	mva SDMCTL, rDMACTL
	mwa #dli1, VDSLST
	jsr updateMusic
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
dli1
	sta nmiA
	stx nmiX
	ldx #0
_pos = *-1
	lda bgcols,x
	inx
	stx _pos
	sta rWSYNC
	sta rCOLBK
	cpx #6
	bne +
	mva #0, _pos
	mwa #dli2, VDSLST
+	lda nmiA
	ldx nmiX
	rti
	
dli2
	sta nmiA
	stx nmiX
	sty nmiY
	lda #0
brypos = *-1
	; sta _y1
	sta _y2
	ldx #0
-	ldy curveLUT,x
	; lda scrols,y
_y1 = *-2
	; pha
	lda bgcols2,y
_y2 = *-2
	sta rWSYNC
	sta rCOLBK
	; pla
	; sta rHSCROL
	inx
	bpl -
	mva #0, rCOLBK
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
	
bgcols
	.byte $80,$82,$84,$86,$88,$8a
	
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

scene0
	lda zCurMsxOrd
	cmp #$30
	bcc _skip
	lda zCurMsxRow
	bne _skip
	mwa #scene1, scefunc
_skip
	rts
	
scene1
	lda zCurMsxRow
	cmp #$1c
	bcc _skip
	mva #0, rHPOSP0
	sta rHPOSP1
	sta rHPOSP2
	sta rHPOSP3
	sta rHPOSM0
	sta rHPOSM1
	sta rHPOSM2
	sta rHPOSM3
	pla ; pop return address so the stack points 
	pla ; to the loader's return address instead
_skip
	rts

	.enc "greets"
greets
	.text "chip=win"
	.text " titan  "
	.text "8static "
	.text " f l t  "
	.text " kulor  "
	.text "trilobit"
	.text "bitprtns"
	.text "btslyadm"
	.text "hooy-prg"
	.text "#atari8 "
	.text "atariage"
	.text " ctrix  "
	.text "sibcrew "
	.text " d h s  "
	.text "chkpoint"
	.text "s m f x "
	.text " lamers "
	.text " r m c  "
	.text " v l k  "
	.text " mskty  "
	.text "tppdevs "
	
; bridgegfx	.binary "gfx/bridge.2bpp"
	
	.align $100
curveLUT
_x := 0
	.rept 128
	.byte (1-(_x/128.0-1)**2)*96+_x*32/128
_x := _x+1
	.next
	
	.align $800
	.union
	.struct
font	.binary "gfx/font_greets.c.1bpp"
txtbuf	.fill 8*5
dlist
	.byte $f0
	.fill 12, [$70,$f0]
    ; .fill 128*3, [$5e,$00,$a0]
    .byte $41
    .word dlist
	.ends
	.fill $300
	.endu
missile	.fill $100
player0	.fill $100
player1	.fill $100
player2	.fill $100
player3	.fill $100
QSTable	.fill $200
; scrols	.fill $100
bgcols2 .fill $100
	.warn format("Part 8's memory usage: %#04x - %#04x", start, *)
