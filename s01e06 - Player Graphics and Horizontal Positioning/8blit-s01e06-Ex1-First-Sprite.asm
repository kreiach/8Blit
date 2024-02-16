
				processor 6502				; s01e06 Ex1. First Sprite
				include	 "vcs.h"			; GRPO (Grapihcs Player 0) are assgined a pattern.  
				include  "macro.h"			; RESP0 immeadiatly sets the X or Horizontal position of Player 0.
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

BKCOLOR			equ 	#$9A				; Background colour (blue)
COLP0			equ		#$0E				; Player 0 sprint colour (white)

				seg		main				; Start of main segment
				org 	$F000

; ---- Start execution 
											; Clear RAM and all TIA registers, $0-$7F (0-127) reserved OS page zero, $80-$FF (128-255) user zero page ram.
											; 8 byte system clear by Andrew Davie

reset:			ldx 	#0 					; (2) x = 0
				txa 	 					; (2) a = x
  
clear:			dex 						; (2) x = x -1
				txs 						; (2) transfer x to stack
				pha							; (3) push a to stack
				bne 	clear				; (2/3) if not 0 goto clear


; ---- Initialize 

				lda		#BKCOLOR			; (2)
				sta		COLUBK				; (3) Set the PF color

				lda		#COLP0				; (2)
				sta		COLUP0				; (3) Set the player 0 sprite colour

											; ---- Player Bitmap

				lda		#%10101111			; (2) stripped line
				sta		GRP0				; (3) Graphic Player 0 

				sta		WSYNC

				SLEEP	19					; Change this number to move the graphic to the right side				

				sta 	RESP0				; (3) Reset Player 0 - Strobe (writing any value triggers the strobe)
											; The TIA takes 5 color clocks to draw RESP0				

											; RESPO will be drawn at color clock = 4 if it is strobed during HSYNC. After, it's it will increment by 3 color clocks for
											; for each additional machine cycle											

; ---- Begin main loop 

startframe:
						; 76543210
				lda 	#%00000010			; (2) Writing D1 bit of the vsync latch to start vsync
				sta 	WSYNC				; (3)
				sta 	VSYNC 				; (3) Turn off the beam 

; ---- 3 scanlines VSYNC, time it takes to turn off beam, min 3 scanlines (684 color clocks, 228 machine cycles)

				sta 	WSYNC				; (3) Halt 6502/6507 processor until next scanline - Strobe (writing any value triggers the strobe)
				sta 	WSYNC				; (3) Wait-For-Sync -> Waiting for HSYNC, when beam returns to the begining of the next scanline
				sta 	WSYNC				; (3) 
						; 76543210  
				lda 	#%00000000			; (2) Clearing D1 bit of the vsync latch to end vsync
				sta		VSYNC				; (3) Turn on the beam

; ---- 37 scanlines vertical blank (8,436 color clocks, 2,812 machine cycles)

				ldx 	#37 				; (2)	
lvblank:		sta 	WSYNC				; (3) Each scanline is 228 color clocks, 76 machine cycles
				dex							; (2) Decrement x by 1
				bne 	lvblank				; (2/3) Branch if not equal x != 37

        				; 76543210
				lda     #%00000000			; (2) Set D1 to 0 to end VBLANK
				sta		WSYNC				; (3)
				sta     VBLANK				; (3) Turn on the beam
				
; ---- 192 lines of drawfield				  Each scanline
											; (68 color clocks, 22 machine cycles) HBLANK
											; (160 color clocks, 53 machine cycles) + 1 Playfield


    			ldx 	#192 				; (2)	
drawfield:		
				sta 	WSYNC				; (3) Wait for the next HSYNC
    			dex							; (2)
				bne 	drawfield			; (2/3)


; ---- Overscan (6,840 color clocks, 2,280 machine cycles)

				sta     WSYNC				; (3)

				        ; 76543210
				lda     #%00000010			; (2) Set D1 = 1 to initiate VBLANK 
				sta     VBLANK				; (3) Turn off the beam

				ldx 	#30					; (2)
overscan:       sta 	WSYNC				; (3)
				dex							; (2)
				bne 	overscan			; (2/3)

				jmp 	startframe			; (3) jump back up to start the next frame


				org 	$FFFA				
	
irqvectors:
				.word reset          		; NMI  ($FFFA)
				.word reset          		; RESET ($FFFC)
				.word reset          		; IRQ ($FFFE)


