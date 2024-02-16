                processor 6502		; -----------------------------------------------------
                                    ; S02E03 Ex2. Timers - Same as Ex1, but uses timers for the Vertical Blank, and Overscan
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/KJYeQjJTkj4
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
                                    ; PIA off the shelf 6532 Peripheral Interface Adaptor
                                    ; Programmable timers, 128 bytes RAM
                                    ; Two 8-bit parallel I/O ports
                                    ;
                                    ; PIA uses the same clock as 6502. 1 PIA cycle per 1 Machine Cycle.
                                    ; Can be set to 1 of 4 counting intervals. 1, 8, 64, 1024
                                    ; Select how many intervals from 1 to 255.
                                    ; Valu decrements at each interval
                                    ;
                                    ; write value to the desired interval setting
                                    ; 1 clock   TIM1T
                                    ; 8 clocks  TIM8T
                                    ; 64 clocks TIM64T
                                    ; 1024 clocks T1024T
                                    ;
                                    ; Read the timers after loaded at INTIM
                                    ;
                                    ; When it reaches 0, it will hold 0 for one interval, then the counter will flip to FF and decrements
                                    ; each clock cycle to allow the programmer determine how long ago the timer zeroed out.


                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ #192            ; playfield height

GHOST_H         equ #9              ; ghost sprite height
GHOST_F         equ #2              ; Number of frames in the ghost animation


                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

p0_y			ds 1	 	        ; 1 byte - player 0 y pos
tp0_y           ds 1                ; 1 byte - temporary player 0 y pos
p0_x            ds 1                ; 1 byte - player 0 x pos
p0_bitmap       ds 1    

scanline        ds 1                ; 1 byte - current scanline

ghost_cel       ds 1                ; current cel of ghost animation
ghost_ptr       ds 2    

                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                lda #$1E
                sta COLUP0          ; set the P0 color 

                lda #$A8       
                sta COLUBK               

                ; set initial player position
                lda #165		    
                sta p0_y			; initial y pos of p0

                lda #80
                sta p0_x            ; initial x pos of p0

; ---- Verticle Sync (3 scanlines)

nextframe:		VERTICAL_SYNC	    ; output: a = 0; 3 scanlines

; ---- Vertical Blank (37 scanlines)

                ; 37 scanlines x 76 machine cycles per scanline = 2812 machine cycles
                ; 2812 machine cycles / 64 clocks = 43.9375
                ldx #43             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 43 with 64-clock interval

                ; start timer --------------------------------------------------------------------------

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

ghost_done:     lda p0_y            ; (2)
                sta tp0_y           ; (3)

                lda #PF_H		    ; (2)
                sta scanline        ; (3)

timer1:         ldx INTIM           ; check the timer          
                bne timer1          ; if it's not 0 then branch back up to timer1

                lda #0	            ; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		    ; (3) end with a clean scanline
                sta VBLANK		    ; (3) turn on the beam

kernel:		    lda #GHOST_H        ; (2) load height of sprite
                sec                 ; (2) set carry flag
                isb tp0_y           ; (5) increase tp0_y subtract from accumulator
                bcs draw_p0         ; (2/3)
                lda #0              ; (2)


draw_p0:        tay                 ; (2)

                lda (ghost_ptr),y    ; (5) Indirect mode, pull graphic from pointer
                sta p0_bitmap

                sta WSYNC           ; (3) 
                sta GRP0            ; (3)

                dec	scanline        ; (5)
                bne kernel		    ; (2/3)

                sta WSYNC           ; (3) end kernel with a clean scan line
                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam

; ---- Overscan (30 scanlines)

                ; 30 scanlines x 76 machine cycles = 2280 machine cycles
                ; 2280 machine cycles / 64 clocks = 35.625

                ldx #35             ; We'll round down, and clean up the remaining cycles with a WSYNC
                stx TIM64T          ; Set a count of 35 with 64-clock interval


; Reset
input:          lda #%00000001      ; (2) read reset input
                bit SWCHB
                bne switch_noreset
                jmp reset
switch_noreset: 
    

; read direction input
                ldx p0_x
                lda #%10000000      ; check for right movement
                bit SWCHA
                bne pos_noright
                cpx #152
                bcs pos_noright
                inx
                lda #%00001000
                sta REFP0                
pos_noright                
                lda #%01000000      ; check left movement
                bit SWCHA
                bne pos_noleft
                cpx #1
                bcc pos_noleft
                dex
                lda #0
                sta REFP0                
pos_noleft:
                stx p0_x
                ldx p0_y
                lda #%00100000                
                bit SWCHA
                bne pos_nodown
                cpx #74
                bcc pos_nodown
                dex
pos_nodown:
                lda #%00010000                
                bit SWCHA
                bne pos_noup
                cpx #255
                bcs pos_noup
                inx
pos_noup:
                stx p0_y

                ; timer2 -----------

timer2:         ldx INTIM
                bne timer2

                sta WSYNC 

                jmp nextframe       ; (3) jump back up to start the next frame
 

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x           sta WSYNC	        ; (3) start a new line
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
	            rts		            ; (6) return to caller


ghost_f0:       
                .byte $0
	            .byte %01010101 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100 

ghost_f1:       
                .byte $0
	            .byte %10101010 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100             

ghost_lsb_ptr:  
                .byte <ghost_f0     ; LSB
                .byte <ghost_f1

ghost_msb_ptr:  
                .byte >ghost_f0     ; MSB
                .byte >ghost_f1  

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)











