; s01e03 Changing the background color
; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
; Registers to draw playfield graphics using one register at a time
; first in normal mode, and then in mirrored

; This Episode on Youtube - https://youtu.be/nKhgqCp8wNk

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

	processor 6502
	include	 "vcs.h"

	seg
	org $f000

reset:
	; Clear RAM and all TIA registers
	ldx #0
	lda #0
clear:
	sta 0,x
	inx                      ;              increase the value in (x)
	bne clear                ;              branch to clear if result not zero

startOfFrame
; start of new frame
; start of vertical blank processing
	lda #0
	sta VBLANK               ;              turn off vblank
	lda #2                   ;              turn on vsync for three scanlines
	sta VSYNC
	sta WSYNC
;---------------------------------------	
	sta WSYNC
;---------------------------------------	
	sta WSYNC
;---------------------------------------	
	lda #0
	sta VSYNC                ;              turn off vsync

	; 37 scanlines of vertical blank.
	ldx #0
verticalBlank
	sta WSYNC
;---------------------------------------
	inx                      ;              increase the value in (x)
	cpx #37                  ;              compare (x) to the immediate value 37
	bne verticalBlank        ;              branch up to verticalBlank if result not zero

	; here is our main kernel where we'll draw 192 scanlines
	ldx #0
drawField:

	; This will draw the background using the value of the current scanline
	stx COLUBK               ;              set the background color
	sta WSYNC
;---------------------------------------
	inx                      ;              increase the value in (x)
	cpx #192                 ;              compare (x) to the immediate value 192
	bne drawField            ;              branch up to drawField if result not zero

	; end of screen - enter blanking
    lda #%00000010           ;              turn on vblank with d2
    sta VBLANK

	; 30 scanlines of overscan
	ldx #0
overscan        
	sta WSYNC
;---------------------------------------	
	inx                      ;              increase the value in (x)
	cpx #30                  ;              compare (x) to the immediate value 30
	bne overscan             ;              branch up to overscan if result not zero
	jmp startOfFrame         ;              branch up to startOfFrame
;------------------------------------------------

	ORG $FFFA
	
interruptVectors
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq

