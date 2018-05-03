; global variables, shared across all parts of demo

	.include "charmap.asm"
	.include "hw.asm"
	.include "macros.asm"
	
; zeropage
*	= $e1
zNTSCcnt   .byte ? ; -1 = PAL, 0-5 = NTSC
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
decompress  = $700 ; pointer to decompressor routine
runDemo     = $900 ; pointer to part loader and music
updateMusic = runDemo + 3 ; pointer to music update routine
compressedPartAddresses = partEntry-(NUM_PARTS*2) ; pointer to compressed part address table
partEntry   = $2000 ; every demo parts (except part 0) get decompressed here and jumped to
xexStart    = partEntry ; entry point of this demo executable

