; S04E01 Score - Two Digits
                                    
; Demonstrates how to display two digits using the playfield commonly used for
; showing the score in a game. This example makes use of a digit data table to
; store the patterns, TIA playfield timing, multiplication, division, masking,
; and pushing/pulling to/from the stack
                                    
; This Episode on Youtube - https://www.youtube.com/watch?v=lUJmDX1fd18

; Become a Patron - https://patreon.com/8blit
; 8blit Merch - https://8blit.myspreadshop.com/
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; Follow on Facebook - https://www.facebook.com/8Blit
; Follow on Instagram - https://www.instagram.com/8blit
; Visit the Website - https://www.8blit.com 
                                    
; Email - 8blit0@gmail.com

	processor 6502
                                    
	include "vcs.h"
	include "macro.h"								
                                    
; compiler symbols
;--------------------------------------
VOUTLINES       = 175
SOUTLINES       = 15            
VBLANKLINES     = 37 
OVERSCANLINES   = 30
VBLANKTIME      = (VBLANKLINES * 76) / 64 
OVERSCANTIME    = (OVERSCANLINES * 76) / 64 

	seg.u vars          ;        uninitialized segment
	org $80             ;        origin set at base of ram 

score           ds 1    ;        value to display
digitIdx        ds 2    ;        index for each digit within the data table
temp            ds 1    ;        general temp address to swap out values
voutCount       ds 1    ;        number of cycles left for vout
soutCount       ds 1    ;        number of cycles left for sount (the score)

; code
;--------------------------------------
	seg code    	        
	org $f000

reset:			
	CLEAN_START         ;        ouput: all ram/registers 0

	lda #$3C            ; 2      the score we want to display
	sta score           ; 3            

nextFrame:
	VERTICAL_SYNC       ;10
	ldx #VBLANKTIME     ; 2                    
	stx TIM64T          ; 3        
	lda #VOUTLINES      ; 2    
	sta voutCount       ; 3    
	lda #SOUTLINES      ; 2    
	sta soutCount       ; 3    
	lda #$0e            ; 2    
	sta COLUPF          ; 3    

	; calculate digit index for the score
	;----------------------------------
	; we're only using the first nibble of the score. if the score is '37', 
	; then we pull '7' by masking the the first 4 bits (d0-d3). multiply that
	; by the height of the digits (5) to find the offset position of the '7'
	; digit. multiplication by 5 is done by multiplying it by 2 twice and then
	; adding the original value to the result. 7*2*2+7=35. the second 4 bits is
	; handled in a similiar manner, except we shift it into the first nibble.
	; this is essentually the same as as SpiceWares blog entry on the AtariAge
	; website. 
	; https://forums.atariage.com/blogs/entry/11118-step-3-score-timer-display/

	lda score           ; 2      get the score   
	clc                 ; 2      clear the carry bit so it's not added in adc 
	pha                 ; 3      push the score to the stack 
	and #$0f            ; 2      mask the first nibble 
	sta temp            ; 3      store the first nibble in temp
	asl                 ; 2      shift left (multiply by 2)
	asl                 ; 2      shift left (multiply by 2)
	adc temp            ; 2      add the first nibble to the result 
	sta digitIdx        ; 3      store calculated index
	pla                 ; 4      pull original score from stack
	and #$f0            ; 2      mask the second nibble
	lsr                 ; 2      shift right (divide by 2)
	lsr                 ; 2      shift right (divide by 2)
	sta temp            ; 3      store calculated index
	lsr                 ; 2      shift right (divide by 2)
	lsr                 ; 2      shift right (divide by 2)
	adc temp            ; 2      add 
	sta digitIdx+1      ; 3      store the index in the address digitIdx+1  

vbTimer:
	lda INTIM           ; 2                   
	bne vbTimer         ; 2/3   
	sta VBLANK          ; 3      set vertical blank off

	ldy #$3             ; 2        
	sta WSYNC           ; 3    
;--------------------------------------

	; get graphic from data table by index
	;----------------------------------
	; the digit graphics are stored as doubles, but we only want to display a 
	; single digit so we mask off the first nibble before writing it to the
	; playfield

voutscore:
	ldx digitIdx        ; 2
	lda digits,x        ; 2      load the digit graphic for this scanline     
	and #$0f            ; 2      mask off first nibble so only see one number
	sta temp            ; 3
	ldx digitIdx+1      ; 2
	lda digits,x        ; 2
	and #$f0            ; 2
	ora temp            ; 2
	ldx #$0             ; 2      around time PF1 1st shown, clr before 2nd 
	stx PF1             ; 3
	dey                 ; 2
	sta WSYNC           ; 3
;--------------------------------------
	bne cont            ; 2/3
	ldy #3              ; 2
	inc digitIdx        ; 2      inc digit offset to get next line of graphic
	inc digitIdx+1      ; 2
cont:
	sta PF1             ; 3      write the digit graphic to the playfield
	dec soutCount       ; 5
	bne voutscore       ; 2/3         

	SLEEP 20            ;20      we need some padding before clearing PF1         

	lda #$0             ; 2
	sta PF1             ; 3      clear PF1  

	sta WSYNC           ; 3
;--------------------------------------
	sta WSYNC           ; 3
;--------------------------------------
	sta WSYNC           ; 3
;--------------------------------------
	lda #$90            ; 2
	sta COLUBK          ; 3
vout:    
	sta WSYNC           ; 3
;--------------------------------------
	dec voutCount       ; 5
	bne vout            ; 2/3       

 	sta WSYNC           ; 3
;--------------------------------------
	lda #$00            ; 2
	sta COLUBK          ; 3

; ---- overscan (30 scanlines)
	ldx #OVERSCANTIME   ; 2
	stx TIM64T          ; 3
osTimer 
	lda INTIM           ; 2
	bne osTimer         ; 2/3
	jmp nextFrame       ; 3         

	align $100          ; align data
        
	include "digits.h"

	org $fffa
	.word reset         ; nmi ($fffa)
	.word reset         ; reset ($fffc)
	.word reset         ; irq ($fffe)








	