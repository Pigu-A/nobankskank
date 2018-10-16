; mptplfox.asm test
	.include "../gvars.asm"
	.enc "a8screen"
	
SDMCTL = $22f
SDLSTL = $230
GPRIOR = $26f
COLOR  = $2c0

HEIGHT = 102
	
*	= $02e0
	.word start
	
*	= $2000
start
; init player variables
	mva #3, rSKCTL
	sta rSKCTL+$10
; convert the mpc file back to mpt
	mva msx+$1c8, lenpat
	ldx msx+$1c9
	dex
	stx tempo
	ldx #$c0 ; instrument pointers
-	lda msx-2,x
	ora msx-1,x
	beq + ; skip empty slot
	clc
	lda msx-2,x
	adc <#msx
	sta msx-2,x
	lda msx-1,x
	adc >#msx
	sta msx-1,x
+	dex
	dex
	bne -
	ldx #0 ; tuning table
-	txa
	and #$3f ; start of table
	bne +
	ldy msx+$c0,x
	jmp ++
+	tya
	clc
	adc msx+$c0,x
	sta msx+$c0,x
	tay
+	inx
	bne -
	ldx #4 ; pattern pointers
-	clc
	lda msx+$1bf,x
	adc <#msx
	sta msx+$1bf,x
	lda msx+$1c3,x
	adc >#msx
	sta msx+$1c3,x
	dex
	bne -
	
	mwa #dlist, SDLSTL
	mva >#pm, rPMBASE
	mva #$01, GPRIOR ; all players above pf
	mva #$26, SDMCTL ; enable missile and dlist dma, normal pf, double line player
	mva #$01, rGRACTL ; turn on missile
	lda #$0e
	sta COLOR
	sta COLOR+1
	sta COLOR+2
	sta COLOR+3
	sta COLOR+5
	mva #0, COLOR+6
	mva #$90, COLOR+8
	lda #"C"
	sta coord40(1,0,scr)
	sta coord40(1,4,scr)
	sta coord40(1,8,scr)
	sta coord40(1,12,scr)
	lda #"H"
	sta coord40(2,0,scr)
	sta coord40(2,4,scr)
	sta coord40(2,8,scr)
	sta coord40(2,12,scr)
	ldx #"1"
	stx coord40(3,0,scr)
	inx
	stx coord40(3,4,scr)
	inx
	stx coord40(3,8,scr)
	inx
	stx coord40(3,12,scr)
	lda #"<"
	sta coord40(0,2,scr)
	sta coord40(0,6,scr)
	sta coord40(0,10,scr)
	sta coord40(0,14,scr)
	lda #">"
	sta coord40(33,2,scr)
	sta coord40(33,6,scr)
	sta coord40(33,10,scr)
	sta coord40(33,14,scr)
	lda #$03
	ldx #$18
	ldy #4
-	sta mis,x
	sta mis+1,x
	sta mis+2,x
	sta mis+3,x
	asl a
	asl a
	pha
	txa
	adc #16
	tax
	pla
	dey
	bne -
	
loop
	lda #76 ; wait until display end
-	cmp rVCOUNT
	bne -
	sta rWSYNC
	mva #$96, rCOLBK
	jsr update
	mva #$90, rCOLBK
	; clear filter tiles
	mwa #coord40(18,0,scr)-1, _clrt
	ldx #0
-	ldy _clrtd,x
	inx
	lda #0
-	sta *,y
_clrt = *-2
	dey
	bne -
	lda _clrtd,x
	add _clrt
	sta _clrt
	bcc +
	inc _clrt+1
+	inx
	cpx #size(_clrtd)
	bne --
	mwa #coord40(34,0,scr), zARG0
	lda zCurMsxOrd
	jsr printhex
	mwa #coord40(37,0,scr), zARG0
	lda zCurMsxRow
	jsr printhex
	lda aud
	and #4 ; highpass 1+3
	beq +
	mva #$5e, coord40(34,2,scr) ; left arrow
	mva #$45, coord40(35,2,scr) ; dl corner
	lda #$7c ; vert line
	sta coord40(35,3,scr)
	sta coord40(35,4,scr)
	sta coord40(35,5,scr)
	sta coord40(35,6,scr)
	sta coord40(35,7,scr)
	sta coord40(35,9,scr)
	mva #$43, coord40(35,10,scr) ; ul corner
	mva #$52, coord40(34,10,scr) ; horz line
	mva #"H", coord40(34,8,scr)
	mva #"P", coord40(35,8,scr)
	mva #"F", coord40(36,8,scr)
+	lda aud
	and #2 ; highpass 2+4
	beq +
	mva #$5e, coord40(34,6,scr) ; left arrow
	mva #$45, coord40(37,6,scr) ; dl corner
	lda #$7c ; vert line
	sta coord40(37,7,scr)
	sta coord40(37,8,scr)
	sta coord40(37,9,scr)
	sta coord40(37,10,scr)
	sta coord40(37,11,scr)
	sta coord40(37,13,scr)
	mva #$43, coord40(37,14,scr) ; ul corner
	lda #$52 ; horz line
	sta coord40(35,6,scr)
	sta coord40(36,6,scr)
	sta coord40(34,14,scr)
	sta coord40(35,14,scr)
	sta coord40(36,14,scr)
	mva #"H", coord40(36,12,scr)
	mva #"P", coord40(37,12,scr)
	mva #"F", coord40(38,12,scr)
+	
	lda aud
	and #1 ; 16kHz mode
	asl a ; x2
	asl a ; x4
	sta zTMP4
	lda aud
	ldx #0
	and #$80 ; 9-bit poly
	beq +
	ldx #8*4
+	stx zTMP3
	ldx #0
-	ldy #0
	lda infoposLo,x
	sta zARG0
	lda infoposHi,x
	sta zARG0+1
	mwa #txt_freqs, printinfo.src
	lda aud
	ldy zTMP4
	cpx #1
	bne +
	and #$40 ; ch1 1.79
	beq +
	ldy #8
+	cpx #3
	bne +
	and #$20 ; ch3 1.79
	beq +
	ldy #8
+	stx zTMP1
	tya
	tax
	ldy #0
	jsr printinfo
	mwa #txt_polys, printinfo.src
	ldx zTMP1
	lda volume,x
	tay
	ldx #16*4
	and #$10 ; vol only
	bne ++
+	tya
	and #$e0
	lsr a ; x16
	lsr a ; x8
	lsr a ; x4
	add zTMP3
	tax
+	ldy #5
	jsr printinfo
	ldx zTMP1
	lda volume,x
	and #$f
	beq +
	sta zTMP2
	lda #$80
	ldy #12
-	sta (zARG0),y
	iny
	dec zTMP2
	bne -
+	lda freq,x
	eor #$ff
	lsr a
	add #$33
	sta rHPOSM0,x
	inx
	cpx #4
	bne --
	jmp loop
	
	; ([tiles][add offset])..
_clrtd .byte 15,96,2,41,1,23,18,57,1,39,4,41,3,23,20,57,3,39,4,43,1,21,15,18,3,41,1,37,4,0
	
printinfo	.block
	mva #4, zTMP0
-	lda *,x
src = *-2
	sta (zARG0),y
	inx
	iny
	dec zTMP0
	bne -
	rts
	.bend
	
infoposLo
	.byte <coord40(6,0,scr)
	.byte <coord40(6,4,scr)
	.byte <coord40(6,8,scr)
	.byte <coord40(6,12,scr)
infoposHi
	.byte >coord40(6,0,scr)
	.byte >coord40(6,4,scr)
	.byte >coord40(6,8,scr)
	.byte >coord40(6,12,scr)
	
printhex
	ldy #0
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	beq +
	tax
	lda _chars,x
+	sta (zARG0),y
	iny
	pla
	and #$f
	tax
	lda _chars,x
	sta (zARG0),y
	rts
_chars .text "0123456789ABCDEF"
	
txt_freqs
	.text "64K 16K 1.79"
txt_polys ;0   2   4   6   8   a   c   e
	.text "5+175   5+4 5   17  TONE4   TONE"
	.text "5+9 5   5+4 5   9   TONE4   TONE"
	.text "VOLO"
	
dlist
	.fill 3, $70
	.byte $42
	.word scr
	.fill 14, $02
	.byte $41
	.word dlist
	
update .include "../mptplfox.asm"
msx	.binary "../CZUJESZT.MPC"

	.align $400
pm	.fill $180
mis	.fill $80
scr	.fill 40*15
