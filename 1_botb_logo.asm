; Part 1: BotB logo (and lots of stuff that will be used later by the other parts)
	.include "gvars.asm"

wCHBAS  = $2f4 ; rCHBASE is write-only, so we have to bother os memory again...
wSDLSTL = $230 ; this too

*	= partEntry
	; region check
	lda #$ff
	sta zNTSCcnt
	lda #$e
	bit rPAL
	beq +
	inc zNTSCcnt
+	
	; move char rom into ram
	mva wCHBAS, chrsrc
	sta chrsrc2
	ldx #0
	ldy #4
mvchrloop
	mva #3, rPORTB
	lda $ff00, x
chrsrc = *-1
	sta scratch, x
	dex
	bne mvchrloop
	lda #124 ; wait until out of screen
-	cmp rVCOUNT
	bne -
	mva #2, rPORTB
-	lda scratch, x
	sta $ff00, x
chrsrc2 = *-1
	dex
	bne -
	inc chrsrc
	inc chrsrc2
	dey
	bne mvchrloop
	
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
	
putlogobitmap
	; TODO transition in effect of this and has it drawn as rotozoomer pixel instead
	ldx wCHBAS
	inx
	inx ; last 64 tiles
	stx _dst
	stx _dst2
	ldx #0
	ldy #0
-	lda botbTex, x
	sta zTMP0
	jsr expand
	sta $ff00, y
_dst = *-1
	jsr expand
	sta $ff40, y
_dst2 = *-1
	iny
	inx
	beq + ; done
	txa
	and #$3f ; 8 tiles yet?
	bne -
	tya
	add #64
	tay
	bne -
	inc _dst
	inc _dst2
	jmp -
+
	mwa #vbk, rNMI
	mwa #dummy, rRESET
	mwa #dummy, rIRQ
	
	mva #0, rIRQEN
	mva #$40, rNMIEN ; vblank
	cli
-	jmp -

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
	lda zNTSCcnt
	bmi ++ ; PAL
	bne +
	mva #5, zNTSCcnt
	rti

+	dec zNTSCcnt
+	jsr updateMusic
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

botbTex	.binary "botb.4x8.1bpp"

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

scratch .fill $100
