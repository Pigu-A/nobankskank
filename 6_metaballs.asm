; Part 6: Metaballs
	.include "gvars.asm"
	
VVBLKI = $222
SDMCTL = $22f
SDLSTL = $230
GPRIOR = $26f
COLOR  = $2c0
CHBAS  = $2f4
ball1Y = GVarsZPBegin-12
ball1X = GVarsZPBegin-11
ball1R = GVarsZPBegin-10
	
TRESHOLD = 8

*	= $02e0
	.word start
	
*	= $2000
start
	; fill squareTable with x**2/128
	; x**2 = 1+3+5+...+(x*2-1), x is signed
	mvx #-2, zTMP2
	inx ; -1
	stx zTMP3
	inx ; 0
	stx zTMP1
	mva #2, zTMP0
	ldy #0
	clc
-	addw zTMP2, zTMP0
	sta squareTable,x
	sta squareTable,y
	adcw #4, zTMP2
	dey
	inx
	bpl -
	mva #$7f, squareTable+$80 ; clamp to 127 to prevent overflow
	
	; fill QSTable and QSTable+256 with x²/256
	; this is used for fast 8-bit*8-bit unsigned multiplication
	; x is of range [-64,191] ([0..128]x[0..63])
	; mva >#QSTable, zARG0
	; mva #192, zARG1
	; jsr initQSTable
	mva #-1, zTMP2
	sta zTMP3
	mva #1, zTMP0
	mva #0, zTMP1
	tax
	tay
-	addw zTMP2, zTMP0
	sta QSTable,x
	sta QSTable+256,x
	cpy #-64
	bcc + ; don't store if index y is below -64
	sta QSTable,y
	sta QSTable+256,y
+	addw #2, zTMP2
	dey
	inx
	cpx #192
	bne -
	mva >#QSTable, zARG2+1
	sta zARG3+1
	
	ldx #8*16-1
-	mva msqtiles,x, charset,x
	dex
	bpl -
	ldy #13
-	ldx #15
-	mva tilemasks,x, tilemasks+16,x
_dst = *-2
	dex
	bpl -
	lda _dst
	add #16
	sta _dst
	dey
	bne --
	ldx #112
-	mva bordergfx-1,x  , player00+7,x
	mva bordergfx+111,x, player01+7,x
	mva bordergfx+223,x, player02+7,x
	mva bordergfx+335,x, player03+7,x
	mva bordergfx+447,x, player10+7,x
	mva bordergfx+559,x, player11+7,x
	mva bordergfx+671,x, player12+7,x
	mva bordergfx+783,x, player13+7,x
	dex
	bne -
	mva #$30, rHPOSP0
	mva #$38, rHPOSP1
	mva #$c0, rHPOSP2
	mva #$c8, rHPOSP3
	
	ldx #size(colors)
-	mva colors-1,x, COLOR-1,x
	dex
	bne -
	
	mva #15, ball1R
	mva #15, ball1R+3
	mva #15, ball1R+6
	mva #15, ball1R+9
	; unpack xanim_d
	ldx #0
	stx zTMP0
-	lda zTMP0
	add xanim_d,x ; apply delta
	sta zTMP0
	sta xanim,x
	ora #128
	sta xanim+32,x
	inx
	cpx #32
	bne -
	; unpack yanim_d
	ldx #0
	ldy #32
	stx zTMP0
-	lda zTMP0
	add yanim_d,x
	sta zTMP0
	sta yanim,x
	sta yanim,y
	neg
	sta yanim+32,x
	sta yanim+32,y
	inx
	dey
	cpx #17
	bne -
	
	mwa #dlist, SDLSTL
	mva >#charset, CHBAS
	sta rPMBASE
	sta pmbas
	mva #$29, SDMCTL ; enable player and dlist dma, narrow pf, double line player
	mva #$01, GPRIOR ; all players above pf
	mva #$02, rGRACTL ; turn on player
	mva #$00, rNMIEN
	mwa VVBLKI, nextvbk
	mwa #vbk, VVBLKI
	mva #$40, rNMIEN ; vblank
	
loop
	mva page+1, ddst+1
	eor #4 ; flip the page
	sta page+1
	; wait for vblank to properly display the finished page
	sta vbkreq
-	lda vbkreq
	bne -
	
renderballs
	ldx #0
	mva #-56, zTMP0
	mva #15, zTMP3
_loopy
	mva #0, zTMP6
	mva #17, zTMP4
_loopx
	mva #0, zTMP2
	stx zTMP5
	ldx zTMP6
	lda arcs,x
	add #0
cylx = *-1
	sta zTMP1
_x := 0
	.rept 4
	lda zTMP0 ; 3
	sub ball1Y+_x*3 ; 5
	tax ; 2
	lda zTMP1 ; 3
	sub ball1X+_x*3 ; 5
	tay ; 2
	lda squareTable,x ; 4
	add squareTable,y ; 6
	tax ; 2
	ldy reciprocTable,x ; 4
	beq + ; 2 ; value too low
	mva ball1R+_x*3, zARG2 ; 6
	eor #$ff ; 2
	adc #1 ; 2
	sta zARG3 ; 3
	lda (zARG2),y ; 5
	sub (zARG3),y ; 7
	add zTMP2 ; 5
	sta zTMP2 ; 3
	cmp #TRESHOLD ; 2
	.if _x < 3
	bcc + ; 3
	jmp _done
	.fi
	; = 76 (max)
+
_x := _x + 1
	.next
_done
	ldx zTMP5
	ror MSQTable,x
	inx
	inc zTMP6
	dec zTMP4
	bne _loopx
	addb #8, zTMP0
	dec zTMP3
	bne _loopy
	
applymsqtoddata
	ldx #0
	ldy #0
-	sty zTMP1
	lda #0
	ldy MSQTable+18,x
	cpy #$80 ; bit 7 -> carry
	rol a
	ldy MSQTable+17,x
	cpy #$80
	rol a
	ldy MSQTable+1,x
	cpy #$80
	rol a
	ldy MSQTable+0,x
	cpy #$80
	rol a
	ldy zTMP1
	ora tilemasks,y
	sta ddata2,y
ddst = *-2
	inx
	iny
	tya
	and #15
	bne +
	inx ; skip 17th cell
+	cpy #16*14
	bne -
	
	lda ballanim
	tax
	add #32
	and #63
	tay
	mva xanim,x, ball1X
	mva yanim,x, ball1Y
	mva xanim,y, ball1X+6
	mva yanim,y, ball1Y+6
	lda ballanim
	neg ; ball 2 and 4 run backwards
	and #63
	tax
	add #32
	and #63
	tay
	mva xanim,y, ball1X+3
	mva yanim,x, ball1Y+3
	mva xanim,x, ball1X+9
	mva yanim,y, ball1Y+9
	ldx ballanim
	inx
	cpx #64
	bne +
	ldx #0
+	stx ballanim
	addb #3, cylx
	jmp loop
	
ballanim	.byte 0
	
vbk
	; sta nmiA
	lda #0
pmbas = *-1
	eor #(>(player00-$200))^(>(player10-$200))
	sta pmbas
	sta rPMBASE
	mva #0, vbkreq
	; lda nmiA
	jmp $ffff
nextvbk = *-2
vbkreq	.byte 0
	
dlist
	.byte $70 ; 8 blank lines
	.byte $47 ; 14 mode 7
	.word ddata1
page = *-2
	.rept 13
	.byte $07
	.next
	.byte $41 ; jvb
	.word dlist
	
colors	.byte $7e,$8e,$9e,$ae,$04,$06,$0a,$0e,$00
arcs ; (asin((x-8)/8)*128/π)%256
	.byte 192,213,222,229,235,241,246,251
	.byte 0,5,10,15,21,27,34,43,64
xanim_d
	.byte 0,10,9,7,5,4,3,3,3,2,3,3,2,3,2,3
	.byte 2,10,9,7,5,4,3,3,3,2,3,3,2,3,2,3
yanim_d	.byte  0,0,1,1,5,6,6,3,3,2,1,1,1,1,1,0,0
	.union
msqtiles	.binary "gfx/corners.c.1bpp"
	.struct
xanim	.fill 64
yanim	.fill 64
	.ends
	.endu
bordergfx	.binary "gfx/border_art.t.1bpp"
	
	.align $100
reciprocTable
	.byte 96
_x := 1
	.rept 255
	.byte 96/_x
_x := _x + 1
	.next
tilemasks
	.byte $00,$40,$80,$80,$c0,$c0,$c0,$c0
	.byte $c0,$c0,$c0,$c0,$80,$80,$40,$00
	.fill 16*15
	
QSTable	.fill 512
squareTable	.fill 256
MSQTable	.fill 256
	.align $400
charset .fill 256
ddata1	.fill 256
player00	.fill 128
player01	.fill 128
player02	.fill 128
player03	.fill 128
ddata2	.fill 512
player10	.fill 128
player11	.fill 128
player12	.fill 128
player13	.fill 128
