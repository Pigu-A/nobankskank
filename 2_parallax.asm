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
    ldy scrollstallcont
    cpy #scrollstall
    blt bp2
    ldy #0
    sty scrollstallcont
bp2
    inc scrollstallcont
    lda #0
    sta ypos
    ;cleanup foreground hscroll
foregroundscrollcleanuphscroll
 ;   dec forescrollcont  ;balance forescroll - this is super dumb, I know
    ;lda forescrollcont
    ;and #7
    ;sta forescrollcont
    ;cmp #0
    ;bne skip2
foregroundscrollcleanuptexture
    ;lda foretexturecont
    ;add #1
    ;cmp #20
    ;blt forescrollcleanupdone2
    ;lda #0
    ;sta foretexturecont
forescrollcleanupdone2
    ;sta foretexturecont
    ;jmp backgroundscrollcleanupcheck
skip2

backgroundscrollcleanupcheck
    ;always update hscrol to make sure background is scrolling correcrtly
    lda backscrollcont
    sta rHSCROL
    ;check if this is an update frame
    ;ldy scrollstallcont
    ;cpy #scrollstall
    ;blt backgroundscrollcleanupdone
backgroundscrollcleanuphscroll  
    ;check if scrollcont needs to be updated
    ;dec backscrollcont
    ;bpl skip              ;move scroll
   ; cmp #255             ;compare to see if out of range
   ; blt backgroundscrollcleanupdone1
    ;lda #7             ;zero the scroll counter for background
    ;sta backscrollcont
skip
backgroundscrollcleanuptexture
    ;lda backtexturecont
    ;add #1             ;add one
    ;cmp #20             ;if it's out of range
    ;blt backgroundscrollcleanupdone2
    ;lda #0
    ;sta backtexturecont
    ;jmp backgroundscrollcleanupdone
backgroundscrollcleanupdone2
    sta backtexturecont
    jmp backgroundscrollcleanupdone
backgroundscrollcleanupdone1
    sta backscrollcont
backgroundscrollcleanupdone
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
checkwindowline
    ;should have the ypos still in reg y
    cpy #26                     ;get an actual value for this
    bge prepareforblitforeground    ;if we're low enough on the screen, this will be the foreground scroller
prepareforblit
    ldy backtexturecont              ;get the offset for texture1
    sty currtexpos
blitline
    cpy #20                     ;check if the value is outside of tex memory
    blt blitlinexfer
    ldy #0                      ;going to overflow on the texture, reset xptr to 0
    sty currtexpos
blitlinexfer
    lda (textureptr),y          ;get our texture byte
    ldy currwindowx             ;get the xptr for drawing to screen
    cpy #20                     ;check to see if window X is offscreen
    bge blitlinefinish
    sta (screenptr),y           ;toss it into screen
    inc currwindowx             ;increment the window position
    inc currtexpos            ;increment the texture position 
    ldy currtexpos            ;prepare to check texture mapping ptr 
    jmp blitline
blitlinefinish
    lda #0
    sta currwindowx             ;reset window position
    inc ypos                    ;straight memory increment, as we'll recall later
    ;TODO: increment texture position as well, when incremented
    jmp drawloop                ;goto check stage
prepareforblitforeground
    ldy foretexturecont
    sty currtexpos
    jmp blitline                ; we just needed to tack this on to grab foretexturecont

vblbeginprog
	sta nmiA
	stx nmiX
	sty nmiY
	bit rNMIST
	bpl +
    ;is this treating dli as an interrupt, or is it just executing in order at the end of vbl?
	jmp dlipalette2
VDSLST = *-2
+	mwa sdlstl, rDLISTL
	mva sdmctl, rDMACTL
    mwa #dlipalette2, VDSLST
    ;make sure our colors are up to date
    lda #$EE
    sta col1
    lda #$FE
    sta col2
    lda #$0C
    sta col3
	jsr updateMusic

   inc d7a+1
   inc d7b+1

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
    lda #$00
    sta col0
    lda #$66
    sta col1
    lda #$50
    sta col2                    ;12 cycles
	gne retdli

dlipalette3
    mwa #dlipalette4, VDSLST
    sta rWSYNC                 ;WSYNC
    ;20-22 cycles available for phase 2
    ;change on Color 1 and 3
    lda #$ac
    sta col0
    lda #$96
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
    ;lda scrollstallcont
    ;cmp #scrollstall
    ;blt retdli
    lda forescrollcont          ;get the foreground hscroll counter
    sta rHSCROL
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
d7a    lda #$1A
    sta col2
d7b    lda #$66
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

forescrollcont  .byte   $03
foretexturecont .byte   $00
backscrollcont  .byte   $03
backtexturecont .byte   $00
ypos            .byte   $00

currtexpos      .byte   $00
currwindowx     .byte   $00

scrollstallcont .byte   $00
scrollstall     = 2

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
	.byte $5a, $04, $e1
	.byte $5a, $18, $e1
	.byte $5a, $2c, $e1
	.byte $5a, $40, $e1
	.byte $5a, $54, $e1
	.byte $5a, $68, $e1
	.byte $5a, $7c, $e1
	.byte $5a, $90, $e1
	.byte $5a, $a4, $e1
	.byte $5a, $b8, $e1
	.byte $5a, $cc, $e1
	.byte $5a, $e0, $e1
	.byte $5a, $f4, $e1
	.byte $5a, $08, $e2
	.byte $5a, $1c, $e2
	.byte $5a, $30, $e2
	.byte $5a, $44, $e2
	.byte $5a, $58, $e2
	.byte $5a, $6c, $e2
	.byte $5a, $80, $e2
	.byte $5a, $94, $e2
	.byte $5a, $a8, $e2
	.byte $5a, $bc, $e2
	.byte $5a, $d0, $e2
	.byte $5a, $e4, $e2
	.byte $5a, $f8, $e2
	.byte $5a, $0c, $e3
	.byte $5a, $20, $e3
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
	