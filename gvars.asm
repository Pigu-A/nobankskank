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

NUM_PARTS = 9 ; number of demo parts, not including part 0

; global addresses, sorted from lowest to highest, do not modify the order
decompress    = $700 ; pointer to lz decompressor routine
runDemo       = $900 ; pointer to part loader, music and global util functions
initQSTable   = runDemo + 3
disnmi        = runDemo + 6
loadSineTable = runDemo + 9
updateMusic   = runDemo + 12 ; must be the last

compressedPartAddresses = xexStart-(NUM_PARTS*4) ; pointer to compressed part address table
xexStart    = $2000 ; entry point of this demo executable, any parts can't have entry point before this
; entry point for each parts
partEntry   = $2000 ; common
partEntry_3 = $23a0
partEntry_7 = $2d00

; math tables
	.weak
SineTable  = $fc00 ; 256 bytes
	.endweak
