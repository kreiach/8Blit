                processor 6502				; s03e08 Ex1. Not a scary ghost
                include	 "vcs.h"			;
                include  "macro.h"			; 
                                            ; This Episode on Youtube - https://youtu.be/fZu8dxS1ARw
                                            ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                   		                    ;
                        	                ; Email - 8blit0@gmail.com

pf_h            equ     #192                ; playfield height
os_h            equ     #34                 ; overscan height
vb_h            equ     #37                 ; vertical blank height

ghost_h         equ     #9                  ; ghost sprite height


                seg.u	vars				; uninitialized segment
                org		$80

p0_y			ds      1	 				; 1 byte - player 0 y pos
tp0_y           ds      1                   ; 1 byte - temporary player 0 y pos
scanline        ds      1                   ; 1 byte - current scanline

ghost_frame     ds      1

                seg		main				; start of main segment
                org 	$F000


reset:			CLEAN_START					; macro included in macro.h file

                lda		#$98			    ; (2)
                sta		COLUBK				; (3) set the PF color

                lda     #$1E
                sta     COLUP0              ; (3)

                lda		#165		        ; (2) 
                sta 	p0_y				; (3) initial y pos of p0

                lda     #80                 ; (2) a = hpos
                ldx 	#0			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 0 graphic

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

                ldx 	#vb_h 				; (2)
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
                dex							; (2) decrement x by 1
                bne 	lvblank				; (2/3) branch if not equal x != 37

                
  

                lda     p0_y                ; (2)
                sta     tp0_y               ; (3)

                lda 	#pf_h			    ; (2)
                sta     scanline            ; (3)

                lda     #%00000000			; (2) set D1 to 0 to end VBLANK
                sta		WSYNC				; (3)
                sta     VBLANK				; (3) turn on the beam

kernel:		  
                lda     #ghost_h            ; (2) load height of sprite
                sec                         ; (2) set carry flag
                isb     tp0_y               ; (5) increase tp0_y subtract from accumulator
                bcs     draw_p0             ; (2/3)
                lda     #0                  ; (2)

draw_p0:            
                tay
                lda     ghost,y             ; (4)
                
                sta     WSYNC               ; (3) 
                sta     GRP0                ; (3)
        
                dec		scanline			; (5)
                bne 	kernel			    ; (2/3)

                sta     WSYNC

                lda     #%00000010			; set D1 = 1 to initiate VBLANK
                sta     VBLANK				; turn off the beam
                ldx 	#os_h			    ; (2)
overscan:       sta 	WSYNC				; (3)
                dex							; (2)
                bne 	overscan			; (2/3)

                jmp 	nextframe			; (3) jump back up to start the next frame

; SetHorizPos routine
; A = X coordinate
; X = player number (0 or 1)
pos_x
                sta     WSYNC	            ; (3) start a new line
	            sec		                    ; (2) set carry flag
loop
	            sbc     #15		            ; (2) subtract 15
	            bcs     loop	            ; (2/3) branch until negative
	            eor     #7		            ; (2) calculate fine offset
	            asl                         ; (2)
	            asl                         ; (2)
	            asl                         ; (2)
	            asl                         ; (2)
	            sta     RESP0,x	            ; (3) fix coarse position
	            sta     HMP0,x	            ; (3) set fine offset
	            rts		                    ; (6) return to caller


ghost:
                .byte %00000000 ;
	            .byte %01010101 ;
	            .byte %11111111 ;
	            .byte %11111111 ;
	            .byte %11111111 ;
	            .byte %10010011 ;
	            .byte %11011011 ;
	            .byte %10010011 ;
	            .byte %01111110 ;
            	.byte %00111100 ;         
      


                org 	$FFFA


irq:
                .word reset          		; NMI  ($FFFA)
                .word reset          		; RESET ($FFFC)
                .word reset          		; IRQ ($FFFE)


