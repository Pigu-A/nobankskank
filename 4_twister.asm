; Part 4: Twister
	.include "gvars.asm"

buf_Screen  = $a000
buf_Screen2 = $e000

;ANTIC
SDMCTL = $022f               ; ANTIC Control Register 00= OFF $22 = ON
SDLSTL = $0230               ; ANTIC DISPLAY LIST
COLOR  = $02c0

*	= partEntry
start
	; clear screen
	lda #0
	ldx #0
	ldy #(>(60*40))+1
-	sta buf_Screen,x
_dst00 = *-2
	sta buf_Screen+$1000,x
_dst01 = *-2
	sta buf_Screen2,x
_dst10 = *-2
	sta buf_Screen2+$1000,x
_dst11 = *-2
	inx
	bne -
	inc _dst00+1
	inc _dst01+1
	inc _dst10+1
	inc _dst11+1
	dey
	bne -
	lda #>SineTable
	jsr loadSineTable
	
    mwa #displaylist, SDLSTL        ; Load display list address and store address into OS display pointer
    mva #$22, SDMCTL                ; Turn ANTIC back ON
	jsr disnmi
	mwa #vbi, rNMI
	mva #$40, rNMIEN ; vblank
	mva #$04, COLOR+4
	mva #$0a, COLOR+5
	mva #$0e, COLOR+6
beginprog
	lda page+1
	eor #>(buf_Screen^buf_Screen2) ; flip the page
	sta page+1
	eor #$10
	sta page2+1
	; wait for vblank to properly display the finished page
	sta vbkreq
-	lda vbkreq
	bne -
	jsr scene0 ; update scene-specific variables
scefunc = *-2
	
    ldx #0
justblit
prepare_buffer_positons
    lda tab_screen_hi,x
    sta screen+1
    lda tab_screen_lo,x
    sta screen
	ldy twposL,x
    lda tab_twist_hi,y
    sta twist+1
    lda tab_twist_lo,y
    sta twist
	iny
	cpy #80
	bcc +
	ldy #0
+	sty zTMP0
    ldy #9
blit_line
    lda $ffff,y
twist = *-2
    sta $ffff,y
screen = *-2
    dey
	bpl blit_line
blit_line_finish
    inx
	cpx #120
    bne justblit
done

updatetwister
	ldx #0
frame = *-1
	inx
	inx
	stx frame
	ldy #0
	sty zTMP0
	lda SineTable,x
	bpl +
	dey
+	sty zTMP1
	asl a
	rol zTMP1
	asl a
	rol zTMP1
	sta zTMP2
	lda #0
ypos = *-1
	add #3
	cmp #80
	bcc +
	sub #80
+	sta ypos
	ldy #0
-	sta twposL,y
	sta _hi
	addb zTMP2, zTMP0
	lda zTMP1
	adc #0
_hi	= *-1
	bpl +
	add #80
+	cmp #80
	bcc +
	sub #80
+	iny
	cpy #120
	bne -
	
updatescraddr
	; TODO hor shift
	ldy #0
-	lda tab_screen_hi,y
	eor #>(buf_Screen^buf_Screen2) ; flip the page
	sta tab_screen_hi,y
	iny
	cpy #120
	bne -
    jmp beginprog
	
vbi
	sta nmiA
	stx nmiX
	sty nmiY
	mva SDMCTL, rDMACTL
	mwa SDLSTL, rDLISTL
	ldx #7
-	mva COLOR,x, rCOLPM0,x
	dex
	bpl -
	mva #0, vbkreq
	jsr updateMusic
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
vbkreq	.byte 0

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
	
;===================================
;DISPLAY LIST
;===================================
; Display list to render in Mode D
displaylist
    .byte $4d                   ; ANTIC Mode D set instruction
    .word buf_Screen            ; Screen memory
page = *-2
    .fill 59, $0d
    .byte $4d
    .word buf_Screen+$1000
page2 = *-2
    .fill 59, $0d
    .byte $41                   ; Jump to wait for VBL
    .word displaylist
	
screenaddress   = range(buf_Screen+$7, buf_Screen+40*60+$7, 40)..range(buf_Screen+$1007, buf_Screen+40*60+$1007, 40)
twisteraddress  = range(buf_Twister, buf_Twister+800, 10)
	
tab_screen_hi   .byte >(screenaddress)
tab_screen_lo   .byte <(screenaddress)
tab_twist_hi    .byte >(twisteraddress)
tab_twist_lo    .byte <(twisteraddress)

buf_Twister .binary "gfx/twist.2bpp"

twposL	.fill 120
twposR	.fill 120
	
	.warn format("Part 4's memory usage: %#04x - %#04x", start, *)
