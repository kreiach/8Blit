                processor 6502		; s02e01 Ex5. Two Ghost, Different Animation Frame Rate
                include	 "vcs.h"	;
                include  "macro.h"	;  
                                    ; 
                                    ; This Episode on Youtube - https://youtu.be/IGq992JnK1Q
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
                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ #192            ; playfield height
OS_H            equ #30             ; overscan height
VB_H            equ #33             ; vertical blank height - VERTICAL_SYNC macro takes 3 + 1 code in VB

GHOST_H         equ #9              ; ghost sprite height
GHOST_FP0       equ #31             ; Number of frames in the ghost animation
GHOST_FP1       equ #15             ; Number of frames in the ghost animation   


                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

p0_y			ds 1	 	        ; 1 byte - player 0 y pos
p1_y            ds 1	 	        ; 1 byte - player 1 y pos
tp0_y           ds 1                ; 1 byte - temporary player 0 y pos
tp1_y           ds 1                ; 1 byte - temporary player 1 y pos
scanline        ds 1                ; 1 byte - current scanline

ghost_frameP0   ds 1                ; current frame of ghost animation
ghost_frameP1   ds 1
ghostPtrP0      ds 2    
ghostPtrP1      ds 2    

                seg	main    		; start of main segment
                org $F000


reset:			CLEAN_START			; ouput: all ram registers 0

                lda	#$98	         
                sta	COLUBK			; set the PF color

                lda #$1E
                sta COLUP0          ; set the P1 color

                lda #$46
                sta COLUP1          ; set the P1 color

                lda #165		    
                sta p0_y			; initial y pos of p0
                sta p1_y            ; initial y pos of p1

                lda #8              ; reflect P1
                sta REFP1           

                lda #110            ; a = hpos
                ldx #0			    ; P0
                jsr pos_x			; set the initial course position of the player 0 graphic

                lda #70
                ldx #1			    ; P1
                jsr pos_x			; set the initial course position of the player 1 graphic

nextframe:		VERTICAL_SYNC	    ; output: a = 0

                ldx	#VB_H 			; (2)
vblank: 		sta	WSYNC			; (3) 
                dex					; (2) decrement x by 1
                bne	vblank 		    ; (2/3) branch if not equal 

                ; create a pointer to the ghost graphic instead of pointing directy to it
                inc ghost_frameP0   ; (5)
                lda ghost_frameP0   ; (2)
                and #GHOST_FP0      ; (2)
                sta ghost_frameP0   ; (3)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2)
                tax                 ; (2)

                lda ghost_pLSB,x    ; (2)
                sta ghostPtrP0      ; (3)

                lda ghost_pMSB,x   ; (5)
                sta ghostPtrP0+1    ; (3)

                inc ghost_frameP1   ; (5)
                lda ghost_frameP1   ; (2)
                and #GHOST_FP1      ; (2)
                sta ghost_frameP1   ; (3)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2)
                tax                 ; (2)

                lda ghost_pMSB,x   ; (5)
                sta ghostPtrP1+1    ; (3)

                lda ghost_pLSB,x    ; (5)
                sta ghostPtrP1      ; (3)          

ghost.done:     lda p0_y            ; (2)
                sta tp0_y           ; (3)

                lda p1_y            ; (2)
                sta tp1_y           ; (3)

                lda #PF_H		    ; (2)
                sta scanline        ; (3)

                lda #$0	            ; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		    ; (3)
                sta VBLANK		    ; (3) turn on the beam

kernel:		    lda #GHOST_H        ; (2) load height of sprite
                sec                 ; (2) set carry flag
                isb tp0_y           ; (5) increase tp0_y subtract from accumulator
                bcs draw_p0         ; (2/3)
                lda #0              ; (2)
                jmp skip_p0         ; (3)

draw_p0:        tay                 ; (2)
                lda (ghostPtrP0),y  ; (5) Indirect mode, pull graphic from pointer
                
skip_p0:        tax                 ; (2)
                lda #GHOST_H        ; (2)
                sec                 ; (2)
                isb tp1_y           ; (5)
                bcs draw_p1         ; (2/3)
                lda #0              ; (2)
                jmp skip_p1         ; (3)

draw_p1:        tay                 ; (2)
                lda (ghostPtrP1),y  ; (5)

skip_p1:        sta WSYNC           ; (3) 
                sta GRP1            ; (3)
                stx GRP0            ; (3)

                dec	scanline        ; (5)
                bne kernel		    ; (2/3)

                sta WSYNC           ; (2)

                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam
                ldx #OS_H	        ; (2)
overscan:       sta WSYNC		    ; (3)
                dex				    ; (2)
                bne overscan	    ; (2/3)

                jmp nextframe       ; (3) jump back up to start the next frame

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x           sta WSYNC	        ; (3) start a new line
	            sec		            ; (2) set carry flag
px.loop         sbc #15		        ; (2) subtract 15
	            bcs px.loop	        ; (2/3) branch until negative
	            eor #7		        ; (2) calculate fine offset
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            sta RESP0,x	        ; (3) fix coarse position
	            sta HMP0,x	        ; (3) set fine offset
	            rts		            ; (6) return to caller

ghost_pLSB:     .byte <ghost_f0     ; LSB
                .byte <ghost_f1

ghost_pMSB:     .byte >ghost_f0     ; MSB
                .byte >ghost_f1

ghost_f0:       .byte $0
	            .byte %01010101 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100 

ghost_f1:       .byte $0
	            .byte %10101010 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100         

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)


