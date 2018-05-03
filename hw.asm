; a8 hardware registers

; CTIA/GTIA
; read
rM0PF   = $d000 ; missile-playfield colls
rM1PF   = $d001
rM2PF   = $d002
rM3PF   = $d003
rP0PF   = $d004 ; player-playfield colls
rP1PF   = $d005
rP2PF   = $d006
rP3PF   = $d007
rM0PL   = $d008 ; missile-player colls
rM1PL   = $d009
rM2PL   = $d00a
rM3PL   = $d00b
rP0PL   = $d00c ; player-player colls
rP1PL   = $d00d
rP2PL   = $d00e
rP3PL   = $d00f
rTRIG0  = $d010 ; joystick trigger buttons
rTRIG1  = $d011
rTRIG2  = $d012
rTRIG3  = $d013
rPAL    = $d014 ; PAL/NTSC
; write
rHPOSP0 = $d000 ; player hpos
rHPOSP1 = $d001
rHPOSP2 = $d002
rHPOSP3 = $d003
rHPOSM0 = $d004 ; missile hpos
rHPOSM1 = $d005
rHPOSM2 = $d006
rHPOSM3 = $d007
rSIZEP0 = $d008 ; player size
rSIZEP1 = $d009
rSIZEP2 = $d00a
rSIZEP3 = $d00b
rSIZEM  = $d00c ; missile size
rGRAFP0 = $d00d ; player graphics
rGRAFP1 = $d00e
rGRAFP2 = $d00f
rGRAFP3 = $d010
rGRAFM  = $d011 ; missile graphics
rCOLPM0 = $d012 ; player+missile colors
rCOLPM1 = $d013
rCOLPM2 = $d014
rCOLPM3 = $d015
rCOLPF0 = $d016 ; playfield colors
rCOLPF1 = $d017
rCOLPF2 = $d018
rCOLPF3 = $d019
rCOLBK  = $d01a ; background color
rPRIOR  = $d01b ; player-playfield priority
rVDELAY = $d01c ; vertical delay
rGRACTL = $d01d ; graphic control
rHITCLR = $d01e ; collision clear
; read/write
rCONSOL = $d01f ; console switch port

; POKEY
; read
rPOT0   = $d200 ; potentiometer values
rPOT1   = $d201
rPOT2   = $d202
rPOT3   = $d203
rPOT4   = $d204
rPOT5   = $d205
rPOT6   = $d206
rPOT7   = $d207
rALLPOT = $d208 ; potentiometer port state
rKBCODE = $d209 ; keyboard code
rRANDOM = $d20a ; rng
rSERIN  = $d20d ; serial in
rIRQST  = $d20e ; IRQ status
rSKSTAT = $d20f ; serial port 4 key status
; write
rAUDF1  = $d200 ; ch1 frequency
rAUDC1  = $d201 ; ch1 control
rAUDF2  = $d202 ; ch2 frequency
rAUDC2  = $d203 ; ch2 control
rAUDF3  = $d204 ; ch3 frequency
rAUDC3  = $d205 ; ch3 control
rAUDF4  = $d206 ; ch4 frequency
rAUDC4  = $d207 ; ch4 control
rAUDCTL = $d208 ; audio control
rSTIMER = $d209 ; start timer
rSKRES  = $d20a ; reset skstat
rPOTGO  = $d20b ; start pot scan sequence
rSEROUT = $d20c ; serial out
rIRQEN  = $d20e ; IRQ enable
rSKCTL  = $d20f ; serial port 4 key control

; PIA
; read/write
rPORTA  = $d300 ; port a data/direction
rPORTB  = $d301 ; port b data/direction (memory/led control in XL/XE)
rPACTL  = $d302 ; port a control
rPBCTL  = $d303 ; port b control (unused in XL/XE)

; ANTIC
; read
rVCOUNT = $d40b ; vertical line counter
rPENH   = $d40c ; light pen x
rPENV   = $d40d ; light pen y
rNMIST  = $d40f ; NMI status
; write
rDMACTL = $d400 ; DMA control
rCHACTL = $d401 ; character control
rDLISTL = $d402 ; display list address
rDLISTH = $d403
rHSCROL = $d404 ; scroll x
rVSCROL = $d405 ; scroll y
rPMBASE = $d407 ; player/missile gfx address
rCHBASE = $d409 ; character gfx address
rWSYNC  = $d40a ; wait for hblank
rNMIEN  = $d40e ; NMI enable
rNMIRES = $d40f ; NMI reset

; 6502 interrupt vectors
rNMI    = $fffa ; NMI vector
rRESET  = $fffc ; reset vector
rIRQ    = $fffe ; IRQ vector
