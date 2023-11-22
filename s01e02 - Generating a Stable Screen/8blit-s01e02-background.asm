; S01E02 Generating a stable screen

; This example creates the proper VSYNC, and number of scanlines to generate a stable frame on NTSC televisions.

; This Episode on Youtube - https://youtu.be/WcRtIpvjKNI

; Become a Patron - https://patreon.com/8blit
; Subscribe to 8Blit - https://www.youtube.com/8blit
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Tweet on Twitter - https://twitter.com/8blit0
; Visit the Website - https://www.8blit.com 

; Email - 8blit0@gmail.com

	processor 6502
	include	 "vcs.h"

BLUE            = $9a                   ; define a symbol to represent a TIA color value (NTSC)
	
	seg
	org $f000
	
reset:
; clear RAM and all TIA registers
	ldx #0                              ; load the value 0 into (x)
	lda #0                              ; load the value 0 into (a)
clear:                                  ; define a label 
	sta 0,x                             ; store the value in (a) into the address of 0 at offset (x)
	inx                                 ; increase (x) by 1. it will count up to 255 and then rollover back to 0
	bne clear                           ; branch up to the 'clear' label if (x) != 0

	lda #BLUE                           ; load the value from the symbol 'blue' into (a)
	sta COLUBK                          ; store (a) into the TIA background color register

startFrame:
; start of new frame
; start of vertical blank processing
	lda #0                              ; load the value 0 into (a)
	sta VBLANK                          ; store (a) into the TIA VBLANK register
	lda #2                              ; load the value 2 into (a). 
	sta VSYNC                           ; store (a) into the TIA VSYNC register to turn on vertical sync
	sta WSYNC                           ; write to the TIA WSYNC register to wait until horizontal sync (any value)
;---------------------------------------
	sta WSYNC
;---------------------------------------
	sta WSYNC                           ; we need 3 scanlines of VSYNC for a stable frame
;---------------------------------------
	lda #0
	sta VSYNC                           ; store 0 into the TIA VSUNC register to turn off vertical sync

; generate 37 scanlines of vertical blank
	ldx #0
verticalBlank:   
	sta WSYNC                           ; write to the TIA WSYNC register to wait until horizontal sync (any value)
;---------------------------------------	
	inx
	cpx #37                             ; compare the value in (x) to the immeadiate value of 37
	bne verticalBlank                   ; branch up to the 'verticalBlank' label the compare is not equal

; generate 192 lines of playfield
	ldx #0
playfield:
	sta WSYNC
;---------------------------------------
	inx
	cpx #192                            ; compare the value in (x) to the immeadiate value of 192
	bne playfield                       ; branch up to the 'drawField' label the compare is not equal

; end of playfield - turn on vertical blank
    lda #%01000010
    sta VBLANK          

; generate 30 scanlines of overscan
	ldx #0
overscan:        
	sta WSYNC
;---------------------------------------
	inx
	cpx #30                             ; compare the value in (x) to the immeadiate value of 30
	bne overscan                        ; branch up to the 'overscan' label the compare is not equal
	jmp startFrame                    ; frame is completed, branch back up to the 'startFrame' label
;------------------------------------------------

	org $fffa                           ; set origin to last 6 bytes of 4k rom
	
InterruptVectors:
	.word reset                         ; nmi
	.word reset                         ; reset
	.word reset                         ; irq

