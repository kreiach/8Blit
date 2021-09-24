	processor 6502

	include "vcs.h"
	include "macro.h"

;------------------------------------------------------------------------------
	SEG
	ORG $F000
	
Reset
; Clear RAM and all TIA registers
	ldx #0 
	lda #0 
Clear           
	sta 0,x 
	inx 
	bne Clear

;------------------------------------------------

StartOfFrame
; Start of new frame
; Start of vertical blank processing
	lda #0
	sta VBLANK
	lda #2
	sta VSYNC
	sta WSYNC
	sta WSYNC
	sta WSYNC               ; 3 scanlines of VSYNC signal
	lda #0
	sta VSYNC
;------------------------------------------------
; 37 scanlines of vertical blank. . .
	ldx #0
VerticalBlank   
	sta WSYNC
	inx
	cpx #37
	bne VerticalBlank
;------------------------------------------------
;192 lines of drawfield
    ldx #0
DrawField:

        ;This will draw the background using the value of the current scanline

	stx COLUBK

	sta WSYNC

        inx
	cpx #192
	bne DrawField
;------------------------------------------------
; end of screen - enter blanking
    lda #%01000010
    sta VBLANK          
;------------------------------------------------
; 30 scanlines of overscan. . .
	ldx #0
Overscan        
	sta WSYNC
	inx
	cpx #30
	bne Overscan
	jmp StartOfFrame
;------------------------------------------------

	ORG $FFFA
	
InterruptVectors
	.word Reset          ; NMI
	.word Reset          ; RESET
	.word Reset          ; IRQ

