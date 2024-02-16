
				processor 6502				; s01e06 Ex2. Course Movement
				include	 "vcs.h"			;   
				include  "macro.h"			; Move our sprite accross the screen using a subroutine that
											; takes in an HPos and determines which color-clock to place 
											; the sprite by counting down by 15.
											; 
											; The movement is jerky because we're not using the HMP# to 
											; fine tune the position
                                          	;
                                            ; This Episode on Youtube - https://youtu.be/GObPgosXPPs
                                            ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                   		                    ;
                        	                ; Email - 8blit0@gmail.com

MAX_HPOS        equ 	#213				; while there are 160 color clocks in the visible portion of the screen
MIN_HPOS        equ 	#33					; anything draw during HSYNC is positioned at color clock 4 so let's move
											; things over to prevent that

MAX_VPOS		equ		#192

BKCOLOR			equ 	#$9A				; background colour (blue)
COLP0			equ		#$0E				; player 0 sprite colour (white)

				seg.u	vars				; uninitialized segment 
				org		$80

player0_x		ds		#MIN_HPOS			; byte variable to hold our horizontal position

				seg		main				; start of main segment
				org 	$F000



reset:			CLEAN_START					; macro included in macro.h file

	
				lda		#BKCOLOR			; (2)
				sta		COLUBK				; (3) set the PF color

				lda		#COLP0				; (2)
				sta		COLUP0				; (3) set the player 1 sprite colour

											; ---- Player Bitmap

				lda		#%10101111			; (2) stripped line
				sta		GRP0				; (3) graphic Player 0 


; ---- Begin main loop 

startframe:		VERTICAL_SYNC				; macro included in macro.h file

; ---- 37 scanlines vertical blank (8,436 color clocks, 2,812 machine cycles)

				ldx 	#36 				; (2)	
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
				dex							; (2) decrement x by 1
				bne 	lvblank				; (2/3) branch if not equal x != 37


        				; 76543210
				lda     #%00000000			; (2) set D1 to 0 to end VBLANK
				sta		WSYNC				; (3)
				sta     VBLANK				; (3) turn on the beam


				inc 	player0_x			; (5) increase the player0 horizontal position
				ldx		player0_x			; (2) load the new horizontal position into x
				cpx 	#MAX_HPOS				
				bcc		draw
				ldx		#MIN_HPOS+1
				stx 	player0_x
draw:
				jsr 	pos_x

; ---- 192 lines of drawfield				  Each scanline
											; (68 color clocks, 22 machine cycles) HBLANK
											; (160 color clocks, 53 machine cycles) + 1 Playfield				

    			ldx 	#MAX_VPOS			; (2)	
drawfield:		sta 	WSYNC				; (3) Wait for the next HSYNC
    			dex							; (2)
				bne 	drawfield			; (2/3)

; ---- Overscan (6,840 color clocks, 2,280 machine cycles)

				        ; 76543210
				lda     #%00000010			; set D1 = 1 to initiate VBLANK 
				sta     VBLANK				; turn off the beam
				ldx 	#MIN_HPOS			; (2)
overscan:       sta 	WSYNC				; (3)
				dex							; (2)
				bne 	overscan			; (2/3)
										
				jmp 	startframe			; (3) jump back up to start the next frame

Divide15									; the 6502/6507 has neither a multiplication nor a division instruction so here
.POS	SET 0								; we're building a list of values for divisions of 15 and which course position 
		REPEAT 256
			.byte (.POS / 15) + 1
.POS	SET .POS + 1
		REPEND				

pos_x  										; (3) subroutine to position the sprite, pass the HPOS in X register.
				lda		Divide15,x			; (2) load the value location at the xth byte in the Divide15 table
				tax							; (2) Transfer the accumulator to the x register
				sta 	WSYNC
											
; ---- this loop takes 5 machine cycles each iteration, that's 15 color clocks. 

loop:		dex							; (2) decrement x
				bne 	loop			; (2/3) branch if not equal	
				sta 	RESP0				; (3) strobe the RESP0 register to set the course position

				rts							; (6) return to caller

				org 	$FFFA				
	
irq:
				.word reset          		; NMI  ($FFFA)
				.word reset          		; RESET ($FFFC)
				.word reset          		; IRQ ($FFFE)


