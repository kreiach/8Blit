 ; S04E01 Score - Two Player

; Demonstrates how to display two two-digit scores using the split playfield.
; This example makes use of a digit data table to store the patterns, 
; multiplication, masking, and pushing/pulling to/from the stack

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
VOUTLINES        = 177
SOUTLINES        = 5            
VBLANKLINES      = 37 
OVERSCANLINES    = 30
VBLANKTIME       = (VBLANKLINES * 76) / 64 
OVERSCANTIME     = (OVERSCANLINES * 76) / 64 

	seg.u vars          ;        uninitialized segment
	org	$80             ;        origin set at base of ram 

score           ds 2    ;        player score's

digitIdx1       ds 2    ;        index for digits to use within the data table
digitIdx2       ds 2    ;        index for digits to use within the data table
temp1           ds 1    ;        general temp address to swap out values
temp2           ds 1    ;        general temp address to swap out values
voutCount       ds 1    ;        number of cycles left for vout
soutCount       ds 1    ;        number of cycles left for sount (the score)
counter         ds 1

; code
;--------------------------------------
	seg	code    	        
	org $f000

reset:			
	CLEAN_START	        ;        ouput: all ram/registers 0

	lda #$00            ; 2
	sta score           ; 3      p0 score  
	sta score+1         ; 3      p1 score          
	sta counter         ; 3      counts down to next score increase

nextFrame:
	dec counter         ; 5                
	bpl noInc           ; 2/3    should we update the score
	lda #$10            ; 2      update every 1/6th second on NTSC
	sta counter         ; 3
	inc score           ; 5      increase p0 score
	inc score+1         ; 5      increase p1 score by 2
	inc score+1         ; 5

noInc:
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
	; we're only using the first nibble of the score. if the score is '17',
	; then we pull '7' by masking the the first 4 bits (d0-d3). multiply that
	; by the height of the digits (5) to find the offset position of the '7'
	; digit. multiplication by 5 is done by multiplying it by 2 twice and then
	; adding the original value to the result. 7*2*2+7=35

	ldy #$1             ; 2      start with p1 score
findIdx:
	lda score,y         ; 2      get the score   
	clc                 ; 2      clear the carry bit so it's not added in adc 
	pha                 ; 3      push the score to the stack 
	and #$0f            ; 2      mask the first nibble 
	sta temp1           ; 3      store the first nibble in temp
	asl                 ; 2      shift left (multiply by 2)
	asl                 ; 2      shift left (multiply by 2)
	adc temp1           ; 2      add the first nibble to the result 
	sta digitIdx1,y     ; 3      store calculated index
	pla                 ; 4      pull original score from stack
	and #$f0            ; 2      mask the second nibble
	lsr                 ; 2      shift right (divide by 2)
	lsr                 ; 2      shift right (divide by 2)
	sta temp1           ; 3      store the result in temp
	lsr                 ; 2      shift right (divide by 2)
	lsr                 ; 2      shift right (divide by 2)
	adc temp1           ; 2      add previous result in temp to get the offset
	sta digitIdx2,y     ; 3      store index @ address digitIdx+1
	dey                 ; 2      move on to p0 score
	bpl findIdx

vbTimer:
	lda INTIM           ; 2                  
	bne vbTimer         ; 2/3   
	sta VBLANK	        ; 3      set vertical blank off
   
	sta WSYNC           ; 3    
;--------------------------------------	

	; get graphic from data table by index
	;-------------------------------------
	; the digit graphics are stored as doubles, but we only want to display a
	; single digit so we mask off the first nibble before writing it to the 
	; playfield

voutscore:
 
	ldx digitIdx1       ; 3      get the index of the 1's position for p0
	lda digits,x        ; 4      load the digit graphic for this scanline     
	and #$0f            ; 2      mask off first nibble so only see one number
	sta temp1           ; 3      store in temp to combine later
	ldx digitIdx2       ; 3      get the index of the 10's position for p0
	lda digits,x        ; 4      load the digit graphic for this scanline
	and #$f0            ; 2      mask off second nibble so only see one number
	ora temp1           ; 3      'or' it with the 1's graphic we saved earlier
	sta WSYNC           ; 3/2    end scanline
;--------------------------------------

	sta PF1             ; 3    3 draw the the p0 score
	sta temp1           ; 3      save p0 graphic for the next scanline
	ldx digitIdx1+1     ; 3      get the index of the 1's position for p1
	lda digits,x        ; 4      load the digit graphic for this scanline     
	and #$0f            ; 2      mask off first nibble so only see one number
	sta temp2           ; 3      ..
	ldx digitIdx2+1     ; 3
	lda digits,x        ; 4
	and #$f0            ; 2
	ora temp2           ; 3
	nop                 ; 2      we need to be past cycle 38 to rewrite pf1
	nop                 ; 2
	nop                 ; 2
	sta PF1             ; 3   39           
	sta temp2           ; 3      save p1 graphic for the next scanline
	sta WSYNC           ; 3
;--------------------------------------	        
	inc digitIdx1       ; 5      increase the offset for the p0 1's digit
	inc digitIdx1+1     ; 5      increase the offset for the p1 1's digit
                
	lda temp1           ; 3      get previous saved p0 graphic
	sta PF1             ; 3   16 write to pf1
	inc digitIdx2       ; 5      increase the offset for the p0 10's digit
	inc digitIdx2+1     ; 5      increase the offset for the p1 10's digit
	lda temp2           ; 3      get the previous saved p1 graphic
	nop                 ; 2      we need to be past cycle 38 to rewrite pf1
	nop                 ; 2
	nop                 ; 2
	nop                 ; 2
	sta PF1             ; 3   40 write to pf1
        
contScore:
	dec soutCount       ; 5      counting down 5 cycles at 2 scanlines per
	bne voutscore       ; 2/3         

	sta WSYNC           ; 3
;--------------------------------------
	lda #$0             ; 2
	sta PF1             ; 3

	sta WSYNC           ; 3
;--------------------------------------

	lda #$0             ; 2
	sta PF1             ; 3

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

	sta WSYNC           ;  3
;--------------------------------------
	lda #$00            ;  2
	sta COLUBK          ;  3

; ---- overscan (30 scanlines)
	ldx #OVERSCANTIME   ;  2
	stx TIM64T          ;  3
osTimer 
	lda INTIM           ;  2
	bne osTimer         ;  2/3
	jmp nextFrame       ;  3         

	align $100          ; align data

	include "digits.h"

	org $fffa
	.word reset         ; nmi ($fffa)
	.word reset         ; reset ($fffc)
	.word reset         ; irq ($fffe)









	