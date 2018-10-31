; Part 4: Twister
	.include "gvars.asm"

buf_Screen = $e000

;ANTIC
SDMCTL = $022f               ; ANTIC Control Register 00= OFF $22 = ON
SDLSTL = $0230               ; ANTIC DISPLAY LIST
COLOR  = $02c0

*	= partEntry
start
	; clear screen and copy the twister data
	lda #0
	ldx #42
-	sta buf_Screen,x
	sta buf_Screen+$1000,x
	dex
	bpl -
	ldx #0
_loop
	ldy #0
-	lda buf_Twister,y
_src = *-2
	sta buf_Screen+43,y
_dst = *-2
	iny
	cpy #12
	bne -
	lda #0
-	sta buf_Screen+43,y
_dst2 = *-2
	iny
	cpy #52
	bne -
	addw #12, _src
	cpx #63
	beq +
	addb #52, _dst
	sta _dst2
	adcb #0, _dst+1
	sta _dst2+1
	inx
	cpx #128
	bne _loop
	geq ++
+	mva #<(buf_Screen+$102b), _dst
	sta _dst2
	mva #>(buf_Screen+$102b), _dst+1
	sta _dst2+1
	inx
	gne _loop
	
	; copy displaylist0+mis00 to displaylist1+mis10
+	ldx #0
-	mva displaylist0,x, displaylist1,x
	mva displaylist0+$100,x, displaylist1+$100,x
	inx
	bne -
	
	lda #>SineTable
	jsr loadSineTable
	
    mwa #<displaylist0, SDLSTL
    mva #$2e, SDMCTL ; enable player, missile and dlist dma, normal pf, double line player
	mva #$12, rPRIOR ; player 1-2 above, player 3-4 below, player 5
	mva #$03, rGRACTL
	mva #$ff, rSIZEM ; quad width all missiles
	mva #$6c, zTMP7 ; player twister position
	jsr disnmi
	mwa #vbi, rNMI
	mva #$c0, rNMIEN ; vblank
	ldx #7
-	mva colors,x, rCOLPM0,x
	dex
	bpl -
beginprog
	lda #>displaylist0
page = *-1
	sta ddl+1
	sta ddl2+1
	eor #>(displaylist0^displaylist1) ; flip the page
	sta page
	sta SDLSTL+1
	sta PMBAS
	lda #0
tscr = *-1
	sta HSCROL
	; wait for vblank to properly display the finished page
	sta vbkreq
-	lda vbkreq
	bne -
	jsr scene0 ; update scene-specific variables
scefunc = *-2
	
updatescrtwister
	ldx #0
frame1 = *-1
	inx
	inx
	stx frame1
	ldy #0
	sty zTMP0
	lda SineTable,x
	bpl +
	dey
+	sty zTMP1 ; -.5~.5
	asl a
	sta _lo
	rol zTMP1 ; -1~1
	ldy zTMP1
	asl a
	rol zTMP1
	asl a
	rol zTMP1 ; -4~4
	sta zTMP2
	add #0
_lo = *-1
	sta zTMP3
	tya
	adc zTMP1 ; -5~5
	asl zTMP3
	rol a
	sta _m0
	add #$be
	sta rHPOSM2
	sub #8
	sta rHPOSM3
	lda #$be
	sbc #0
_m0 = *-1
	sta rHPOSM0
	sub #8
	sta rHPOSM1
	lda #0
ypos = *-1
	add #3
	and #127
	sta ypos
	ldy #0
-	sta stwpos,y
	sta _hi
	addb zTMP2, zTMP0
	lda zTMP1
	adc #0
_hi	= *-1
	and #127
	iny
	cpy #120
	bne -
	
	lda #124
xpos = *-1
	lsr a
	lsr a
	sta xtile
	lda xpos
	and #3
	sta _sub
	lda #4
	sub #0
_sub = *-1
	sta tscr
	
	mvx #0, zTMP0
	ldy #1
justblit
prepare_buffer_positons
	lda stwpos,x
	tax
    lda tab_screen_lo,x
	add #0
xtile = *-1
	sta displaylist0,y
ddl = *-2
	iny
    lda tab_screen_hi,x
	adc #0
	sta displaylist0,y
ddl2 = *-2
	iny
	iny
	bne blit_line_finish
	inc ddl+1
	inc ddl2+1
blit_line_finish
    inc zTMP0
	ldx zTMP0
	cpx #120
    bne justblit
done

updatepyrtwisterX
	lda ddl+1
	add #1
	sta ddl3
	ldx #199
frame3 = *-1
	inx
	inx
	inx
	stx frame3
	ldy #0
	lda SineTable,x
	bpl +
	dey
+	sty zTMP1 ; -.5~.5
	asl a
	rol zTMP1
	asl a
	rol zTMP1 ; -2~2
	sta zTMP0
	mva #0, zTMP2
	ldx #119
	lda #222
frame4 = *-1
	add #4
	sta frame4
	tay
-	lda SineTable,y
	asr a ; x64
	asr a ; x32
	sta _add
	asr a ; x16
	add #0
_add = *-1
	sta pyrX+4,x
	tya
	add #$40
	bpl +
	lda #>(pyr00^pyr02)
	gne ++
+	lda #0
+	sta dpyr+4,x
	addb zTMP0, zTMP2
	tya
	adc zTMP1
	tay
	dex
	bpl -

updatepyrtwisterY
	lda #55
frame2 = *-1
	add #5
	sta frame2
	tax
	ldy #0
-	lda #0
ddl3 = *-1
	eor dpyr+4,y
	sta dp0+1
	sta dp1+1
	eor #>(pyr00^pyr02)
	sta dp2+1
	sta dp3+1
	lda buf_PyrTwister,x
	sta pyr00+4,y
dp0 = *-2
	lda buf_PyrTwister+32,x
	sta pyr01+4,y
dp1 = *-2
	lda buf_PyrTwister,x
	sta pyr02+4,y
dp2 = *-2
	lda buf_PyrTwister+32,x
	sta pyr03+4,y
dp3 = *-2
	inx
	txa
	and #31
	tax
	iny
	cpy #120
	bne -
    jmp beginprog
	
vbi
	sta nmiA
	stx nmiX
	bit rNMIST
	bpl +
	jmp dli0
VDSLST = *-2
+
	sty nmiY
	mva SDMCTL, rDMACTL
	mwa SDLSTL, rDLISTL
	lda #0
PMBAS = *-1
	sta rPMBASE
	lda #0
HSCROL = *-1
	sta rHSCROL
	mva #0, vbkreq
	jsr updateMusic
	ldy nmiY
retdli
	lda nmiA
	ldx nmiX
	rti
vbkreq	.byte 0

dli0
	ldx rVCOUNT
	lda dpyr,x
	bne _inverse
	lda zTMP7
	add pyrX,x
	sta rHPOSP1
	sub #8
	sta rHPOSP0
	lda zTMP7
	sub pyrX,x
	sta rHPOSP3
	sbc #8
	sta rHPOSP2
	gne retdli
_inverse
	lda zTMP7
	add pyrX,x
	sta rHPOSP3
	sub #8
	sta rHPOSP2
	lda zTMP7
	sub pyrX,x
	sta rHPOSP1
	sbc #8
	sta rHPOSP0
	gne retdli

scene0
	lda zCurMsxOrd
	cmp #$10
	bcc _skip
	lda zCurMsxRow
	bne _skip
	mwa #scene1, scefunc
_skip
	rts
	
scene1
	lda zCurMsxRow
	cmp #$28
	bcc _skip
	pla ; pop return address so the stack points 
	pla ; to the loader's return address instead
_skip
	rts
	
screenaddress   = buf_Screen + range(0, 52*64, 52)..range($1000, 52*64+$1000, 52)
	
tab_screen_hi   .byte >(screenaddress)
tab_screen_lo   .byte <(screenaddress)

colors	.byte $4a,$4a,$4a,$4a,$04,$0a,$0e,$36

	.align $100
	.union
buf_Twister	.binary "gfx/twmain.2bpp"
	.struct
SineTable	.fill $100
pyrX	.fill 128
dpyr	.fill 128
stwpos	.fill 120
	.ends
	.endu
buf_PyrTwister	.binary "gfx/twpyr.t.1bpp"
	
	.align $400
	.union
	.struct
displaylist0
    .fill 120*3, [$dd,$00,$a0]
    .byte $41
    .word displaylist0
	.ends
	.fill $180
	.endu
mis00	.binary "gfx/twmis.1bpp"
pyr00	.fill $80
pyr01	.fill $80
pyr02	.fill $80
pyr03	.fill $80
displaylist1	.fill $180
mis10	.fill $80
pyr10	.fill $80
pyr11	.fill $80
pyr12	.fill $80
pyr13	.fill $80
	.warn format("Part 4's memory usage: %#04x - %#04x", start, *)
