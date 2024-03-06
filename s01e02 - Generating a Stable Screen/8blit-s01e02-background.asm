; S01E02 Generating a stable screen

; This example creates the proper VSYNC, and number of scanlines to generate a stable frame on NTSC
; televisions.

; This Episode on Youtube - https://youtu.be/WcRtIpvjKNI

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

	processor 6502
	include "vcs.h"

BLUE           = $9a         ;              define symbol for TIA color (NTSC)

	seg
	org $f000

reset:
	; clear RAM and all TIA registers
	ldx #0                   ;              load the value 0 into (x)
	lda #0                   ;              load the value 0 into (a)
clear:                       ;              define a label 
	sta 0,x                  ;              store value in (a) at address of 0 with offset (x)
	inx                      ;              inc (x) by 1. it will count to 255 then rollover to 0
	bne clear                ;              branch up to the 'clear' label if (x) != 0

	lda #BLUE                ;              load the value from the symbol 'blue' into (a)
	sta COLUBK               ;              store (a) into the TIA background color register

startFrame:
	; start of new frame
	; start of vertical blank processing
	lda #0                   ;              load the value 0 into (a)
	sta VBLANK               ;              store (a) into the TIA VBLANK register
	lda #2                   ;              load the value 2 into (a). 
	sta VSYNC                ;              store (a) into TIA VSYNC register to turn on vsync
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
;---------------------------------------
	sta WSYNC
;---------------------------------------
	sta WSYNC                ;              we need 3 scanlines of VSYNC for a stable frame
;---------------------------------------
	lda #0
	sta VSYNC                ;              store 0 into TIA VSYNC register to turn off vsync

	; generate 37 scanlines of vertical blank
	ldx #0
verticalBlank:   
	sta WSYNC                ;              write any value to TIA WSYNC register to wait for hsync
;---------------------------------------
	inx
	cpx #37                  ;              compare the value in (x) to the immeadiate value of 37
	bne verticalBlank        ;              branch to 'verticalBlank' label if compare not equal

	; generate 192 lines of playfield
	ldx #0
playfield:
	sta WSYNC
;--------------------------------------
	inx
	cpx #192                 ;              compare the value in (x) to the immeadiate value of 192
	bne playfield            ;              branch to 'drawField' label if compare not equal

	; end of playfield - turn on vertical blank
    lda #%01000010
    sta VBLANK

	; generate 30 scanlines of overscan
	ldx #0
overscan:        
	sta WSYNC
;---------------------------------------
	inx
	cpx #30                  ;              compare value in (x) to immeadiate value of 30
	bne overscan             ;              branch up to 'overscan' label, compare if not equal
	jmp startFrame           ;              frame completed, branch up to the 'startFrame' label
;------------------------------------------------

	org $fffa                ;              set origin to last 6 bytes of 4k rom
	
interruptVectors:
	.word reset              ;              nmi
	.word reset              ;              reset
	.word reset              ;              irq

