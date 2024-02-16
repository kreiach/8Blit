 
                processor 6502		; s02e04 Ex1. One Player Graphic 1SL, Background 4SL
                include	 "vcs.h"	;
                include  "macro.h"	; 
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

                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ #48             ; playfield height (in segments)
GHOST_H         equ #12              ; ghost sprite height
GHOST_F         equ #2              ; Number of frames in the ghost animation

                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

p0_y			ds 1	 	        ; 1 byte - player 0 y pos
tp0_y           ds 1                ; 1 byte - temporary player 0 y pos
p0_x            ds 1                ; 1 byte - player 0 x pos
;p0_bitmap       ds 1    
pf_index        ds 1                ; 1 byte - playfield index
;seg_index       ds 1
;playfield_ptr   ds 2                ; 1 byte - pointer to playfield data
ghost_cel       ds 1                ; current cel of ghost animation
ghost_col_ptr   ds 2
ghost_ptr       ds 2    
tpf0            ds 1
tpf1            ds 1
tpf2            ds 1

                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                lda #%00000001      ; set playfield to reflect (default behavior, not nessesary)
                sta CTRLPF          ; control playfield

                lda #$1E
                sta COLUP0          ; set the P0 color 

                lda #$A8       
                sta COLUPF

                lda #$0
                sta COLUBK    

                         

                ; set initial player position
                lda #165		    
                sta p0_y			; initial y pos of p0
                lda #80
                sta p0_x            ; initial x pos of p0

; ---- Verticle Sync (3 scanlines)

nextframe		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines

; ---- Vertical Blank (37 scanlines)

                ldx #43             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 43 with 64-clock interval

                ; set the x position 
                lda p0_x            ; load the p0 x position
                ldx #0			    ; P0
                jsr pos_x			; set the initial course position of the player 0 graphic
                sta WSYNC
                sta HMOVE	        ; gotta apply HMOVE

                ; create a pointer to the ghost graphic
                inc ghost_cel       ; (5)
                lda ghost_cel       ; (2)
                and #15             ; (2)
                sta ghost_cel       ; (3)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2) 

                tax                 ; (2)
                lda ghost_lsb_ptr,x ; (5)
                sta ghost_ptr       ; (3)
                lda ghost_msb_ptr,x ; (5)
                sta ghost_ptr+1     ; (3)

                lda ghost_col_lsb_ptr,x
                sta ghost_col_ptr
                lda ghost_col_msb_ptr,X
                sta ghost_col_ptr+1


ghost_done      lda p0_y            ; (2)
                sta tp0_y           ; (3)

                ; prime first line of playfield
                ldy #PF_H
                lda PF0_data,y
                sta PF0
                lda PF1_data,y
                sta PF1
                lda PF2_data,y
                sta PF2
                sty pf_index

timer1          ldx INTIM           ; check the timer          
                bne timer1          ; if it's not 0 then branch back up to timer1

                lda #0	            ; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		    ; (3) end with a clean scanline
                sta VBLANK		    ; (3) turn on the beam

                ; end of VBLANK



kernel		    jsr draw_p0         ; (27, 9 from WSYNC) Draw P0
                ldy pf_index
                beq pf_end
                dey
                sty pf_index

                lda PF0_data,y      ;4
                sta tpf0            ;3

                jsr draw_p0
                ldy pf_index
                lda PF1_data,y
                sta tpf1

                jsr draw_p0
                ldy pf_index
                lda PF2_data,y
                sta tpf2

                jsr draw_p0
                lda tpf0
                sta PF0
                lda tpf1
                sta PF1
                lda tpf2
                sta PF2

                jmp kernel		    ; (2/3)
                
pf_end          sta WSYNC           ; (3) end kernel with a clean scan line
                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam

; ---- Overscan (30 scanlines)

                ldx #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 35 with 64-clock interval

                lda #0
                sta GRP0 

; Reset
input           lda #%00000001      ; (2) read reset input
                bit SWCHB
                bne switch_noreset
                jmp reset
switch_noreset 
    

; read direction input
                ldx p0_x
                lda #%10000000      ; check for right movement
                bit SWCHA
                bne pos_noright
                cpx #152
                bcs pos_noright
                inx
                lda #%00000000
                sta REFP0                
pos_noright                
                lda #%01000000      ; check left movement
                bit SWCHA
                bne pos_noleft
                cpx #1
                bcc pos_noleft
                dex
                lda #%00001000
                sta REFP0                
pos_noleft
                stx p0_x
                ldx p0_y
                lda #%00100000                
                bit SWCHA
                bne pos_nodown
                cpx #77
                bcc pos_nodown
                dex
pos_nodown
                lda #%00010000                
                bit SWCHA
                bne pos_noup
                cpx #255
                bcs pos_noup
                inx
pos_noup
                stx p0_y

                ; timer2 -----------

timer2          ldx INTIM
                bne timer2
                

                jmp nextframe       ; (3) jump back up to start the next frame

; draw player (37 mc total, 28mc to WSYNC, 9 mc after WSYNC)
draw_p0:        lda #GHOST_H        ; (2) load height of sprite
                sec                 ; (2) set carry flag
                isb tp0_y           ; (5) increase tp0_y subtract from accumulator
                bcs drawing_p0      ; (2/3)
                lda #0              ; (2)
drawing_p0      tay                 ; (2)
                lda (ghost_col_ptr),y
                tax
                
                lda (ghost_ptr),y   ; (5) Indirect mode, pull graphic from pointer
                sta WSYNC           ; (3) 
                sta GRP0            ; (3)
                stx COLUP0 
                
                rts                 ; (6) return from subroutine

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x:          sta WSYNC	        ; (3) start a new line
                bit 0               ; 
	            sec		            ; (2) set carry flag
pos_x_loop      sbc #15		        ; (2) subtract 15
	            bcs pos_x_loop	    ; (2/3) branch until negative
	            eor #7		        ; (2) calculate fine offset
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            sta RESP0,x	        ; (3) fix coarse position
	            sta HMP0,x	        ; (3) set fine offset
	            rts		            ; (6) return from subroutine

                align $100          ; align?

; we're going with a 4 scanline playfield loading data from the bottom up

                ;     PF2        PF1        PF0 
                ;     8bits rev  8bits      4 bits rev
PF0_data        .byte #%00000000
                .byte #%11111111 ;<- last
                .byte #%11110000
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
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%00010000
                .byte #%11110000 ;<- second
                .byte #%11111111 ;<- first

PF1_data        .byte #%00000000
                .byte #%11111111 ;<- last
                .byte #%11111111
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
                .byte #%11111111 ;<- second
                .byte #%11111111 ;<- first

PF2_data        .byte #%00000000
                .byte #%11111111 ;<- last
                .byte #%11111111
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
                .byte #%11111111
                .byte #%11111111 ;<- first
          

          

ghost_f0
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
ghost_f1
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

ghost_lsb_ptr  
                .byte <ghost_f0     ; LSB
                .byte <ghost_f1

ghost_msb_ptr  
                .byte >ghost_f0     ; MSB
                .byte >ghost_f1  

ghost_f0_col    .byte $0
	            .byte #$28      ; orange
	            .byte #$2C      ; orange
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$98      ;
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0E      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$EE      ;  yellow

ghost_f1_col    .byte $0
	            .byte #$28      ; orange
	            .byte #$2C      ; orange
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$98      ;
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0E      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$0C      ; dark grey
	            .byte #$1A     ;  yellow                

ghost_col_lsb_ptr  
                .byte <ghost_f0_col     ; LSB
                .byte <ghost_f1_col

ghost_col_msb_ptr  
                .byte >ghost_f0_col     ; MSB
                .byte >ghost_f1_col  

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)











