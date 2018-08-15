; Part 1: BotB logo (and lots of stuff that will be used later by the other parts)
	.include "gvars.asm"

wCHBAS  = $2f4 ; rCHBASE is write-only, so we have to bother os memory again...
wSDLSTL = $230 ; this too
charset = $e000

*	= partEntry
	; region check
	; lda #$ff
	; sta zNTSCcnt
	; lda #$e
	; bit rPAL
	; beq +
	; inc zNTSCcnt
; +	
	; move char rom into ram
mvchr
	mva wCHBAS, _src
	ldx #0
	ldy #4
_loop
	mva #3, rPORTB
	lda $ffff, x
_src = *-1
	sta scratch, x
	inx
	bne _loop
	lda #124 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	mva #2, rPORTB
-	lda scratch, x
	sta charset, x
_dst = *-1
	inx
	bne -
	inc _src
	inc _dst
	dey
	bne _loop
	mva #<charset, rCHBASE
	; make a copy to charset+$400 too for double buffering
	; ldx #0
	ldy #4
-	lda charset, x
_src2 = *-1
	sta charset+$400, x
_dst2 = *-1
	inx
	bne -
	inc _src2
	inc _dst2
	dey
	bne -
	
loadsinetable
	; fill SineTable with the data in sine_unmoved
	; sine_unmoved contains only the first π/2 region
	; but due to how sine function works it's possible to expand it to the full 2π range
	ldx #0
	ldy #64
-	lda sine_unmoved, x
	sta SineTable, x
	sta SineTable+64, y
	neg
	sta SineTable+128, x
	sta SineTable+192, y
	inx
	dey
	bne -
	; these two addresses are not filled by the above loop
	mva #255, SineTable+64
	mva #0, SineTable+192

loadqstable
	; fill QSTableLo+Hi with x**2/4
	; this is used for fast 8-bit*8-bit unsigned multiplication
	; x**2 = 1+3+5+...+(x*2-1)
	mva #$c0, zTMP3 ; -0.25
	ldx #$ff
	stx zTMP4
	stx zTMP5
	mva #$40, zTMP0 ; 0.25
	inx
	stx zTMP1
	stx zTMP2
	jsr loadqstable_fill
	inc loadqstable_fill.lo
	inc loadqstable_fill.hi
	jsr loadqstable_fill

initcharmap	
	; try getting the current charmap and change display mode
	; although many DOS run in 40x24 char mode, don't assume that all of them run in it
	; zTMP0 = charmap address
	mva wSDLSTL, zTMP0
	sta zARG0
	mva wSDLSTL+1, zTMP1
	sta zARG0+1
	ldy #0
-	lda (zTMP0), y
	iny
	tax
	and #$0f
	beq - ; blank lines
	; I don't think someone is crazy enough to put jump before the first load memory scan in the display list 
	txa
	and #$40 ; has load memory scan?
	beq -
	lda (zTMP0), y ; got charmap address
	sta botbDlist0.addr
	iny
	lda (zTMP0), y
	sta botbDlist0.addr+1
	mwa #botbDlist0, copydlist.src
	ldy #size(botbDlist0)
	jsr copydlist
	
putlogotiles
	; time to put botb logo in the middle of the screen
	addw #coord40(15,7), botbDlist0.addr, _dst
	ldy #0
	ldx #0
-	lda botbFrame, x
	sta $ffff, y
_dst = *-2
	iny
	cpy #10
	bne ++
	lda _dst
	add #40
	sta _dst
	bcc +
	inc _dst+1
+	ldy #0
+	inx
	cpx #100
	bne -
	
unpackTex
texArea = $f000 ; must be page-aligned
texAddrLo = GVarsZPBegin-84
texAddrHi = texAddrLo+32
	lda #0
	ldx #32
	ldy #>(texArea+$800)
-	sub #64
	sta texAddrLo-1,x
	bcs +
	dey
+	sty texAddrHi-1,x
	dex
	bne -
	
putlogobitmap
	; o-------------u
	; |     Ax,y
	; |      ^
	; |     / \<-----view
	; |Cx,y<   >Bx,y
	; |     \ /
	; |      v
	; v          texture
Ay  = GVarsZPBegin-20 ; starting texture pos
Ax  = Ay+2
By  = Ay+4 ; texture pos to advance each view x change
Bx  = Ay+6
Cy  = Ay+8 ; texture pos to advance each view y change
Cx  = Ay+10
tt  = Ay+12 ; temp texture pointers
txy = zARG2
txx = zARG3
tyy = zTMP0 ; temp texture positions 
tyx = zTMP2
tyt = zTMP4
by  = zTMP6 ; current charmap pos
bx  = zTMP7 ; 
	mwa #0, Ax
	mwa #0, Ay
	mwa #$100, Bx
	mwa #0, By
	mwa #0, Cx
	mwa #$100, Cy
	jsr setRotoRes

	mwa #vbk, rNMI
	mwa #dummy, rRESET
	mwa #dummy, rIRQ
	
	mva #0, rIRQEN
	mva #$40, rNMIEN ; vblank
	cli

placeroto
	; now time to draw rotozoomer
	lda Ax
	sta txx
	sta tyx
	tay
	lda Ax+1
	sta txx+1
	sta tyx+1
	tax
	lda Ay
	sta txy
	sta tyy
	lda Ay+1
	sta txy+1
	sta tyy+1
	lda #<charset
rotoBaseLo = *-1
	sta rotoBaseX
	lda #>(charset+$200)
rotoDestHi = *-1
	eor 4 ; flip the page
	sta rotoBaseX+1
	sta rotoDestHi
	; wait for vblank to properly display the finished page
	sta rNMIRES
-	bit rNMIST
	bvc -
	lda #8
rotoWidth = *-1
	sta bx
	mva #0, by
	clc
	
_loop
	lda texAddrHi,x ; 4
	sta tt+1 ; 3
	lda tyy+1 ; 3
	adc texAddrLo,x ; 4
	sta tt ; 3
_x := 2
	.rept 3
	tya ; 2
	add Bx ; 5
	tay ; 2
	txa ; 2
	adc Bx+1 ; 3
	and #31 ; 2
	tax ; 2
	lda texAddrHi,x ; 4
	sta tt+_x+1 ; 3
	.if _x == 2
	lda tyy ; 3
	adc By ; 3
	sta tyt ; 3
	lda tyy+1 ; 3
	.else
	lda tyt
	adc By
	sta tyt
	lda tyt+1
	.fi
	adc By+1 ; 3
	and #63 ; 2
	sta tyt+1 ; 3
	adc texAddrLo,x ; 4
	sta tt+_x ; 3
_x := _x + 2
	.next ; 52*3 = 156
	ldy #0 ; 2
	lda (tt),y ; 5
	asl a ; 2
	asl a ; 2
	eor (tt+2),y ; 5
	asl a ; 2
	asl a ; 2
	eor (tt+4),y ; 5
	asl a ; 2
	asl a ; 2
	eor (tt+6),y ; 5
	ldy by ; 3
	sta $ffff,y ; 5
rotoBaseX = *-2
	iny ; 2
	cpy #64 ; 2
rotoHeight = *-1
	.page
	beq + ; 2
	sty by ; 3
	lda tyx ; 3
	adc Cx ; 3
	sta tyx ; 3
	tay ; 2
	lda tyx+1 ; 3
	adc Cx+1 ; 3
	and #31 ; 2
	sta tyx+1 ; 3	
	tax ; 2
	lda tyy ; 3
	adc Cy ; 3
	sta tyy ; 3
	lda tyy+1 ; 3
	adc Cy+1 ; 3
	and #63 ; 2
	sta tyy+1 ; 3
	jmp _loop ; 3
	           ; = 271
	; advance to next column
+	dec bx
	.endp
	beq ++ ; finished
	; multiply Bx,y by 4 since we are skipping 4 pixels
	lda Bx+1
	sta _bx4hi
	lda Bx
	asl a
	rol _bx4hi
	asl a
	rol _bx4hi
	adc txx
	sta txx
	sta tyx
	tay
	lda txx+1
	adc #0
_bx4hi = *-1
	and #31
	sta txx+1
	sta tyx+1
	tax
	lda Bx+1
	sta _bx4hi
	lda Bx
	asl a
	rol _by4hi
	asl a
	rol _by4hi
	adc txy
	sta txy
	sta tyy
	lda txy+1
	adc #0
_by4hi = *-1
	and #63
	sta txy+1
	sta tyy+1
	lda rotoBaseX
	adc rotoHeight
	sta rotoBaseX
	bcc +
	inc rotoBaseX+1
+	jmp _loop
	
	; TODO: properly animate this
+	
-	jmp placeroto

setRotoRes
rotoBaseXListLo = scratch
rotoBaseXListHi = scratch+128
	

loadqstable_fill .block
	lda zTMP0
	add zTMP3
	sta zTMP0
	lda	zTMP1
	adc zTMP4
	sta zTMP1
	sta QSTableLo,x
lo = *-1
	lda zTMP2
	adc zTMP5
	sta zTMP2
	sta QSTableHi,x
hi = *-1
	lda #$80 ; 0.5
	adc zTMP3 ; last add is guaranteed to have carry cleared
	sta zTMP3
	bcc +
	inc zTMP4
	bne +
	inc zTMP5
+	inx
	bne loadqstable_fill
	rts
	.bend
	

expand
	.rept 4
	asl zTMP0
	php
	rol a
	plp
	rol a
	.next
	rts

; copy display list of length y from .src to zARG0 and automatically append jump back to the start
copydlist .block
	iny
	iny
	lda zARG0+1
	sta (zARG0), y
	dey
	lda zARG0
	sta (zARG0), y
	dey
	lda #$41 ; jump and wait for vblank
	sta (zARG0), y
-	dey
	lda $ffff, y
src = *-2
	sta (zARG0), y
	tya
	bne -
	rts
	.bend

vbk
	pusha
	; lda zNTSCcnt
	; bmi ++ ; PAL
	; bne +
	; mva #5, zNTSCcnt
	; jmp _popregs

; +	dec zNTSCcnt
+	jsr updateMusic

_popregs
	popa
dummy
	rti

sine_unmoved .block
	; sin((x*2π/256)+1)*128
_x := 0
	.rept 64
	.byte (sin(rad(_x*360.0/256.0))+1.0)*128
_x := _x + 1
	.next
	.bend

botbFrame
	.enc "a8screen"
	.text "/========\"
_x := $40
	.rept 8
	.text "H"
	.rept 8
	.byte _x
_x := _x + 8
	.next
	.text "H"
_x := _x - 63
	.next
	.text "\========/"

botbDlist0 .block
	.byte $70, $70, $70 ; 24 blank lines
	.byte $42 ; 24 mode 2
addr	.word ?
	.rept 23
	.byte $02
	.next
	.bend

	.align $100
botbTex	.binary "gfx/botb.4x8.1bpp"

scratch .fill $100
