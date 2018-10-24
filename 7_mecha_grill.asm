; Part 7: GR.9/10 interlaced art ✗
	.include "gvars.asm"
	
SDMCTL = $22f
SDLSTL = $230
COLOR  = $2c0

HEIGHT = 100
	
*	= partEntry_7
start
	mva #0, SDMCTL
	mwa #vbi, rNMI
	mva #$40, rNMIEN
	mva #$70, dlist0 ; 8 blank lines
	sta dlist0+1
	sta dlist1
	sta dlist1+1
	mva #$30, dlist0+2 ; 4 blank lines
	sta dlist1+2
	mwa #gfxl-2, zTMP0
	mwa #gfxc-2, zTMP2
	ldx #0
	ldy #HEIGHT
-	lda #$5f ; lms + hscrol
	sta dlist0d, x
_dst00C = *-2
	sta dlist0d+3, x
_dst01C = *-2
	sta dlist1d, x
_dst10C = *-2
	sta dlist1d+3, x
_dst11C = *-2
	lda zTMP0
	sta dlist0d+1, x
_dst00L = *-2
	sta dlist1d+4, x
_dst11L = *-2
	lda zTMP1
	sta dlist0d+2, x
_dst00H = *-2
	sta dlist1d+5, x
_dst11H = *-2
	lda zTMP2
	sta dlist0d+4, x
_dst01L = *-2
	sta dlist1d+1, x
_dst10L = *-2
	lda zTMP3
	sta dlist0d+5, x
_dst01H = *-2
	sta dlist1d+2, x
_dst10H = *-2
	addw #40, zTMP0
	addw #40, zTMP2
	txa
	add #6
	tax
	bcc +
	inc _dst00C+1
	inc _dst00L+1
	inc _dst00H+1
	inc _dst01C+1
	inc _dst01L+1
	inc _dst01H+1
	inc _dst10C+1
	inc _dst10L+1
	inc _dst10H+1
	inc _dst11C+1
	inc _dst11L+1
	inc _dst11H+1
+	dey
	bne -
	mva #$41, dlist0d+HEIGHT*6 ; jvb
	sta dlist1d+HEIGHT*6
	mwa #dlist0, dlist0d+HEIGHT*6+1
	mwa #dlist1, dlist1d+HEIGHT*6+1
	
	mwa #dlist0, SDLSTL
	mva #$22, SDMCTL ; enable dlist dma, normal pf
loop
	lda #0
framecnt = *-1
	eor #1
	sta framecnt
	sta zTMP0
	sta rWSYNC
	sta rPRIOR
	bne +
	lda >#dlist0
	gne ++
+	lda >#dlist1
+	sta SDLSTL+1
	lda COLOR
	sta rCOLBK
	jsr scene0 ; update scene-specific variables
scefunc = *-2

	mva #(HEIGHT*2), zTMP1
	lda #(63-HEIGHT/2) ; wait until display begin
-	cmp rVCOUNT
	bne -
	sta rWSYNC
	clc
-	lda rRANDOM
	and #0
rand = *-1
	adc #8
offs = *-1
	tay
	lda zTMP0
	eor #1
	sta zTMP0
	beq +
	lda #$40
	ldx #0
	geq ++
+	lda #$80
	ldx #0
color8 = *-1
+	sta rWSYNC
	stx rCOLBK
	sta rPRIOR
	sty rHSCROL
	dec zTMP1
	bne -
	jmp loop
	
scene0
	lda framecnt
	bne _done
	ldx #8
-	lda gfxcpals,x
	and #$f
	add _fade
	cmp #$f
	bcc +
	lda #$f
+	sta zTMP1
	lda gfxcpals,x
	and #$f0
	ora zTMP1
	cpx #8
	beq +
	sta COLOR,x
	gne ++
+	sta color8
+	dex
	bpl -
	dec _fade
	bpl _done
	mwa #scene1, scefunc
_done
	rts
_fade .byte 15
	
scene1 ; TODO tile copying system when I actually have an animation finished
	lda zCurMsxOrd
	cmp #$24
	bne _done
	lda zCurMsxRow
	cmp #$30
	bne _done
	mwa #scene2, scefunc
	jmp scene2
_done
	rts

scene2
	; scroll the whole gfx to the right
	lda #0
_state = *-1
	eor #6
	sta _state
	sta zTMP2
	ldx _lasti
	lda _lut,x
	sta zTMP3
	bne _move
	rts ; no need to move the gfx data yet
	
_move
	; since both gfxl and gfxc are aligned to the same lower byte,
	; we can just do only one math on the lower byte of both gfxs
	; same goes with dlist0 and dlist1
	lda _lastp
	ldx zTMP2
	beq _s0
	sub zTMP3
	sta _lastp
	sta _dstl
	sta _dstc
	lda _lastp+1
	bcs _st
	dec _lastp+1
	gcc _st
_s0
	add #40
	sta _dstl
	sta _dstc
	lda _lastp+1
	adc #0
_st
	sta _dstl+1
	add >#(gfxc-gfxl)
	sta _dstc+1
	mva >#(dlist0d+1), _dst00S+1
	sta _dst00L+1
	sta _dst00H+1
	sta _dst01L+1
	sta _dst01H+1
	mva >#(dlist1d+1), _dst10L+1
	sta _dst10H+1
	sta _dst11L+1
	sta _dst11H+1
	
	ldy #HEIGHT/2
_moveloop
	ldx zTMP3
	lda #0
-	sta $ffff,x
_dstl = *-2
	sta $ffff,x
_dstc = *-2
	dex
	bne -
	ldx zTMP2
	lda dlist0d+1,x
_dst00S = *-2
	sub zTMP3
	sta dlist0d+1,x
_dst00L = *-2
	sta dlist0d+4,x
_dst01L = *-2
	sta dlist1d+1,x
_dst10L = *-2
	sta dlist1d+4,x
_dst11L = *-2
	bcs +
	dec dlist0d+2,x
_dst00H = *-2
	dec dlist0d+5,x
_dst01H = *-2
	dec dlist1d+2,x
_dst10H = *-2
	dec dlist1d+5,x
_dst11H = *-2
+	txa
	add #12
	sta zTMP2
	bcc +
	inc _dst00S+1
	inc _dst00L+1
	inc _dst00H+1
	inc _dst01L+1
	inc _dst01H+1
	inc _dst10L+1
	inc _dst10H+1
	inc _dst11L+1
	inc _dst11H+1
+	addw #80, _dstl
	addw #80, _dstc
	dey
	bne _moveloop
	
	lda _state
	bne _done
	inc _lasti
	lda _lasti
	cmp #size(_lut)
	bne _done
	pla ; pop return address so the stack points 
	pla ; to the loader's return address instead
	mva #0, rCOLPF2
	sta COLOR+6
_done
	rts
_lasti	.byte 0
_lastp	.word gfxl+39
_lut	.block
_x := 1
_t1 := 0
	.rept 16
_t2 := int(32*(_x/16.0)**2+_x/2.0+.5)
	.byte _t2-_t1
_t1 := _t2
_x := _x + 1
	.next
	.bend
	
vbi
	sta nmiA
	stx nmiX
	sty nmiY
	mwa SDLSTL, rDLISTL
	mva SDMCTL, rDMACTL
	ldx #7
-	mva COLOR,x, rCOLPM0,x
	dex
	bpl -
	jsr updateMusic
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
	.align $1000
	.fill 42, 0 ; buffer for when scrolling right
gfxl	.binary "gfx/mechag_l.4bpp"
	.align $1000
	.fill 42, 0
gfxc	.binary "gfx/mechag_c.4bpp"
	.fill 2
gfxcpals	.byte $00,$07,$0f,$15,$1c,$35,$85,$ec,$9c
	.align $400
dlist0	.fill 3
dlist0d	.fill HEIGHT*6+3
	.align $400
dlist1	.fill 3
dlist1d	.fill HEIGHT*6+3
	.warn format("Part 7's memory usage: %#04x - %#04x", start, *)
