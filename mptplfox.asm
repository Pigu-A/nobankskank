; Player MPT 2.4
; by Fox/Infinity
; 07,19,25,30/07/96
; original version by Jaskier/Taquart

zp     = $e4

freq   = zp
slup   = zp+4
ad     = zp+8
aud    = zp+10
tp     = zp+11

	ldx freq
	ldy freq+1
	lda aud
	sta rAUDCTL
	and #$10
v10 = *-1
	beq w1
	ldy numdzw+1
	ldx bsfrql,y
	lda bsfrqh,y
	tay
w1
	stx rAUDF1
	sty rAUDF2
	lda freq+2
	sta rAUDF3
	lda freq+3
	sta rAUDF4
	lda volume
	sta rAUDC1
	lda volume+1
	sta rAUDC2
	lda volume+2
	sta rAUDC3
	lda volume+3
	sta rAUDC4

	mvx #0, aud
	inc licz
	lda zCurMsxRow
	cmp #$40
lenpat = *-1
	dec zegar
	bcc r1
	bne r5
	stx zCurMsxRow
p2	lda #$ff
	sta ptrwsk,x
	sta licspc,x
	lda msx+$1c0,x
	sta ad
	lda msx+$1c4,x
	sta ad+1
	ldy zCurMsxOrd
p3	lda (ad),y
	iny
	cmp #$fe
	bcc p6
	beq p4
	lda (ad),y
	bmi p4
	asl a
	tay
	sta zCurMsxOrd
	bcc p3
p6	asl a
	sta numptr,x
	lda (ad),y
	sta poddzw,x
p7	inx
	cpx #4
	bcc p2
	iny
	sty zCurMsxOrd
	bcs r5
p4	ldx #3
	lda #0
fin	sta volume,x
	dex
	bpl fin
	dec zCurMsxRow
	inc zegar
ret	rts

r1	bpl r5
	ldx #3
r2	dec licspc,x
	bpl r4
	ldy numptr,x
	lda msx+$41,y
	beq r4
	sta ad+1
	lda msx+$40,y
	sta ad
	ldy ptrwsk,x
	jmp newdzw
r3	lda ilespc,x
	sta licspc,x
r4	dex
	bpl r2
	lda #5
tempo = *-1
	sta zegar
	inc zCurMsxRow

r5	ldx #3
	bne r6

d0	sta volume,x
	jmp r9

r8	ldy #$23
	lda (ad),y
	ora aud
	sta aud
	lda (ad),y
	and filtry,x
	beq r9
	ldy #$28
	lda (ad),y
	add numdzw,x
	jsr czest
	sec
	adc p1pom,x
	sta freq+2,x
r9	dex
	bmi ret
r6	lda adrinh,x
	beq d0
	sta ad+1
	lda adrinl,x
	sta ad
	ldy slup,x
	cpy #$20
	bcs d3
	lda (ad),y
	adc adcvol,x
	bit v10
	beq d1
	and #$f0
d1	sta volume,x
	iny
	lda (ad),y
	iny
	sty slup,x
	sta tp
	and #7
	beq d4
	tay
	lda akce-1,y
	sta akbr+1
	lda tp
	.rept 5
	lsr a
	.next
	ora #$28
	tay
	lda (ad),y
	clc
akbr	bcc *
ak

a0	adc freq,x
a1	sta freq,x
	jmp r9
a2	jsr aczest
	sta freq,x
	jmp r9
a4	sta freq,x
	lda ndziel,x
	bpl a7
a5	sta freq,x
	lda #$80
	bne a7
a6	sta freq,x
	lda #1
a7	ora aud
	sta aud
	jmp r9
a8	and rRANDOM
	sta freq,x
	jmp r9

d3	iny
	iny
	bne *+4
	ldy #$20
	sty slup,x
	lda volume,x
	and #$0f
	beq d4
	ldy #$22
	lda (ad),y
	beq d4
	dec p3lic,x
	bne d4
	sta p3lic,x
	dec volume,x
d4	lda slup,x
	and #6
	lsr a
	adc #$24
	tay
	lda (ad),y
	jsr aczest
	sta freq,x
	ldy branch,x
	sty typbr+1
	ldy p2lic,x
typbr	beq *
so
	dec p2lic,x
	jmp r8

s0	lda #2
	and #0
licz = *-1
	beq t2
	asl a
	and licz
	bne t0
	lda p1lsb,x
t1	sta p1pom,x
	adc freq,x
	sta freq,x
	jmp r8
t0	lda freq,x
s1	sub p1lsb,x
	sta freq,x
	tya
	sub p1lsb,x
t2	sta p1pom,x
	jmp r8
s2	lda p1lic,x
t9	sta p1pom,x
	add freq,x
t3	sta freq,x
	lda p1lic,x
	add p1lsb,x
	sta p1lic,x
	jmp r8
s3	lda numdzw,x
	sub p1lic,x
t4	jsr nczest
	jmp t3
s4	tya
	sub p1lic,x
	jmp t9
s5	lda numdzw,x
	add p1lic,x
	jmp t4
s6	jsr t5
	jmp t1
s7	jsr t5
	adc numdzw,x
	jsr nczest
	sta freq,x
	jmp r8
t5	ldy p1lic,x
	lda p1lsb,x
	bmi *+4
	iny
	iny
	dey
	tya
	sta p1lic,x
	cmp p1lsb,x
	bne t7
	eor #$ff
	sta p1lsb,x
	lda p1lic,x
t7	clc
	rts
aczest	adc adcdzw,x
nczest	sta numdzw,x
czest	and #$3f
	ora frqwsk,x
	tay
	lda msx+$c0,y
	rts

nins	sty tp
	and #$1f
	asl a
	tay
	lda msx,y
	sta adrinl,x
	lda msx+1,y
	sta adrinh,x
	ldy tp
newdzw	lda #0
newavo	sta adcvol,x
new	iny
	lda (ad),y
	bpl q4
	cmp #$fe
	bne q0
	tya
	sta ptrwsk,x
	jmp r3
q0	cmp #$c0
	bcc q3
	cmp #$e0
	bcc q1
	mva lenpat, zCurMsxRow
	bcs new
q1	cmp #$d0
	bcc q2
	and #$0f
	sta tempo
	bpl new
q2	adc #$31
	bvc newavo
q3	and #$3f
	sta ilespc,x
	bpl new
q4	cmp #$40
	bcs nins

	adc poddzw,x
	sta adcdzw,x
	tya
	sta ptrwsk,x
	lda adrinh,x
	beq qret
	sta ad+1
	lda adrinl,x
	sta ad
	ldy #$20
	lda (ad),y
	and #$0f
	sta p1lsb,x
	lda (ad),y
	.rept 4
	lsr a
	.next
	and #7
	tay
	lda typy,y
	sta branch,x
	ldy #$21
	lda (ad),y
	asl a
	asl a
	sta tp
	and #$3f
	sta p2lic,x
	eor tp
	sta frqwsk,x
	iny
	lda (ad),y
	sta p3lic,x
	lda #0
	sta slup,x
	sta p1lic,x
	sta p1pom,x
	lda adcdzw,x
;	(nczest)
	sta numdzw,x
	and #$3f
	ora frqwsk,x
	tay
	lda msx+$c0,y
	sta freq,x
qret	jmp r3

akce
	.byte a1-ak,a0-ak,a2-ak
	.byte a4-ak,a5-ak,a6-ak,a8-ak
typy
	.byte s0-so,s1-so,s2-so,s3-so
	.byte s4-so,s5-so,s6-so,s7-so
ndziel	.byte $40,0,$20,0
filtry	.byte 4,2,0,0

bsfrql = *-1
	.byte $f2,$33,$96
	.byte $e2,$38,$8c,0
	.byte $6a,$e8,$6a,$ef
	.byte $80,8,$ae,$46
	.byte $e6,$95,$41,$f6
	.byte $b0,$6e,$30,$f6
	.byte $bb,$84,$52,$22
	.byte $f4,$c8,$a0,$7a
	.byte $55,$34,$14,$f5
	.byte $d8,$bd,$a4,$8d
	.byte $77,$60,$4e,$38
	.byte $27,$15,6,$f7
	.byte $e8,$db,$cf,$c3
	.byte $b8,$ac,$a2,$9a
	.byte $90,$88,$7f,$78
	.byte $70,$6a,$64,$5e

bsfrqh = *-1
	.byte $d,$d,$c,$b,$b,$a,$a,9
	.byte 8,8,7,7,7,6,6,5,5,5,4,4,4,4
	.byte 3,3,3,3,3,2,2,2,2,2,2,2
	.byte 1,1,1,1,1,1,1,1,1,1,1,1
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

branch	.dword 0
volume	.dword 0
adcvol	.dword 0
frqwsk	.dword 0
adcdzw	.dword 0
poddzw	.dword 0
adrinl	.dword 0
adrinh	.dword 0
numdzw	.dword 0
numptr	.dword 0
ptrwsk	.dword 0
ilespc	.dword 0
licspc	.dword 0
p1lsb	.dword 0
p1lic	.dword 0
p1pom	.dword 0
p2lic	.dword 0
p3lic	.dword 0
zegar	.byte 1
