; Part 1: BotB logo
	.include "gvars.asm"

Ma = GVarsZPBegin-24
Mb = Ma+2
SDMCTL = $22f
SDLSTL = $230
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
	mva >#QSTable, zARG0
	mva #192, zARG1
	jsr initQSTable
	; install vector to Ma and Mb instead since zARG2-3 is already occupied
	mva >#QSTable, Ma+1
	sta Mb+1

initcharmap	
	; force 40x24 hires char mode with data at $bc40
	; (where dos display data without cart would be)
	ldy #size(botbDlist0)
-	lda botbDlist0-1, y
	sta dlist-1, y
	dey
	bne -
	mva #0, rHPOSP0
	sta rHPOSP1
	sta rHPOSP2
	sta rHPOSP3
	sta rPRIOR ; combine all plyer colors
	mva #3, rSIZEP0 ; quad width
	sta rSIZEP1
	sta rSIZEP2
	sta rSIZEP3
	mva #$2a, SDMCTL ; enable player and dlist dma, normal pf, double line player
	mva #$02, rGRACTL ; turn on player
	mva #>(player0-$200), rPMBASE
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
	
initplayers
	; make color masks as player graphics
	tax
	ldy #16
	jsr blankpyrs
	ldy #28
	jsr fillpyrs
	ldy #4
	jsr blankpyrs
	ldy #32
	jsr fillpyrs
	ldy #4
	jsr blankpyrs
	ldy #28
	jsr fillpyrs
	ldy #16
	jsr blankpyrs
	
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
Ay  = Mb+2 ; starting texture pos
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
	mwa #$200, Cy
	mwa #vbi, rNMI
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
	
updateA
	; TODO: properly animate this
+	lda haltroto
	beq placeroto
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
	
updateBC
	mva #0, Bx+1
	sta By+1
	sta Cx+1
	ldx #$90
zooi = *-1
	inx
	inx
	inx
	stx zooi
	lda SineTable,x
	asr a
	asr a ; -32~31
	add #40 ; 8~71
	tay
	lda #0
ang = *-1
	add #7
	sta ang
	tax
	
	lda SineTable,x
	asr a
	sta Ma
	neg
	sta Mb
	lda (Ma),y
	sub (Mb),y
	bpl +
	dec By+1
+	asl a
	rol By+1
	asl a
	rol By+1
	asl a
	rol By+1
	asl a
	rol By+1
	sta By
	txa
	add #64 ; change to cos(x)
	tax
	lda SineTable,x
	asr a
	sta Ma
	neg
	sta Mb
	lda (Ma),y
	sub (Mb),y
	bpl +
	dec Bx+1
+	asl a
	rol Bx+1
	asl a
	rol Bx+1
	asl a
	rol Bx+1
	sta Bx
	sta Cy
	mva Bx+1, Cy+1
	asl Cy
	rol Cy+1
	txa
	add #64 ; change to -sin(x)
	tax
	lda SineTable,x
	asr a
	sta Ma
	neg
	sta Mb
	lda (Ma),y
	sub (Mb),y
	bpl +
	dec Cx+1
+	asl a
	rol Cx+1
	asl a
	rol Cx+1
	asl a
	rol Cx+1
	sta Cx
	txa
	jmp placeroto
	
blankpyrs
	lda #0
-	sta player0,x
	sta player1,x
	sta player2,x
	sta player3,x
	inx
	dey
	bne -
	rts
	
fillpyrs
	lda #$3f
	sta player0,x
	lda #$ff
	sta player1,x
	sta player2,x
	lda #$fc
	sta player3,x
	inx
	dey
	bne fillpyrs
	rts

vbi
	sta nmiA
	bit rNMIST
	bpl +
	jmp dli1
VDSLST = *-2
+	stx nmiX
	sty nmiY
	mwa SDLSTL, rDLISTL
	mva SDMCTL, rDMACTL
	mva curpage, rCHBASE
	ldx #8
-	mva COLOR,x, rCOLPM0,x
	dex
	bpl -
	jsr updateMusic
	ldx nmiX
	ldy nmiY
retdli
	lda nmiA
	rti
	
dli1 ; center
	lda #2
	sta rWSYNC
	sta rCHACTL
	lda dlicolupd
	beq +
	mva COLOR+9, rCOLPM0
	mva COLOR+10, rCOLPM1
	mva COLOR+11, rCOLPM2
	mva COLOR+12, rCOLPM3
	mva COLOR+13, rCOLPF2
+	mwa #dli2, VDSLST
	gne retdli
	
dli2 ; bottom
	lda #6
	sta rWSYNC
	sta rCHACTL ; xflip tiles on non-center rows
	lda dlicolupd
	beq +
	mva COLOR+14, rCOLPM0
	mva COLOR+15, rCOLPM1
	mva COLOR+16, rCOLPM2
	mva COLOR+17, rCOLPM3
	mva COLOR+18, rCOLPF2
+	mwa #dli1, VDSLST
	gne retdli
	
scene0
	lda zCurMsxOrd
	beq _skip
	inc haltroto
	mwa #scene1, scefunc
_skip
	rts
haltroto	.byte 0
dlicolupd	.byte 0

scene1
	lda _siz
	cmp #9
	bcc _skip
	mva #$00, zTMP0
	jsr _box
_skip
	inc _siz
	lda _siz
	cmp #41
	beq _skip2
	mva #$80, zTMP0
	jsr _box
	rts
_skip2
	mva #$c0, rNMIEN
	mwa #scene2, scefunc
	rts
_siz	.byte 8
_box
	lda _siz
	lsr a
	sta zTMP1
	lda #19
	sub zTMP1
	tay
	lda #11+17
	sub zTMP1
	tax
	mva chardataddrL,x, zTMP1
	mva chardataddrH,x, zTMP2
	mva _siz, zTMP3
	lda zTMP0
-	sta (zTMP1),y
	iny
	dec zTMP3
	bne -
	mva _siz, zTMP3
-	lda zTMP0
	sta (zTMP1),y
	inx
	mva chardataddrL,x, zTMP1
	mva chardataddrH,x, zTMP2
	dec zTMP3
	bne -
	mva _siz, zTMP3
	lda zTMP0
-	sta (zTMP1),y
	dey
	dec zTMP3
	bne -
	tya
	bmi +
	mva _siz, zTMP3
-	lda zTMP0
	sta (zTMP1),y
	dex
	mva chardataddrL,x, zTMP1
	mva chardataddrH,x, zTMP2
	dec zTMP3
	bne -
+	rts

scene2
	lda zCurMsxOrd
	cmp #$02
	bne _skipall
	lda zCurMsxRow
	cmp #32
	bcc _skipfade
	dec _frame
	bne _skipfade
	mva #6, _frame
	lda COLOR+5
	and #$f
	cmp #$f
	beq +
	tax
	inx
	stx COLOR+5
+	lda COLOR+6
	and #$f
	beq +
	dec COLOR+6
+	lda COLOR+8
	and #$f
	beq _skipfade
	dec COLOR+8
_skipfade
	lda zCurMsxRow
	cmp #-1
_last = *-1
	sta _last
	beq _skipall
	and #7
	bne _skipall
	jmp _0
_ptr = *-2
_skipall
	rts
_0 ; left
	mva #$50, zTMP0
	mva #6, zTMP2
	mva #25, zTMP3
	ldx #0
	jsr _draw
	mwa #_1, _ptr
	mva #$c0, zTMP0
	mva #8, zTMP2
	mva #25, zTMP3
	ldx #7
	jmp _draw
_1 ; downright
	mva #$40, zTMP0
	mva #8, zTMP2
	mva #41, zTMP3
	mva #$88, _cmd ; dey
	ldx #25
	jsr _draw
	mwa #_2, _ptr
	mva #$c0, zTMP0
	mva #6, zTMP2
	mva #41, zTMP3
	ldx #34
	jmp _draw
_2 ; up
	mwa #_3, _ptr
	mva #$c0, zTMP0
	mva #8, zTMP2
	mva #23, zTMP3
	ldx #16
	jmp _draw
_3 ; right
	mva #$c0, zTMP0
	mva #8, zTMP2
	mva #25, zTMP3
	mva #$c8, _cmd ; iny
	ldx #25
	jsr _draw
	mwa #_4, _ptr
	mva #$40, zTMP0
	mva #6, zTMP2
	mva #25, zTMP3
	ldx #34
	jmp _draw
_4 ; downleft
	mva #$d0, zTMP0
	mva #6, zTMP2
	mva #41, zTMP3
	mva #$88, _cmd ; dey
	ldx #0
	jsr _draw
	mwa #_5, _ptr
	mva #$40, zTMP0
	mva #8, zTMP2
	mva #41, zTMP3
	ldx #7
	jmp _draw
_5 ; upright
	mva #$40, zTMP0
	mva #8, zTMP2
	mva #23, zTMP3
	ldx #25
	jsr _draw
	mwa #_6, _ptr
	mva #$c0, zTMP0
	mva #6, zTMP2
	mva #23, zTMP3
	ldx #34
	jmp _draw
_6 ; down
	mwa #_7, _ptr
	mva #$c0, zTMP0
	mva #8, zTMP2
	mva #41, zTMP3
	ldx #16
	jmp _draw
_7 ; upleft
	mva #$d0, zTMP0
	mva #6, zTMP2
	mva #23, zTMP3
	ldx #0
	jsr _draw
	mwa #scene2_0, scefunc
	mva #$40, zTMP0
	mva #8, zTMP2
	mva #23, zTMP3
	ldx #7
	jmp _draw
_frame	.byte 2
_draw
-	ldy zTMP3
	mva #8, zTMP1
-	mva chardataddrL,y, _dst
	mva chardataddrH,y, _dst+1
	mva zTMP0, $ffff,x
_dst = *-2
	iny
_cmd = *-1
	inc zTMP0
	dec zTMP1
	bne -
	inx
	dec zTMP2
	bne --
	rts
	
scene2_0 ; end
	lda zCurMsxOrd
	cmp #$03
	bcc +
	lda zCurMsxRow
	bne +
	mva #$28, rHPOSP0
	mva #$4c, rHPOSP1
	mva #$94, rHPOSP2
	mva #$b8, rHPOSP3
	inc dlicolupd
	mwa #scene3, scefunc
+	rts

scene3
	lda zCurMsxRow
	and #7
	cmp #-1
_last = *-1
	sta _last
	beq ++
	ldx #0
	ldy #5
	cmp #0
	beq +
	ldx #5
	ldy #6
	cmp #4
	beq +
	ldx #11
	ldy #4
	cmp #6
	bne ++
+	sty zTMP0
-	ldy _colp,x
	lda rRANDOM
	and #$f2
	sta COLOR,y
	inx
	dec zTMP0
	bne -
+	lda zCurMsxOrd
	cmp #$04
	bcc _skip
	lda zCurMsxRow
	cmp #32
	bne _skip
	dec	dlicolupd
	mva #0, rHPOSP0
	sta rHPOSP1
	sta rHPOSP2
	sta rHPOSP3
	mwa #scene4, scefunc
_skip
	rts
_colp .byte 1,2,13,15,16,0,3,10,11,14,17,6,9,12,18
	
COLOR .fill 19

scene4
	lda curVol
	and #$0f
	sta COLOR+5
	lda curVol
	and #$f0
	bne +
	cmp #0
_last = *-1
	beq +
	lda rRANDOM
	and #$f0
	sta COLOR+6
	sta COLOR+8
+	sta _last
	
_skipcol
	lda zCurMsxOrd
	cmp #$05
	bcc _skip
	mva #0, rCOLPF2
	sta rCOLBK
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
	.fill 5, $02
	.byte $82
	.fill 8, $02
	.byte $82
	.fill 8, $02
	.byte $41 ; jvb
	.word dlist
	.bend
	
chardataddr = chardat + range(0,40*24,40)
dumm = $f800
chardataddrL
	.fill 17, <dumm
	.byte <(chardataddr)
	.fill 17, <dumm
chardataddrH
	.fill 17, >dumm
	.byte >(chardataddr)
	.fill 17, >dumm

	.align $100
botbTex	.binary "gfx/botb.t.1bpp"
	
	.align $400
	.union
scratch	.fill $100
QSTable	.fill $200
	.endu
player0	.fill $80
player1	.fill $80
player2	.fill $80
player3	.fill $80
	.warn format("Part 1's memory usage: %#04x - %#04x", start, *)
