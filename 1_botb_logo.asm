; Part 1: BotB logo (and lots of stuff that will be used later by the other parts)
	.include "gvars.asm"

SDLSTL = $230
COLOR = $2c0
dlist = $bc20
chardat = $bc40
charset = $c000
texArea = $d800 ; must be page-aligned
os_char = $e000

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
	ldx #0
	ldy #4
_loop
	mva #3, rPORTB
	lda os_char, x
_src = *-2
	sta scratch, x
	inx
	bne _loop
	lda #124 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	mva #2, rPORTB
-	lda scratch, x
	sta charset, x
_dst = *-2
	inx
	bne -
	inc _src+1
	inc _dst+1
	dey
	bne _loop
	mva #>(charset+$400), curpage
	sta rCHBASE
	; make a copy to charset+$400 too for double buffering
	; ldx #0
	ldy #4
-	lda charset, x
_src2 = *-2
	sta charset+$400, x
_dst2 = *-2
	inx
	bne -
	inc _src2+1
	inc _dst2+1
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
	mva #127, SineTable+64
	mva #-128, SineTable+192

; loadqstable
	; fill QSTableLo+Hi with x**2/4
	; this is used for fast 8-bit*8-bit unsigned multiplication
	; x**2 = 1+3+5+...+(x*2-1)
	; mva #$c0, zTMP3 ; -0.25
	; ldx #$ff
	; stx zTMP4
	; stx zTMP5
	; mva #$40, zTMP0 ; 0.25
	; inx
	; stx zTMP1
	; stx zTMP2
	; jsr loadqstable_fill
	; inc loadqstable_fill.lo
	; inc loadqstable_fill.hi
	; jsr loadqstable_fill

initcharmap	
	; force 40x24 hires char mode with data at $bc40
	; (where dos display data without cart would be)
	ldy #size(botbDlist0)
-	lda botbDlist0-1, y
	sta dlist-1, y
	dey
	bne -
	mwa #dlist, SDLSTL
	mva #$ca, COLOR+5 ; default a8 palette
	sta rCOLPF1
	mva #$94, COLOR+6
	sta rCOLPF2
	
putlogotiles
	; time to put botb logo in the middle of the screen
	ldy #0
	ldx #0
-	lda botbFrame, x
	sta coord40(15,7,chardat), y
_dst = *-2
	iny
	cpy #10
	bne +
	addw #40, _dst
	ldy #0
+	inx
	cpx #100
	bne -
	
unpackTex
	mva #$80, zTMP0
	ldx #4
-	ldy #0
-	lda botbTex,y
_src = *-2
	and zTMP0
	bne +
	lda #0
	geq ++
+	lda #3
+	sta texArea,y
_dst = *-2
	iny
	cpy #64
	bne -
	inc _dst+1
	ldy #0
	lsr zTMP0
	bcc --
	ror zTMP0
	lda _src
	add #64
	sta _src
	dex
	bne --
	
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
	eor #4 ; flip the page
	sta rotoBaseX+1
	sta rotoDestHi
	lda #0
curpage = *-1
	eor #4
	sta curpage
	; wait for vblank to properly display the finished page
	sta rNMIRES
-	bit rNMIST
	bvc -
	lda #8
rotoWidth = *-1
	sta bx
	mva #0, by
	
_loop
	txa ; 2
	add #>texArea ; 4
	sta tt+1 ; 3
	lda tyy+1 ; 3
	sta tt ; 3
_x := 2
	.rept 3
	tya ; 2
	adc Bx ; 3
	tay ; 2
	txa ; 2
	adc Bx+1 ; 3
	tax ; 2
	and #31 ; 2
	add #>texArea ; 4
	sta tt+_x+1 ; 3
	.if _x == 2
	lda tyy ; 3
	.else
	lda tyt
	.fi
	add By ; 5
	sta tyt ; 3
	lda tt+_x-2 ;3
	adc By+1 ; 3
	and #63 ; 2
	sta tt+_x ; 3
_x := _x + 2
	.next ; 45*3 = 135
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
	add Cy ; 5
	sta tyy ; 3
	lda tyy+1 ; 3
	adc Cy+1 ; 3
	and #63 ; 2
	sta tyy+1 ; 3
	jmp _loop ; 3
	           ; = 250
	; advance to next column
+	dec bx
	beq ++ ; finished
	mva #0, by
	; multiply Bx,y by 4 since we are skipping 4 pixels
	lda Bx+1
	sta _bx4hi
	lda Bx
	asl a
	rol _bx4hi
	asl a
	rol _bx4hi
	add txx
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
	lda By+1
	sta _by4hi
	lda By
	asl a
	rol _by4hi
	asl a
	rol _by4hi
	add txy
	sta txy
	sta tyy
	lda txy+1
	adc #0
_by4hi = *-1
	and #63
	sta txy+1
	sta tyy+1
	lda rotoBaseX
	add rotoHeight
	sta rotoBaseX
	bcc +
	inc rotoBaseX+1
+	jmp _loop
	
	; TODO: properly animate this
+	
	lda Ay
	add #$55
	sta Ay
	lda Ay+1
	adc #5
	and #63
	sta Ay+1
	lda Ax
	add #$66
	sta Ax
	lda Ax+1
	adc #6
	and #31
	sta Ax+1
	lda ang
	add #11
	sta ang
	tax
	ldy #0
	lda SineTable,x
	bpl +
	dey
+	sty By+1
	asl a
	rol By+1
	asl a
	rol By+1
	sta By
	txa
	add #64 ; change to cos(x)
	tax
	ldy #0
	lda SineTable,x
	bpl +
	dey
+	sty zTMP0
	asl a
	rol zTMP0
	sta Bx
	sta Cy
	lda zTMP0
	sta Bx+1
	sta Cy+1
	txa
	add #64 ; change to -sin(x)
	tax
	ldy #0
	lda SineTable,x
	bpl +
	dey
+	sta Cx
	sty Cx+1
	jmp placeroto
ang	.byte 0

; loadqstable_fill .block
	; lda zTMP0
	; add zTMP3
	; sta zTMP0
	; lda	zTMP1
	; adc zTMP4
	; sta zTMP1
	; sta QSTableLo,x
; lo = *-1
	; lda zTMP2
	; adc zTMP5
	; sta zTMP2
	; sta QSTableHi,x
; hi = *-1
	; lda #$80 ; 0.5
	; adc zTMP3 ; last add is guaranteed to have carry cleared
	; sta zTMP3
	; bcc +
	; inc zTMP4
	; bne +
	; inc zTMP5
; +	inx
	; bne loadqstable_fill
	; rts
	; .bend
	

expand
	.rept 4
	asl zTMP0
	php
	rol a
	plp
	rol a
	.next
	rts

vbk
	pusha
	; lda zNTSCcnt
	; bmi ++ ; PAL
	; bne +
	; mva #5, zNTSCcnt
	; jmp _popregs

	mwa SDLSTL, rDLISTL
	mva curpage, rCHBASE
; +	dec zNTSCcnt
+	jsr updateMusic

_popregs
	popa
dummy
	rti
vbkreq	.byte 0

sine_unmoved .block
	; sin(x*2π/256)*128
_x := 0
	.rept 64
	.byte sin(rad(_x*360.0/256.0))*128
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
	.word chardat
	.rept 23
	.byte $02
	.next
	.byte $41 ; jvb
	.word dlist
	.bend

	.align $100
botbTex	.binary "gfx/botb.4x8.1bpp"

scratch .fill $100
