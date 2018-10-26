; Part 3: Demo title art
	.include "gvars.asm"
	
SDMCTL = $22f
SDLSTL = $230
	
*	= partEntry_3
start
	mva #$22, SDMCTL ; enable dlist dma, normal pf
	mwa #dlist, SDLSTL
	jsr disnmi
	mwa #vbi, rNMI
	mva #$c0, rNMIEN ; vblank + dlist
loop
	inc vbkreq
-	lda vbkreq
	bne -
	dec cnt
	bne loop
	mva #3, cnt
	jsr scene0 ; update scene-specific variables
scefunc = *-2
	ldx #13
-	lda hues,x
-	sub #$10
	beq - ; skip gray ($0x) hue
	sta hues,x
	lda lums,x
	sub dims,x
	bcs +
	lda #0
	beq ++
+	ora hues,x
+	sta pals,x
	dex
	bpl --
	jmp loop
cnt	.byte 3
	bne +
	mwa #scene1, scefunc
+	rts

scene0
	ldx #13
-	lda dims,x
	beq +
	dec dims,x
+	dex
	bpl -
	lda zCurMsxOrd
	cmp #$0a
	bcc _skip
	lda zCurMsxRow
	bne _skip
	mwa #scene1, scefunc
_skip
	rts

scene1
	lda zCurMsxOrd
	cmp #$0b
	bne +
	pla ; pop return address so the stack points 
	pla ; to the loader's return address instead
+	lda zCurMsxRow
	cmp #$28
	bcc +
	ldx #0
-	lda dims+1,x
	sta dims,x
	inx
	cpx #13
	bne -
	inc dims+13
+	rts
	
vbi
	sta nmiA
	stx nmiX
	sty nmiY
	bit rNMIST
	bpl +
	jmp psw0
VDSLST = *-2
+
	mva SDMCTL, rDMACTL
	mwa SDLSTL, rDLISTL
	mva >#tiledat, rCHBASE
	jsr updateMusic
	mva #0, vbkreq
retdli
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
vbkreq	.byte 0

psw0
	lda pals
	ldx pals+1
	ldy pals+2
	sta rWSYNC
	sta rCOLPF0
	stx rCOLPF1
	sty rCOLPF2
	mwa #psw1, VDSLST
	gne retdli
	
psw1
	lda pals+3
	ldx pals+4
	ldy pals+5
	sta rWSYNC
	sta rCOLPF0
	stx rCOLPF1
	sty rCOLPF3
	mwa #csw0, VDSLST
	gne retdli
	
csw0
	lda >(#tiledat+$400)
	sta rWSYNC
	sta rCHBASE
	mwa #psw2, VDSLST
	gne retdli
	
psw2
	lda pals+5
	ldx pals+6
	ldy pals+7
	sta rWSYNC
	sta rCOLPF2
	stx rCOLPF0
	sty rCOLPF1
	mva pals+8, rCOLPF3
	mwa #psw3, VDSLST
	gne retdli
	
psw3
	lda pals+6
	ldx pals+7
	ldy pals+8
	sta rWSYNC
	sta rCOLPF2
	stx rCOLPF0
	sty rCOLPF1
	mva pals+9, rCOLPF3
	mwa #psw4csw1, VDSLST
	gne retdli
	
psw4csw1
	lda pals+8
	ldx pals+9
	ldy pals+10
	sta rWSYNC
	sta rCOLPF2
	stx rCOLPF0
	sty rCOLPF1
	mva pals+11, rCOLPF3
	mva >(#tiledat+$800), rCHBASE
	mwa #psw5, VDSLST
	gne retdli
	
psw5
	lda pals+9
	ldx pals+10
	ldy pals+11
	sta rWSYNC
	sta rCOLPF2
	stx rCOLPF0
	sty rCOLPF1
	mva pals+12, rCOLPF3
	mwa #psw6, VDSLST
	gne retdli
	
psw6
	lda pals+11
	ldx pals+12
	ldy pals+13
	sta rWSYNC
	sta rCOLPF2
	stx rCOLPF0
	sty rCOLPF1
	mwa #psw0, VDSLST
	gne retdli
	
pals	.fill 14
dims	.byte  24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11
hues	.byte $b0,$40,$70,$60,$90,$30,$20,$10,$e0,$d0,$c0,$b0,$a0,$90
lums	.byte $0c,$0c,$0c,$0c,$0c,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a
	
dlist
	.byte $70 ; 10 blank lines
	.byte $90 ; pal swap 0
	.byte $45 ; 13 mode 5
	.word tilemap
	.byte $05, $85 ; pal swap 1
	.byte $05, $85 ; char swap 0
	.byte $85 ; pal swap 2
	.byte $05, $85 ; pal swap 3
	.byte $85 ; pal swap 4 + char swap 1
	.byte $05, $85 ; pal swap 5
	.byte $85, $05 ; pal swap 6
	.byte $41 ; jvb
	.word dlist
	
tilemap	.binary "gfx/nbsk_map.bin"
	.align $400
tiledat	.binary "gfx/nbsk.2bpp"
	.warn format("Part 3's memory usage: %#04x - %#04x", start, *)
