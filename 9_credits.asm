; Part 9: credits + compo info
	.include "gvars.asm"
	
SDMCTL = $22f
SDLSTL = $230

zp = GVarsZPBegin-11
ptr = zTMP4
i = zTMP0
j = zTMP1
alpha = zp
beta = zp+1
gamma = zp+2
delta = zp+3
complex_ac = zp+4
complex_ad = zp+5
complex_bc = zp+6
complex_bd = zp+7
alpha_sin = zp+8
beta_sin = zp+9
quadrant = zp+10
k = zTMP2
l = zTMP3

screen_mem = $a000
screen_mem_v2 = $e000

*	= partEntry
start
	; clear screen
	lda #0
	ldy #ceil(40*64/256)
-	tax
-	sta screen_mem,x
_dst00 = *-2
	sta screen_mem+$1000,x
_dst01 = *-2
	sta screen_mem_v2,x
_dst10 = *-2
	sta screen_mem_v2+$1000,x
_dst11 = *-2
	inx
	bne -
	inc _dst00+1
	inc _dst01+1
	inc _dst10+1
	inc _dst11+1
	dey
	bne --
	
	; copy right gfx
	ldy #0
-	ldx #18
	mva screen_lo_table_v1+72,y, _dst
	mva screen_hi_table_v1+72,y, _dst+1
	mva screen_lo_table_v2+72,y, _dst2
	mva screen_hi_table_v2+72,y, _dst2+1
-	lda right_gfx-18,x
_src = *-2
	sta $ffff,x
_dst = *-2
	sta $ffff,x
_dst2 = *-2
	inx
	cpx #40
	bne -
	addw #22, _src
	iny
	cpy #112
	bne --
	
	; clear old texels since it can potentially corrupt the copied art
	lda #0
	tax
-	sta old_texels_v1_x,x
	sta old_texels_v1_y,x
	sta old_texels_v2_x,x
	sta old_texels_v2_y,x
	inx
	bne -

	; init tables
	lda #>sine_table
	jsr loadSineTable
	lda #0
	tax
-	sta neg_table,x
	sub #1
	inx
	bne -
	ldx #0
-	mva quad_texels_x,x, base_texels_x,x
	mva quad_texels_y,x, base_texels_y,x
	inx
	bne -
	
	; Init alpha/beta
	sta quadrant
	sta alpha
	ora #$40
	sta beta
	eor #$c0
	sta gamma
	ora #$40
	sta delta
	
	; Set text colors, then background colors
	lda #$df
	sta text_color
	sta rCOLPF0
	sta rCOLPF1
	lda #$80
	sta background_color
	sta rCOLPF2
	sta rCOLBK
	lda #$e0
	sta rCOLPM0
	sta rCOLPM1
	lda #3
	sta rSIZEP0
	sta rSIZEP1
	mva #>bottom_gfx, rCHBASE
	mva #>(player0-$200), rPMBASE
	mva #$34, rHPOSP0
	mva #$54, rHPOSP1
	mva #$2a, SDMCTL ; enable player and dlist dma, normal pf, double line player
	mwa disp_list1, SDLSTL
	mva #$02, rGRACTL
	
	; Disable NMI + DMA
	jsr disnmi
	mwa #vbl_irq, rNMI
	; Re-enable NMI + DMA
	mva #$40, rNMIEN
loop
	inc vbkreq
-	lda vbkreq
	bne -
play_frame
increase_angle
	inc alpha
	inc beta
	inc gamma
	inc gamma
	inc gamma
	;inc gamma
	;inc gamma
	inc delta
	lda alpha
	and #$40
	beq _skip
	lda #$00
	sta alpha
	lda #$40
	sta beta
	;lda #$80
	;sta gamma
	;lda #$c0
	;sta delta
	ldx quadrant
	inx
	txa
	and #$03
	sta quadrant
	jsr rotate_texels
_skip
	jsr update_complex_table
	jsr transform_texels

odd_frame
	ldx alpha
	txa
	and #$01
	bne double_frame
	jsr clear_texels_v1
	jsr render_texels_v1
	mwa #disp_list1, SDLSTL
	jmp loop

double_frame
	jsr clear_texels_v2
	jsr render_texels_v2
	mwa #disp_list2, SDLSTL
    jmp loop

vbl_irq
	sta nmiA
	stx nmiX
	sty nmiY
	mwa SDLSTL, rDLISTL
	mva SDMCTL, rDMACTL
	mva #0, vbkreq
	lda zCurMsxOrd
	cmp #$31
	bcs +
	jsr updateMusic
+	lda nmiA
	ldx nmiX
	ldy nmiY
	rti
vbkreq           .byte 0
text_color       .byte 0
background_color .byte 0
period           .byte 0

multiply_kl:
	lda #$00
	sta i
	sta j
_x := 0
	.rept 8
	.if _x != 0
	asl i
	rol j
	.fi
	asl k
	bcc +
	lda l
	add i
	sta i
	lda j
	adc #$00
	sta j
+
_x := 1
	.next
	lda j
	asl a
	rts

render_texels_v1
	ldx #$00
texel_loop_v1
	stx zTMP0
	mva texels_y,x, old_texels_v1_y,x
	tay
	lda texels_x,x
	tax
	lda screen_lo_table_v1,y
	sta ptr
	lda screen_hi_table_v1,y
	sta ptr+1
	lda bit_table,x
	ldy asr3_table,x
	ora (ptr),y
	sta (ptr),y
	ldx zTMP0
	tya
	sta old_texels_v1_x,x
	inx
	cpx #texel_count
	bne texel_loop_v1
	rts

render_texels_v2
	ldx #$00
texel_loop_v2
	stx zTMP0
	mva texels_y,x, old_texels_v2_y,x
	tay
	lda texels_x,x
	tax
	lda screen_lo_table_v2,y
	sta ptr
	lda screen_hi_table_v2,y
	sta ptr+1
	lda bit_table,x
	ldy asr3_table,x
	ora (ptr),y
	sta (ptr),y
	ldx zTMP0
	tya
	sta old_texels_v2_x,x
	inx
	cpx #texel_count
	bne texel_loop_v2
	rts

clear_texels_v1
	ldx #$00
	stx zTMP0
clear_texel_loop_v1
	ldy old_texels_v1_y,x
	lda screen_lo_table_v1,y
	sta ptr
	lda screen_hi_table_v1,y
	sta ptr+1
	lda #$00
	ldy old_texels_v1_x,x
	sta (ptr),y
	inc zTMP0
	ldx zTMP0
	cpx #texel_count
	bne clear_texel_loop_v1
	rts

clear_texels_v2
	ldx #$00
	stx zTMP0
clear_texel_loop_v2
	ldy old_texels_v2_y,x
	lda screen_lo_table_v2,y
	sta ptr
	lda screen_hi_table_v2,y
	sta ptr+1
	lda #$00
	ldy old_texels_v2_x,x
	sta (ptr),y
	inc zTMP0
	ldx zTMP0
	cpx #texel_count
	bne clear_texel_loop_v2
	rts
	
; old routines

rotate_texels_v0:
	ldx #$00
rotation_loop_v0:
	lda quad_texels_x,x
	sta base_texels_x,x
	lda quad_texels_y,x
	sta base_texels_y,x
	inx
	cpx #texel_count
	bne rotation_loop_v0
	rts

rotate_texels_v1:
	ldx #$00
rotation_loop_v1:
	lda quad_texels_x,x
	sta base_texels_y,x
	ldy quad_texels_y,x
	lda neg_table,y
	sta base_texels_x,x
	inx
	cpx #texel_count
	bne rotation_loop_v1
	rts

rotate_texels:
	lda quadrant
	cmp #$03
	beq rotate_texels_v1
	cmp #$02
	beq rotate_texels_v2
	cmp #$01
	beq rotate_texels_v3
	jmp rotate_texels_v0

rotate_texels_v2:
	ldx #$00
rotation_loop_v2:
	ldy quad_texels_x,x
	lda neg_table, y
	sta base_texels_x,x
	ldy quad_texels_y,x
	lda neg_table, y
	sta base_texels_y,x
	inx
	cpx #texel_count
	bne rotation_loop_v2
	rts

rotate_texels_v3:
	ldx #$00
rotation_loop_v3:
	ldy quad_texels_x,x
	lda neg_table, y
	sta base_texels_y,x
	lda quad_texels_y,x
	sta base_texels_x,x
	inx
	cpx #texel_count
	bne rotation_loop_v3
	rts

transform_texels:
	ldx #$00
transform_loop:
	ldy base_texels_x,x
	lda real_table,y
	ldy base_texels_y,x
	sub imag_table,y
	sta texels_x,x
	lda real_table,y
	ldy base_texels_x,x
	add imag_table,y
	sta texels_y,x
	inx
	cpx #texel_count
	bne transform_loop
	rts

update_complex_table
	ldx alpha
	lda sine_table,x
	sta k
	ldx gamma
	lda half_sine_table,x
	sta l
	jsr multiply_kl
	sta alpha_sin
	ldx beta
	lda sine_table,x
	sta k
	ldx gamma
	lda half_sine_table,x
	sta l
	jsr multiply_kl
	sta beta_sin
	lda #$00
	tax
_x := 0
	.rept 128
	add alpha_sin
	bcc +
	inx
+	stx real_table+_x
_x := _x+1
	.next
	lda #$00
	tax
_x := -1
	.rept 128
	sub alpha_sin
	bcs +
	dex
+	stx real_table+$100+_x
_x := _x-1
	.next
	lda #$00
	tax
_x := 0
	.rept 128
	add beta_sin
	bcc +
	inx
+	stx imag_table+_x
_x := _x+1
	.next
	lda #$00
	tax
_x := -1
	.rept 128
	sub beta_sin
	bcs +
	dex
+	stx imag_table+$100+_x
_x := _x-1
	.next
	rts
	
texel_count = 248
	.align $100
quad_texels_x	.binary "gfx/texel_data.bin", 0, texel_count
	.align $100
quad_texels_y	.binary "gfx/texel_data.bin", texel_count, texel_count
	.align $100
bit_table
	.fill 256, [$01, $02, $04, $08, $10, $20, $40, $80]
asr3_table
_x := 0
	.rept 128
	.char 8-_x/8
_x := _x+1
	.next
_x := -128
	.rept 128
	.char 8-_x/8
_x := _x+1
	.next

half_sine_table
_x := 0
	.rept 256
	.byte sin(rad(_x*360.0/256.0))*56+72
_x := _x+1
	.next

screen_layout = range($1000, 40*64+$1000, 40)..range(0, 40*64+0, 40)
screen_table_v1 = screen_mem + screen_layout..screen_layout
screen_table_v2 = screen_mem_v2 + screen_layout..screen_layout
screen_lo_table_v1	.byte <(screen_table_v1)
screen_hi_table_v1	.byte >(screen_table_v1)
screen_lo_table_v2	.byte <(screen_table_v2)
screen_hi_table_v2	.byte >(screen_table_v2)
	
	.align $400
	.union
	.struct
disp_list1
	.byte $70, $70
	.byte $4f
	.word screen_mem
	.fill 63, $0f
	.byte $4f
	.word screen_mem+$1000
	.fill 63, $0f
	.byte $70, $42
	.word char_mem
	.fill 9, $02
	.byte $41
	.word disp_list1
	.ends
	.fill $200
	.endu
player0
	.fill 12, $00
	.fill 64, $ff
	.fill 52, $00
player1
	.fill 12, $00
	.fill 64, $ff
	.fill 52, $00
sine_table .fill 256
	
disp_list2
	.byte $70, $70
	.byte $4f
	.word screen_mem_v2
	.fill 63, $0f
	.byte $4f
	.word screen_mem_v2+$1000
	.fill 63, $0f
	.byte $70, $42
	.word char_mem
	.fill 9, $02
	.byte $41
	.word disp_list2
char_mem	.binary "gfx/credits_map.bin"
	
	.align $400
bottom_gfx	.binary "gfx/credits.t.1bpp"

	.union
right_gfx	.binary "gfx/tryyourbest.1bpp"
	.struct
	.align $100
neg_table       .fill 256
real_table      .fill 256
imag_table      .fill 256
old_texels_v1_x .fill 256
old_texels_v1_y .fill 256
old_texels_v2_x .fill 256
old_texels_v2_y .fill 256
base_texels_x   .fill 256
base_texels_y   .fill 256
texels_x        .fill 256
texels_y        .fill 256
	.ends
	.endu
	.warn format("Part 9's memory usage: %#04x - %#04x", start, *)
