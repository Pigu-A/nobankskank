; Part 2: Parallax
	.include "gvars.asm"

screen = $e000
	
screenptr       =   $80
textureptr      =   $82
textureptrfore  =   $84

;ANTIC
sdmctl =    $022F               ; ANTIC Control Register 00= OFF $22 = ON

sdlstl =    $0230               ; ANTIC DISPLAY LIST

col0    =   rCOLPF0
col1    =   rCOLPF1
col2    =   rCOLPF2
col3    =   rCOLPF3

;NOTES-----------
; TIMERS -- NOTES
;vertical blank vector     =   $0222
;deferred vertical blank vector$0224 (after the OS increments timers/decrements system timers, etc.)
;dummy VBL routine         =   $E462

*	= partEntry
start
    mwa #displaylist, sdlstl

    ;disable NMI + DMA
    jsr disnmi
    ;setup VBL
    mwa #vblbeginprog, rNMI ;setup vbl vector

    ;renable NMI + DMA
    lda #$C0
    sta rNMIEN
    lda #$31
    sta sdmctl

    ;init colors
    lda #$02
    sta $2C4
    lda #$08
    sta $2C5
    lda #$0C
    sta $2C6
stall
	; wait for vblank
	sta rNMIRES
-	bit rNMIST
	bvc -
	jsr scene0 ; update scene-specific variables
scefunc = *-2
	lda endpart
	beq beginprog
	rts ; end this part
beginprog
    ;make sure we zero our ypointers so we don't spin or overwrite mem
    lda #0
    sta ypos
    sta typos
    ;cleanup foreground hscroll
    lda forescrollcont
    cmp #16
    blt backgroundscrollcleanup
    lda #0
    sta forescrollcont
    ;because forescroll got reset, we'll need to increment the texture pointer
    lda foretexturecont
    adc #1
    cmp #4
    blt backgroundscrollcleanup
    lda #0
    sta foretexturecont
    ;cleanup background scroll
backgroundscrollcleanup
    lda backscrollcont
    cmp #16
    blt beforedrawloop
    lda #0
    sta backscrollcont
    lda textureoff
    adc #1
    cmp #20
    blt beforedrawloop
    lda #0
beforedrawloop
    sta textureoff
    ;now make sure HSCROLL is current
    lda backscrollcont
    adc #1
    sta backscrollcont
    sta rHSCROL
;drawloop runs as deferred VBL
drawloop
    ;check screen ypointer to prevent overdrawing
    ldy ypos                    ;get the line on the screen
    cpy #47                     ;check to see the line will be out of screen memory
    bge stall
preparebufferpositions
    ;prepare the zp jump address for screen memory
    lda screen_lo,y
    sta screenptr               ;note to self, bytes are read backwards
    lda screen_hi,y
    sta screenptr+1
preparebufferpostions2
    ;prepare the zp jump address for texturememory
    ldy ypos
    lda texture_lo,y
    sta textureptr
    lda texture_hi,y
    sta textureptr+1
prepareforblit
    ldy currtexpos              ;get X for texture
blitline
    cpy #20
    blt blitlinexfer
    ldy #0                      ;going to overflow on the texture, reset xptr to 0
blitlinexfer
    lda (textureptr),y          ;get our texture byte
    sty currtexpos
    ldy currwindowx             ;get the xptr for drawing to screen
    cpy #20                     ;check to see if window X is offscreen
    bge blitlinefinish
    sta (screenptr),y           ;toss it into screen
    iny                         ;hop to next screenmemory byte
    sty currwindowx             ;store to window x var
    ldy currtexpos
    iny                         ;increment and jump back to check
    sty currtexpos
    jmp blitline
blitlinefinish
    lda #0
    sta currwindowx
    sta currtexpos
    inc ypos                    ;straight memory increment, as we'll recall later
    ;TODO: increment texture position as well, when incremented
    jmp drawloop                ;goto check stage

vblbeginprog
	sta nmiA
	stx nmiX
	sty nmiY
	bit rNMIST
	bpl +
	jmp dlipalette2
VDSLST = *-2
+	mwa sdlstl, rDLISTL
	mva sdmctl, rDMACTL
    ;make sure our colors are up to date
    lda #$02
    sta col1
    lda #$08
    sta col2
    lda #$0C
    sta col3
	jsr updateMusic
    
retdli
	lda nmiA
	ldx nmiX
	ldy nmiY
	rti

dlipalette2
    ;31 cycles in Phase One
    ;setup next DLI while there's time in Phase One
    mwa #dlipalette3, VDSLST
    sta rWSYNC                   ;set WSYNC to await next hsync
    ;20-22 cycles available for Phase Two (swap colors here)
    ;change palette colors
    lda #$50
    sta col1
    lda #$5c
    sta col2                    ;12 cycles
	gne retdli

dlipalette3
    mwa #dlipalette4, VDSLST
    sta rWSYNC                 ;WSYNC
    ;20-22 cycles available for phase 2
    ;change on Color 1 and 3
    lda #$92
    sta col0
    lda #$29
    sta col2
	gne retdli

dlipalette4
    mwa #dlipalette5, VDSLST
    sta rWSYNC                 ;WSYNC
    ;20-22 cycles available for phase 2
    ;change on Color 2 and 3
    lda #$EE
    sta col1
    lda #$D2
    sta col2
	gne retdli

dlipalette5
    ;change this to proper in the future
    mwa #dliroutine, VDSLST
    sta rWSYNC                 ;WSYNC
    ;20-22 cycles available for phase 2
    ;change color 1 and 3
    lda #$00
    sta col1
    lda #$F2
    sta col3
	gne retdli

dliroutine
    mwa #dlipalette6, VDSLST
    sta rWSYNC                   ;set WSYNC to await next hsync
    ;TODO: UPDATE TO GIVE A DIFFERENT HSCROLL VAL BASED ON MEMORY
    ;inc rHSCROL                 ;increment hscroll
    lda forescrollcont          ;get the foreground hscroll counter
    adc #2                      ;scroll at 2x speed
    sta rHSCROL
    sta forescrollcont
	jmp retdli

dlipalette6
    mwa #dlipalette7, VDSLST
    sta rWSYNC
    ;color updates
    lda #$AC 
    sta col1
    lda #$5A
    sta col2
    lda #$88
    sta col3
	gne retdli

dlipalette7
    mwa #dlipalette8, VDSLST
    sta rWSYNC
    ;color updates
    lda #$1A
    sta col2
    lda #$66
    sta col3
	gne retdli

dlipalette8
    mwa #dlipalette9, VDSLST
    sta rWSYNC
    ; color updates 
    lda #$0A
    sta col1
    lda #$E4
    sta col2
    lda #$36
    sta col3
	gne retdli

dlipalette9
    ;reset dli
    mwa #dlipalette2, VDSLST
    sta rWSYNC
    lda #$AC
    sta col1
    lda #$D6
    sta col2
    lda #$F4
    sta col3
	gne retdli
	
scene0
	lda zCurMsxOrd
	cmp #$09
	bcc _skip
	inc endpart
_skip
	rts
endpart	.byte 0

screenaddress = range(screen, screen+1176, 20)

screen_hi   .byte >(screenaddress)
screen_lo   .byte <(screenaddress)

    ;==============
    ;PRESHIFTED TEXTURES
    ;==============
realtexture     .binary "gfx/par.2bpp"

; texture address table should look like the screen table, since it's the same size
textureaddresses = range(realtexture, realtexture+960, 20)

texture_hi  .byte   >(textureaddresses)
texture_lo  .byte   <(textureaddresses)

forescrollcont  .byte   $00
foretexturecont .byte   $00
backscrollcont  .byte   $00
backtexturecont .byte   $00
ypos            .byte   $00
typos           .byte   $00

texturelen      .byte   48
textureoff      .byte   $00
currtexpos      .byte   $00
currwindowx     .byte   $00

    ;===============
    ;DISPLAY LIST
    ;===============
displaylist
    .byte $70,$70,$70; 3 blank lines to clear overscan
	.byte $5a, $00, $e0
	.byte $5a, $14, $e0
	.byte $5a, $28, $e0
	.byte $5a, $3c, $e0
	.byte $5a, $50, $e0
	.byte $5a, $64, $e0
	.byte $5a, $78, $e0
	.byte $5a, $8c, $e0
	.byte $5a, $a0, $e0
	.byte $5a, $b4, $e0
	.byte $5a, $c8, $e0
	.byte $5a, $dc, $e0
	.byte $5a, $f0, $e0
	.byte $da, $04, $e1
	.byte $5a, $18, $e1
	.byte $da, $2c, $e1
	.byte $5a, $40, $e1
	.byte $da, $54, $e1
	.byte $5a, $68, $e1
	.byte $da, $7c, $e1
	.byte $5a, $90, $e1
	.byte $5a, $a4, $e1
	.byte $da, $b8, $e1
	.byte $5a, $cc, $e1
	.byte $5a, $e0, $e1
	.byte $5a, $f4, $e1
	.byte $5a, $08, $e2
	.byte $5a, $1c, $e2
	.byte $da, $30, $e2
	.byte $5a, $44, $e2
	.byte $5a, $58, $e2
	.byte $5a, $6c, $e2
	.byte $5a, $80, $e2
	.byte $5a, $94, $e2
	.byte $da, $a8, $e2
	.byte $5a, $bc, $e2
	.byte $5a, $d0, $e2
	.byte $5a, $e4, $e2
	.byte $5a, $f8, $e2
	.byte $5a, $0c, $e3
	.byte $da, $20, $e3
	.byte $5a, $34, $e3
	.byte $5a, $48, $e3
	.byte $5a, $5c, $e3
	.byte $5a, $70, $e3
	.byte $5a, $84, $e3
	.byte $5a, $98, $e3
	.byte $5a, $ac, $e3
    .byte $41             ;Jump to wait for VBL
    .word displaylist       ;ABSOLUTELY NEEDS TO BE THE DISPLAY LIST ITSELF
	.warn format("Part 2's memory usage: %#04x - %#04x", start, *)
	