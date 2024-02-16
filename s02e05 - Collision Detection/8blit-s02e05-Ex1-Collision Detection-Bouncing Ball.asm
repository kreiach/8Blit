        processor 6502          ; s02e05 Ex. 1 Collision Detection - Bouncing Ball
                                ;
        include	 "vcs.h"	; this example uses the bounce/reflect method used in the game COMBAT
        include  "macro.h"	;  
                                ;
                                ; This Episode on Youtube - https://youtu.be/fi5n4tPL1PI
                                ;
								; Become a Patron - https://patreon.com/8blit
								; 8blit Merch - https://8blit.myspreadshop.com/
								; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
								; Follow on Facebook - https://www.facebook.com/8Blit
								; Follow on Instagram - https://www.instagram.com/8blit
								; Visit the Website - https://www.8blit.com 
                   	            ;
                       	        ; Email - 8blit0@gmail.com

; define constants
PF_H            equ #96         ; 2LK playfield height (in segments)
                                ; we're using a 2LK just as a simple way to have a larger ball
                                ; nothing else to worry about so it's low impact. 
                                ; just adjust PF_H accordingly

        seg.u	vars		; uninitialized segment
        org	$80             ; origin set at base of ram

b_x             ds 1            ; ball x pos
b_y		ds 1	 	; ball y pos

b_bearing       ds 1            ; (0-15) 16 angles 22.5 deg apart
b_bearing_old   ds 1            ; holds the original bearing (direction) of the ball before bounce

collision_count ds 1            ; collision count
pf_count        ds 1            ; playfield index


        seg	main    	; start of main segment
        org $F000

Reset:			
        CLEAN_START		; ouput: all ram/registers 0

        ; set area values
        lda #%00010101          ; playfield to reflect (default behavior, not nessesary)
        sta CTRLPF      
        lda #$AC                ; baby blue playfield
        sta COLUPF       
        lda #$A0                ; dark blue background
        sta COLUBK      

        ; set initial ball position
        lda #81		    
        sta b_y	                ; y pos
        sta b_x                 ; x pos
        ldx #4		        ; ball object
        jsr PositionX	        ; uses x register as graphic object index from P0 address        
        sta WSYNC           
        sta HMOVE	        ; strobe horizontal move to set fine positions

        ; set initial bearing (direction)
        lda #$09                ; index from bearing_offsets address
        sta b_bearing   

NextFrame:
	VERTICAL_SYNC	        ; output: a = 0; 3 scanlines

VerticalBlank               
        ldx #43                 ; 37sl * 76mc = 2812 
        stx TIM64T              ; set 64-clock for 43 intervals. 43 * 64mc = 2752mc before timer ends

        ; collision detection
        lda CXBLPF              ; ball collision with playfield?
        bmi collision
        
        lda #0                  ; no collision, set collision count to 0
        sta collision_count
        jmp no_collision        ; bypass collision handling

; when a collision occures we try to reflect to a vertical bearing. If on the next frame we're still
; registering a collision then we try a horizontal bearing. If it's STILL registering a collision 
; then we reflect it back 180 degrees from the original pre-bounce bearing.

collision:
        ; a collision occured
        lda collision_count     ; how many times has a collision occured consecutively
        bne col_on              ; branch if collisions are already ongoing

        lda b_bearing           ; get the current bearing
        sta b_bearing_old       ; store current missile b_bearing
        eor #$FF                ; reverse our bearings 
        sta b_bearing          
        inc b_bearing           ; additive reverse
        lda b_bearing
        and #$03                ; is bearing N,S,E,W?
        bne col_no_adj
        inc b_bearing           ; increment bearing by one offset to prevent continuous reflection

col_no_adj: 
        jmp collision_done

col_on: cmp #$01                ; check collision_count
	beq reverse_bearing     ; first collision in series
	cmp #$03                ; check collision_count
	bcc collision_done      ; second/third collision in series
	bne collision_done      ; more than three collisions in series
	lda b_bearing_old       ; retrieve pre-bounce bearing
	jmp reverse_org_bearing ; reverse bearing it 180 degrees

reverse_bearing:                ; reverse altered bearing
        lda b_bearing           
reverse_org_bearing:            ; reverse original bearing
        clc                     ; clear carry so it's not included in add on next instruction
	adc #$08                ; reverse bearing by 180 degrees
	sta b_bearing

collision_done:
        inc collision_count     ; increment the number of consecutive collisions
no_collision:

        ; move the ball
        lda b_bearing     
        and #$0F                ; strip the high nibble
        tay
        lda bearing_offsets,y   ; load the x/y offsets based on the current bearing

        sta HMBL                ; update the balls horizontal motion register which will only
                                ; use the high nibble where the x offset is stored.
        and #$0F                ; strip out the high nibble which leaves only the y offset
        sec                     ; set the carry flag
        sbc #$08                ; subtract 8 for 4bit 2's completment +/-
        clc                     ; clear carry flag so it's not used in the following add
        adc b_y                 ; add y offset to current y position
        sta b_y                 ; store the new y position

        ldx #255
        ldy #PF_H
        sty pf_count

checktimer:
        lda INTIM               ; time remaining (or past)
        bne checktimer          ; burn remaining cycles

        lda #0	                ; D1 to 0 to end VBLANK
        sta WSYNC
;--------------------------------------		
        sta VBLANK	        ; 3   3 - set vertical blank off
        sta CXCLR
        sta HMOVE

kernel:    
        lda pf_count;           ; 2   2 
        and #%011               ; 2   4 - binary 3 (4th interation)
        bne skipx               ; 3   7 
        inx                     ; 2   9 
skipx:     

        lda PF0_data,x          ; 2  11 
        sta WSYNC
;--------------------------------------	 
      
        ; draw playfield
        sta PF0                 ; 3  3
        lda PF1_data,x          ; 2  5
        sta PF1                 ; 3  8
        lda PF2_data,x          ; 2  10
        sta PF2                 ; 3  13

        ldy #0                  ; 2  15 - used to disable ball graphic
        lda b_y                 ; 2  17 - load ball y pos
        cmp pf_count            ; 2  19 - compare y pos to playfield counter
        bne noball              ; 3  22 - if it's not the same then continue with disabled ball graphic
        ldy #2                  ; 2  24 - ball y pos and playfield counter are same so enable ball graphic

noball:       
        sty ENABL               ; 3  37 - enable/disable ball graphic

        sta WSYNC

        dec pf_count            ; 5  39
        bne kernel              ; 3  42
        
        ; end of kernel
        sta WSYNC               ; end kernel with a clean scan line
        lda #$0
        sta PF0
        sta PF1
        sta PF2
        sta ENABL
        lda #$2     	        ; set D1 = 1 to initiate VBLANK
        sta VBLANK		; turn off the beam


; ---- Overscan (30 scanlines)
        ldx #35                 ; We'll round down, and clean up the remaining cycles with a WSYNC
        stx TIM64T              ; Set a count of 35 with 64-clock interval

        ; timer2 -----------
timer2          
        ldx INTIM
        bne timer2

        jmp NextFrame           ; (3) jump back up to start the next frame


; -----------------------------------------------------------------------------
; PositionX
; A - Horizontal position of the object
; X - Object to position
;   0 - Player 0
;   1 - Player 1
;   2 - Missile 0
;   3 - Missile 1
;   4 - Ball
; -----------------------------------------------------------------------------

PositionX:          
        sec	                ;  2 +2 - set the carry flag
        sta WSYNC	        ;  3 +5 - start a new line
DivideLoop
        sbc #15		        ;  2  2 - subtract 15
	bcs DivideLoop	        ;  2  4 - branch until negative
	eor #7		        ;  2  6 - calculate fine offset
	asl                     ;  2  8 - shift left
	asl                     ;  2 10
	asl                     ;  2 12
	asl                     ;  2 14
	sta HMP0,x	        ;  5 19 - set fine offset
	sta RESP0,x	        ;  4 23 - set coarse position
	rts		        ;  6 29 - return

        align $100              ; align data

bearing_offsets
                                ;index  x-move  y-move          deg     direction  
                                ;------------------------------------------                                                                                            
      	.byte #%11101000        ; 0     -2      (8-8)   0       90      right
        .byte #%11100111        ; 1     -2      (7-8)  -1       112.5
        .byte #%11100110        ; 2     -2      (6-8)  -2       135
        .byte #%11110110        ; 3     -1      (6-8)  -2       157.5
      	.byte #%00000110        ; 4      0      (6-8)  -2       180     down
        .byte #%00010110        ; 5     +1      (6-8)  -2       202.5 
        .byte #%00100110        ; 6     +2      (6-8)  -2       225   
        .byte #%00100111        ; 7     +2      (7-8)  -1       247.5   
      	.byte #%00101000        ; 8     +2      (8-8)   0       270     left
        .byte #%00101001        ; 9     +2      (9-8)  +1       292.5 
        .byte #%00101010        ; 10    +2      (10-8) +2       315   
        .byte #%00011010        ; 11    +1      (10-8) +2       337.5 
      	.byte #%00001010        ; 12     0      (10-8) +2       0/360   up
        .byte #%11111010        ; 13    -1      (10-8) +2       22.5
        .byte #%11101010        ; 14    -2      (10-8) +2       45
        .byte #%11101001        ; 15    -2      (9-8)  +1       67.5

; we're going with a 4 scanline playfield loading data from the bottom up
PF0_data
        .byte #%11110000 ;<- first
        .byte #%00110000 
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%11110000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00110000
        .byte #%11110000 ;<- last

PF1_data
        .byte #%11111111 ;<- first
        .byte #%00000000 
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00001111
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11110000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11111111 ;<- last

PF2_data
        .byte #%11111111 ;<- first
        .byte #%00000000 
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00001111
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11110000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11111111 ;<- last

        org 	$FFFA

        .word Reset     	; NMI  ($FFFA)
        .word Reset     	; RESET ($FFFC)
        .word Reset     	; IRQ ($FFFE)

