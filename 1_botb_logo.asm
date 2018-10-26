; Part 1: BotB logo
	.include "gvars.asm"

SDLSTL = $230
COLOR = $2c0
dlist = $bc20
chardat = $bc40
charset = $c000
texArea = $d800 ; must be page-aligned
os_char = $e000

*	= partEntry
start
	; move char rom into ram
mvchr
	ldx #0
	ldy #4
_loop
	mva #$fb, rPORTB
	lda os_char, x
_src = *-2
	sta scratch, x
	inx
	bne _loop
	lda #124 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	mva #$fa, rPORTB
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
	
	lda #>SineTable
	jsr loadSineTable

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
	; special case: if there's internal basic before,
	; just copy the data from $9c40
	lda $6
	beq putlogotiles
	ldx #0
-	mva $9c40,x, chardat,x
	mva $9d30,x, chardat+240,x
	mva $9e20,x, chardat+480,x
	mva $9f10,x, chardat+720,x
	inx
	cpx #240
	bne -
	
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
	; multiply Bx,y by 4 since we are skipping 4 pixels when moving to the next column
	lda Bx+1
	sta _bx4hi
	lda Bx
	asl a
	rol _bx4hi
	asl a
	rol _bx4hi
	sta _bx4lo
	lda By+1
	sta _by4hi
	lda By
	asl a
	rol _by4hi
	asl a
	rol _by4hi
	sta _by4lo
	lda #<charset
rotoBaseLo = *-1
	sta rotoBaseX
	sta rotoBaseX2
	lda #>(charset+$200)
rotoDestHi = *-1
	eor #4 ; flip the page
	sta rotoBaseX+1
	sta rotoBaseX2+1
	sta rotoDestHi
	lda #0
curpage = *-1
	eor #4
	sta curpage
	; wait for vblank to properly display the finished page
	sta rNMIRES
-	bit rNMIST
	bvc -
	jsr scene0 ; update scene-specific variables
scefunc = *-2

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
	iny	; 2
	sta $ffff,y ; 5
rotoBaseX2 = *-2
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
	           ; = 257
	; advance to next column
+	dec bx
	beq ++ ; finished
	mva #0, by
	lda txx
	add #0
_bx4lo = *-1
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
	lda txy
	add #0
_by4lo = *-1
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
	sta rotoBaseX2
	bcc +
	inc rotoBaseX+1
	inc rotoBaseX2+1
+	jmp _loop
	
	; TODO: properly animate this
+	
	lda Ay
	add #$33
	sta Ay
	lda Ay+1
	adc #3
	and #63
	sta Ay+1
	lda Ax
	add #$44
	sta Ax
	lda Ax+1
	adc #4
	and #31
	sta Ax+1
	lda ang
	add #7
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
+	sty Bx+1
	asl a
	rol Bx+1
	sta Bx
	mvy Bx+1, Cy+1
	asl a
	rol Cy+1
	sta Cy
	txa
	add #64 ; change to -sin(x)
	tax
	ldy #0
	lda SineTable,x
	bpl +
	dey
+	sty Cx+1
	asl a
	rol Cx+1
	sta Cx
	jmp placeroto
ang	.byte 0

vbk
	sta nmiA
	stx nmiX
	sty nmiY
	mwa SDLSTL, rDLISTL
	mva curpage, rCHBASE
	jsr updateMusic
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
	
scene0
	lda zCurMsxOrd
	cmp #$05
	bcc _skip
	pla ; pop return address so the stack points 
	pla ; to the loader's return address instead
_skip
	rts

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
botbTex	.binary "gfx/botb.t.1bpp"

scratch .fill $100
	.warn format("Part 1's memory usage: %#04x - %#04x", start, *)
