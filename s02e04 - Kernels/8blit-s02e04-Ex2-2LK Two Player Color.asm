        processor 6502          ; s02e04 2LK Two Player Graphics 2SL, Background 4SL
                            
        include	 "vcs.h"	
        include  "macro.h"	 
                                ;
                                ; This Episode on Youtube - https://youtu.be/VP0kUBIH2T0
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
ROBOT_H         equ #12         ; robot sprite height
ROBOT_F         equ #2          ; number of frames in the robot animation

        seg.u	vars		; uninitialized segment
        org	$80             ; origin set at base of ram

p0_y		ds 1	 	; player 0 y pos
tp0_y           ds 1            ; temporary player 0 y pos
p0_x            ds 1            ; player 0 x pos
colp0           ds 1            ; temporary to store player 0 color
p1_y		ds 1	 	; player 1 y pos
tp1_y           ds 1            ; temporary player 1 y pos
p1_x            ds 1            ; player 1 x pos
pf_count        ds 1            ; playfield index
robot_cel       ds 1            ; current cel of robot animation
robot_col_ptr   ds 2
robot1_col_ptr  ds 2
robot_ptr       ds 2  
robot_tcol      ds 1 
robot0_tcol     ds 1 
tpf0            ds 1
tpf1            ds 1
tpf2            ds 1

        seg	main    	; start of main segment
        org $F000

Reset:			
        CLEAN_START		; ouput: all ram/registers 0

        ; set area values
        lda #%00000001  ; playfield to reflect (default behavior, not nessesary)
        sta CTRLPF      ; set control playfield
        lda #$A8        ; blue
        sta COLUPF      ; set playfield color
        lda #$0         ; black
        sta COLUBK      ; set background color
        lda #1          ; delay updating GRP0 until GRP1 is written
        sta VDELP0	; set vertical delay

        ; set initial player position
        lda #200		    
        sta p0_y	; initial y pos of p0
        sta p1_y	; initial y pos of p1
        lda #40
        sta p0_x        ; initial x pos of p0
        lda #120
        sta p1_x        ; initial x pos of p1                
        lda #%00001000  ; player reflect    
        sta REFP1       ; set reflect on player 1    

NextFrame:
	VERTICAL_SYNC	; output: a = 0; 3 scanlines
        sta WSYNC

VerticalBlank               
        ldx #43         ; 37sl * 76mc = 2812 
        stx TIM64T      ; set 64-clock for 43 intervals. 43 * 64mc = 2752mc before timer ends

PositionPlayers
        lda p0_x        ; player 0 x position
        ldx #0		; player 0 object
        jsr PositionX		 
        lda p1_x        ; player 1 x position
        ldx #1		; player 1 object
        jsr PositionX		
        sta WSYNC           
        sta HMOVE	; strobe horizontal move to fine positions

        ; create pointers to the robot graphic
        inc robot_cel   ; next cel
        lda robot_cel        
        and #15               
        sta robot_cel       
        lsr                 
        lsr                 
        lsr                  
        tax                 
        lda robot_lsb_ptr,x 
        sta robot_ptr       
        lda robot_msb_ptr,x 
        sta robot_ptr+1     
        lda robot_col_lsb_ptr,x
        sta robot_col_ptr
        lda robot_col_msb_ptr,X
        sta robot_col_ptr+1
        lda robot1_col_lsb_ptr,x
        sta robot1_col_ptr
        lda robot1_col_msb_ptr,X
        sta robot1_col_ptr+1        

        lda p0_y            ; player 0 y position
        sta tp0_y           ; set working y index
        lda p1_y            ; player 1 y position
        sta tp1_y           ; set working y index

        ldx #255
        ldy #PF_H
        sty pf_count

CheckTimer:
        lda INTIM           ; time remaining (or past)
        bne CheckTimer      ; burn remaining cycles

        lda #0	            ; D1 to 0 to end VBLANK
        sta WSYNC
;--------------------------------------		    
        sta VBLANK	        ; 3   3 - set vertical blank off

Kernel:                         
        lda pf_count;           ; 2   5 [18]
        and #%11                ; 2   7 [20]
        bne SkipX               ; 3  10 [23]
        inx                     ; 2  12 [25]
SkipX      
        ; draw player 0
        lda #ROBOT_H            ; 2  14 [27] - load height of sprite
        sec                     ; 2  16 [29] - set carry flag
        isb tp0_y               ; 6  22 [35] - increase tp0_y subtract from accumulator
        bcs drawing_p0          ; 3  25 [38] - 
        lda #0                  ; 2  27 [41]
drawing_p0
        tay                     ; 2  29 [43]
        lda (robot_col_ptr),y   ; 5  34 [48]
        sta robot0_tcol          ; 3  37 [51]
        lda (robot_ptr),y       ; 5  42 [56] - pull graphic from pointer
        sta WSYNC               ; 3  45 [59]
;--------------------------------------        
        sta GRP0                ; 3   3 - immediatly store, but wont be written until GRP1 is
        

        ; draw playfield
        lda PF0_data,x          ; 2  10 
        sta PF0                 ; 3  13
        lda PF1_data,x          ; 2  15
        sta PF1                 ; 3  18
        lda PF1_data,x          ; 2  20
        sta PF2                 ; 3  23
 
        ; draw player 1
        lda #ROBOT_H            ; 2  25 - load height of sprite
        sec                     ; 2  27 - set carry flag
        isb tp1_y               ; 6  33 - increase tp0_y subtract from accumulator
        bcs drawing_p1          ; 3  36 - 
        lda #0                  ; 2  38
drawing_p1
        tay                     ; 2  40
        lda (robot1_col_ptr),y  ; 5  45
        sta robot_tcol          ; 3  48
        lda (robot_ptr),y       ; 5  53 - pull graphic from pointer
        sta WSYNC               ; 3  56
;--------------------------------------        
        sta GRP1                ; 3   3 - immediatly store, but wont be written until GRP1 is
        lda robot0_tcol          ; 2   5
        sta COLUP0              ; 3   8
        lda robot_tcol          ; 2   5
        sta COLUP1              ; 3   8

        dec pf_count            ; 5  13
        bne Kernel              ; 3  16

        sta WSYNC
        
        lda #0
        sta PF0
        sta PF1
        sta PF2
        
        ; end of kernel

pf_end          
        sta WSYNC           ; end kernel with a clean scan line
        lda #$2     	    ; set D1 = 1 to initiate VBLANK
        sta VBLANK		    ; turn off the beam

; ---- Overscan (30 scanlines)
        ldx #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
        stx TIM64T          ; Set a count of 35 with 64-clock interval

        ; read direction input player 0
        ldx p0_x
        ; check right movement
        lda #%10000000      
        bit SWCHA
        bne pos_noright
        cpx #155
        bcs pos_noright
        inx
        lda #%00000000
        sta REFP0                
pos_noright     
        ; check left movement   
        lda #%01000000      
        bit SWCHA
        bne pos_noleft
        cpx #4
        bcc pos_noleft
        dex
        lda #%00001000
        sta REFP0                
pos_noleft
        stx p0_x        ; store x position

        ; check down movement
        ldx p0_y
        lda #%00100000                
        bit SWCHA
        bne pos_nodown
        cpx #173        ; lower bound
        bcc pos_nodown
        dex
pos_nodown
        ; check up movement
        lda #%00010000                
        bit SWCHA
        bne pos_noup
        cpx #255        ; upper bound
        bcs pos_noup
        inx
pos_noup
        stx p0_y        ; store y position

        ; read direction input player 1
        ldx p1_x
        ; check right movement
        lda #%00001000      
        bit SWCHA
        bne pos_noright1
        cpx #155
        bcs pos_noright1
        inx
        lda #%00000000
        sta REFP1                
pos_noright1     
        ; check left movement   
        lda #%00000100      
        bit SWCHA
        bne pos_noleft1
        cpx #4
        bcc pos_noleft1
        dex
        lda #%00001000
        sta REFP1                
pos_noleft1
        stx p1_x        ; store x position

        ; check down movement
        ldx p1_y
        lda #%00000010                
        bit SWCHA
        bne pos_nodown1
        cpx #173        ; lower bound
        bcc pos_nodown1
        dex
pos_nodown1
        ; check up movement
        lda #%00000001                
        bit SWCHA
        bne pos_noup1
        cpx #255        ; upper bound
        bcs pos_noup1
        inx
pos_noup1
        stx p1_y        ; store y position        

        ; timer2 -----------
timer2          
        ldx INTIM
        bne timer2

        jmp NextFrame       ; (3) jump back up to start the next frame


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
        sec	        ;  2 +2 - set the carry flag
        sta WSYNC	;  3 +5 - start a new line
DivideLoop
        sbc #15		;  2  2 - subtract 15
	bcs DivideLoop	;  2  4 - branch until negative
	eor #7		;  2  6 - calculate fine offset
	asl             ;  2  8 - shift left
	asl             ;  2 10
	asl             ;  2 12
	asl             ;  2 14
	sta HMP0,x	;  5 19 - set fine offset
	sta RESP0,x	;  4 23 - set coarse position
	rts		;  6 29 - return

        align $100      ; align data

; we're going with a 4 scanline playfield loading data from the bottom up
PF0_data
        .byte #%11110000 ;<- first
        .byte #%00010000 
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
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00010000
        .byte #%00110000
        .byte #%00010000
        .byte #%11110000 ;<- last

PF1_data
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
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
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
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%00000000
        .byte #%11111111 ;<- last

robot_f0
        .byte $0
	.byte %00000000 ;
	.byte %10000100 ;
	.byte %01010010 ;
	.byte %11111111 ;
	.byte %10101010 ;
	.byte %11111110 ;
	.byte %01111111 ;
	.byte %11001001 ;
	.byte %11011011 ;
	.byte %11001001 ;
	.byte %01111110 ;
	.byte %00001000 ;

robot_f1
        .byte $0
	.byte %10000100 ;
	.byte %00010000 ;
	.byte %01000010 ;
	.byte %11111111 ;
	.byte %01010101 ;
	.byte %11111110 ;
	.byte %01111111 ;
	.byte %11001001 ;
	.byte %11011011 ;
	.byte %11001001 ;
	.byte %01111110 ;
	.byte %00001000 ;

robot_lsb_ptr  
        .byte <robot_f0     ; LSB
        .byte <robot_f1

robot_msb_ptr  
        .byte >robot_f0     ; MSB
        .byte >robot_f1  

robot_f0_col
        .byte $0
	.byte #$28      ; orange
	.byte #$2C      ; orange
	.byte #$0C      ; dark grey
	.byte #$0C      ; dark grey
        .byte #$98      ; blue
	.byte #$0C      ; dark grey
	.byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0E      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$EE      ; yellow
        
robot_f1_col
        .byte $0
        .byte #$28      ; orange
        .byte #$2C      ; orange
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$98      ; blue
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0E      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$1A     ;  yellow        

robot1_f0_col
        .byte $0
	.byte #$28      ; orange
	.byte #$2C      ; orange
	.byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$44      ; red
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0E      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$36      ; yellow
        .byte #0
robot1_f1_col
        .byte $0
	.byte #$28      ; orange
        .byte #$2C      ; orange
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$44      ; red
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0E      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$0C      ; dark grey
        .byte #$3A      ; yellow
                                           

robot_col_lsb_ptr  
        .byte <robot_f0_col      ; LSB
        .byte <robot_f1_col 

robot_col_msb_ptr  
        .byte >robot_f0_col     ; MSB
        .byte >robot_f1_col  

robot1_col_lsb_ptr  
        .byte <robot1_f0_col     ; LSB
        .byte <robot1_f1_col

robot1_col_msb_ptr  
        .byte >robot1_f0_col     ; MSB
        .byte >robot1_f1_col                 

        org 	$FFFA

        .word Reset     	; NMI  ($FFFA)
        .word Reset     	; RESET ($FFFC)
        .word Reset     	; IRQ ($FFFE)

