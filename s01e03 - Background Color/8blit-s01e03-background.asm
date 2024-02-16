				processor 6502				; s01e03 Changing the background color
				include	 "vcs.h"			; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
											; Registers to draw playfield graphics using one register at a time
											; first in normal mode, and then in mirrored
	                                        ;
    	                                    ; This Episode on Youtube - https://youtu.be/nKhgqCp8wNk
        	                                ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                                	        ;
                                   		    ; Email - 8blit0@gmail.com

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

