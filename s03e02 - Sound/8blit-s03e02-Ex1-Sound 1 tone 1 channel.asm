        processor 6502          ; S03e02 Ex. 1 tone, 1 channel
                                ;
        include	 "vcs.h"	; Demonstrates basic audio generation by setting the audio registers to create 
        include  "macro.h"      ; a sound when the ball bounces. Turns volume off after a specified number 
                                ; of frames.
                                ;
                                ; This Episode on Youtube - https://youtu.be/NBE-rEzk4cs
                                ;
								; Become a Patron - https://patreon.com/8blit
								; 8blit Merch - https://8blit.myspreadshop.com/
								; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
								; Follow on Facebook - https://www.facebook.com/8Blit
								; Follow on Instagram - https://www.instagram.com/8blit
								; Visit the Website - https://www.8blit.com 
                   	            ;
                       	        ; Email - 8blit0@gmail.com

                                ;
                                ; F1 (Game Select) Change to next arena based on Right Difficulty Setting 
                                ; F7 (Right Difficulty A) Move forward in list
                                ; F8 (Right Difficulty B) Move backward in list
                                ; F2 (Reset) Randomly select an arena and ball direction
                                ;

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
pf_prev         ds 1
PF0_ptr         ds 2    
PF1_ptr         ds 2    
PF2_ptr         ds 2
PF_col_ptr      ds 2
PF_col          ds 1
r_seed          ds 1            ; random seed
l_seed          ds 1            ; list seed
mode            ds 1            ; 0 = randomize on reset, 1 = iterate through lfsr
swt_reset       ds 1            ; locking - 1 if reset was handled, until reset is released
swt_select      ds 1            ; locking - 1 if select was handled, until select is released

snd_on          ds 1            ; greater that 0 if sound is playing on channel 0


        seg	main    	; start of main segment
        org     $F000

reset:			
        CLEAN_START	        ; ouput: all ram/registers 0

        ; generate a random see from the interval timer
        lda INTIM               ; unknown value to use as an initial random seed
        sta r_seed              ; random seed
        sta l_seed              ; iterive seed

        ; set area values
        lda #%00010101          ; playfield to reflect (default behavior, not nessesary)
        sta CTRLPF   

soft_reset:

        lda #0
        sta mode                ; sets mode to randomize

        ; 'randomly' select an initial bearing (direction)
        jsr galois_lfsr_random  ; no need to store the seed for this one
        and #$0F                ; limit the value to 0-15
        sta b_bearing  

        ; set the starting position of the ball 
        lda #80		        
        sta b_y	                ; y pos
        sta b_x                 ; x pos
        ldx #4		        ; ball object
        jsr PositionX	        ; a = x pos, x = object (index from P0 object address)

        ; lock the graphic object positions
        sta WSYNC           
        sta HMOVE	        ; strobe horizontal move to set fine positions                

        ; 'randomly' select which arena to use, but not the previous
        jsr galois_lfsr_random
        and #%00000011          ; limit it to our 4 arena's
        cmp pf_prev
        beq soft_reset
        sta pf_prev

change_arena: 
        ldx pf_prev

        ; get the playfield for the area
        lda PF0_lsb_ptr,x 
        sta PF0_ptr       
        lda PF0_msb_ptr,x 
        sta PF0_ptr+1   
        lda PF1_lsb_ptr,x 
        sta PF1_ptr       
        lda PF1_msb_ptr,x 
        sta PF1_ptr+1   
        lda PF2_lsb_ptr,x 
        sta PF2_ptr           
        lda PF2_msb_ptr,x 
        sta PF2_ptr+1  

        ; get/set the pallet for the arena
        lda PF_col_lsb_ptr,x
        sta PF_col_ptr
        lda PF_col_msb_ptr,x
        sta PF_col_ptr+1
        
        ldy #0
        lda (PF_col_ptr),y    
        sta COLUPF 
        iny      
        lda (PF_col_ptr),y
        sta PF_col        

NextFrame:
	VERTICAL_SYNC	        ; output: a = 0; 3 scanlines

VerticalBlank               
        ldx #43                 ; 37sl * 76mc = 2812 
        stx TIM64T              ; set 64-clock for 43 intervals. 43 * 64mc = 2752mc before timer ends

        ; process sound
        lda snd_on             ; check is sound 0 is active
        beq snd                ; are we playing a sound? Yes
        dec snd_on
        bne snd
        lda #0
        sta AUDV0               ; since we know a = 0, use it to turn off the volume
snd:


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

        ; turn on our sound
        lda #$4                 ; distortion
        sta AUDC0               ; audio control (type of sound/which lfsr)
        sta AUDF0               ; audio frequency
        sta AUDV0               ; audio volume
        lda #$1                 ; frames to play sound (i.e. sound on)
        sta snd_on              

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
        tax
        lda bearing_offsets,x   ; load the x/y offsets based on the current bearing
        sta HMBL
                                ; update the balls horizontal motion register which will only
                                ; use the high nibble where the x offset is stored.
        and #$0F                ; strip out the high nibble which leaves only the y offset
        sec                     ; set the carry flag
        sbc #$08                ; subtract 8 for 4bit 2's completment +/-
        clc                     ; clear carry flag so it's not used in the following add
        adc b_y                 ; add y offset to current y position
        sta b_y                 ; store the new y position

        ldy #255
        ldx #PF_H
        stx pf_count

        sta WSYNC
;--------------------------------------	
        sta HMOVE
        sta CXCLR

checktimer:
        lda INTIM               ; time remaining (or past)
        bne checktimer          ; burn remaining cycles
        lda #0	                ; D1 to 0 to end VBLANK
        sta WSYNC
;--------------------------------------	
        sta VBLANK	        ; 3   3 - set vertical blank off

kernel:    
        lda pf_count;           ; 2   2 
        and #%011               ; 2   4 - binary 3 (4th interation)
        bne skipx               ; 3   7 
        iny                     ; 2   9 
skipx:     

        lda (PF0_ptr),y         ; 2  11 
        sta WSYNC
;--------------------------------------	 
      
        ; draw playfield
        sta PF0                 ; 3  3
        lda (PF1_ptr),y         ; 2  5
        sta PF1                 ; 3  8
        lda (PF2_ptr),y         ; 2  10
        sta PF2                 ; 3  13
        lda PF_col              ; 2  15
        sta COLUBK              ; 3  18

        ldx #0                  ; 2  20 - used to disable ball graphic
        lda b_y                 ; 2  22 - load ball y pos
        cmp pf_count            ; 2  24 - compare y pos to playfield counter
        bne noball              ; 3  26 - if it's not the same then continue with disabled ball graphic
        ldx #2                  ; 2  28- ball y pos and playfield counter are same so enable ball graphic

noball:       
        stx ENABL               ; 3  31 - enable/disable ball graphic
        sta WSYNC               ; 3  34

        dec pf_count            ; 5  39
        bne kernel              ; 3  42
        
        ; end of kernel
        sta WSYNC               ; end kernel with a clean scan line
        lda #$0
        sta PF0
        sta PF1
        sta PF2
        sta COLUBK
        sta ENABL
        lda #$2     	        ; set D1 = 1 to initiate VBLANK
        sta VBLANK		; turn off the beam


; ---- overscan (30 scanlines)
        ldx #35                 ; We'll round down, and clean up the remaining cycles with a WSYNC
        stx TIM64T              ; Set a count of 35 with 64-clock interval

; ---- check switches
        lda #%00000001          ; check reset switch
        bit SWCHB
        bne no_reset            ; jump of if reset is not pressed
        lda swt_reset           ; load the latching reset register
        bne skip_reset          ; if non-zero then we've already handled reset so jump
        inc swt_reset           ; if 0 then latch the register and handle reset

        jmp soft_reset          ; end frame prematurely and soft reset
no_reset:
        lda #0                  
        sta swt_reset           ; no reset pressed to unlatch the register 
skip_reset:

        lda #%00000010          ; check game select switch
        bit SWCHB
        bne no_select
        lda swt_select
        bne skip_select
        inc swt_select

        lda #1
        sta mode                ; mode is now interate lfsr

        ; which way to iterate the lfsr?
        lda #%10000000
        bit SWCHB
        bne int_advance
int_inv:        
        jsr galois_lfsr_backward
        and #%00000011          ; limit it to our 4 arena's
        cmp pf_prev
        beq int_inv
        sta pf_prev
        jmp change_arena
int_advance:
        jsr galois_lfsr_forward
        and #%00000011          ; limit it to our 4 arena's
        cmp pf_prev
        beq int_advance
        sta pf_prev
        jmp change_arena

no_select:
        lda #0
        sta swt_select
skip_select

        lda mode                ; check mode
        bne overscan_timer      ; if mode 0, then randomize
        jsr galois_lfsr_random  ; runs once through at frame end to increase entropy 

        ; overscan remainder timer -----------
overscan_timer          
        ldx INTIM
        bne overscan_timer

        jmp NextFrame           ; (3) jump back up to start the next frame


; Galois 8-bit Linear Feedback Shift Registers
; https://samiam.org/blog/20130617.html
galois_lfsr_random              
        lda r_seed              ; keep calling funtion to for better entropy
        lsr                     ; shift right
        bcc noeor0              ; if carry 1, then exclusive OR the bits
        eor #$D4                ; d4 tap (11010100)
noeor0: sta r_seed
        rts

galois_lfsr_forward
        lda l_seed
        lsr                     ; shift right
        bcc noeor1              ; if carry 1, then exclusive OR the bits
        eor #$D4                ; d4 tap (11010100)
noeor1: sta l_seed
        rts

galois_lfsr_backward
        lda l_seed
        asl                     ; shift left
        bcc noeor2              ; if carry 1, then exclusive OR the bits
        eor #$A9                ; a9 tap (10101001)
noeor2: sta l_seed
        rts

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

                                ;index  x-move  y-move  deg     direction  
bearing_offsets                 ;------------------------------------------                                                                                            
      	.byte #%11100000        ; 0     -2       0      90.0    right
        .byte #%11100111        ; 1     -2      -2      67.5
        .byte #%11100110        ; 2     -2      -4      45.0
        .byte #%11110110        ; 3     -1      -4      22.5
      	.byte #%00000110        ; 4      0      -4      0/360   up
        .byte #%00010110        ; 5     +1      -4      337.5
        .byte #%00100110        ; 6     +2      -4      315.0
        .byte #%00100111        ; 7     +2      -2      292.5  
      	.byte #%00101000        ; 8     +2       0      270.0   left
        .byte #%00101001        ; 9     +2      +2      247.5
        .byte #%00101010        ; 10    +2      +4      225.0
        .byte #%00011010        ; 11    +1      +4      202.5
      	.byte #%00001010        ; 12     0      +4      180.0   down
        .byte #%11111010        ; 13    -1      +4      157.5
        .byte #%11101010        ; 14    -2      +4      135.0
        .byte #%11101001        ; 15    -2      +2      112.5;

PF_col_lsb_ptr
        .byte <PF_col_atari
        .byte <PF_col_pattern
        .byte <PF_col_combat
        .byte <PF_col_activision
PF_col_msb_ptr
        .byte >PF_col_atari
        .byte >PF_col_pattern
        .byte >PF_col_combat
        .byte >PF_col_activision
PF0_lsb_ptr  
        .byte <PF0_data_atari     
        .byte <PF0_data_pattern
        .byte <PF0_data_combat
        .byte <PF0_data_activision
PF0_msb_ptr  
        .byte >PF0_data_atari     
        .byte >PF0_data_pattern  
        .byte >PF0_data_combat
        .byte >PF0_data_activision
PF1_lsb_ptr  
        .byte <PF1_data_atari     
        .byte <PF1_data_pattern
        .byte <PF1_data_combat
        .byte <PF1_data_activision
PF1_msb_ptr  
        .byte >PF1_data_atari     
        .byte >PF1_data_pattern  
        .byte >PF1_data_combat
        .byte >PF1_data_activision
PF2_lsb_ptr  
        .byte <PF2_data_atari     
        .byte <PF2_data_pattern
        .byte <PF2_data_combat
        .byte <PF2_data_activision
PF2_msb_ptr  
        .byte >PF2_data_atari     
        .byte >PF2_data_pattern                     
        .byte >PF2_data_combat
        .byte >PF2_data_activision

        INCLUDE "playfields/pf_atari.asm"
        INCLUDE "playfields/pf_pattern.asm"
        INCLUDE "playfields/pf_combat.asm"
        INCLUDE "playfields/pf_activision.asm"

        org 	$FFFA

        .word reset     	; NMI  ($FFFA)
        .word reset     	; RESET ($FFFC)
        .word reset     	; IRQ ($FFFE)