; global variables, shared across all parts of demo

	.include "charmap.asm"
	.include "hw.asm"
	.include "macros.asm"
	
; zeropage
*	= $dc
GVarsZPBegin = *

; interrupt temp storage
irqA .byte ?
irqX .byte ?
irqY .byte ?
nmiA .byte ?
nmiX .byte ?
nmiY .byte ?

; zNTSCcnt   .byte ? ; -1 = PAL, 0-5 = NTSC
zCurMsxOrd .byte ? ; current music order
zCurMsxRow .byte ? ; current music row

; $e4 - $ef are used by mpt player

*	= $f0
zARG0 .word ?
zARG1 .word ?
zARG2 .word ?
zARG3 .word ?
zTMP0 .byte ?
zTMP1 .byte ?
zTMP2 .byte ?
zTMP3 .byte ?
zTMP4 .byte ?
zTMP5 .byte ?
zTMP6 .byte ?
zTMP7 .byte ?

NUM_PARTS = 1 ; number of demo parts, not including part 0

; global addresses, sorted from lowest to highest, do not modify the order
decompress  = $700 ; pointer to lz decompressor routine
deDED       = $8ed ; pointer to ded decoder routine
runDemo     = $a10 ; pointer to part loader and music
updateMusic = runDemo + 3 ; pointer to music update routine
compressedPartAddresses = partEntry-(NUM_PARTS*2) ; pointer to compressed part address table
partEntry   = $2000 ; every demo parts (except part 0) get decompressed here and jumped to
xexStart    = partEntry ; entry point of this demo executable

; math tables
QSTableLo  = $f800 ; 1024 bytes, for multiplication
QSTableHi  = $fa00
SineTable  = $fc00 ; 256 bytes
