				processor 6502			; s01e05 Ex0. Draw the playfield on an Atari 2600
				include	 "vcs.h"		; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
										; Registers to draw a in the safe visual area of the screen, using the 
                                       	; generally recommended number of VBLANK's
                                        ;
                                        ; This Episode on Youtube - https://youtu.be/LWIyHl9QfvQ
                                        ;
										; Become a Patron - https://patreon.com/8blit
										; 8blit Merch - https://8blit.myspreadshop.com/
										; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
										; Follow on Facebook - https://www.facebook.com/8Blit
										; Follow on Instagram - https://www.instagram.com/8blit
										; Visit the Website - https://www.8blit.com 
                                        ;
                                        ; Email - 8blit0@gmail.com

PFCOLOR 		equ 	#$A2

				; ------------------------- Start of main segment ---------------------------------

				seg		main
				org 	$F000

				; ------------------------- Start of program execution ----------------------------

reset: 			ldx 	#0 				; Clear RAM and all TIA registers
				lda 	#0 
  
clear:       	sta 	0,x 			; $0 to $7F (0-127) reserved OS page zero, $80 to $FF (128-255) user zero page ram.
				inx 
				bne 	clear

				lda 	#%00000001		; Set D0 to reflect the playfield
				sta 	CTRLPF			; Apply to the CTRLPF register

				lda		#PFCOLOR			
				sta		COLUPF			; Set the PF color

				; --------------------------- Begin main loop -------------------------------------

startframe:			; ------- 76543210 ---------- Bit order
				lda 	#%00000010		; Writing a bit into the D1 vsync latch
				sta 	VSYNC 

				; --------------------------- 3 scanlines of VSYNC signal
				sta 	WSYNC
				sta 	WSYNC
				sta 	WSYNC  

				; --------------------------- Turn off VSYNC         	 
				lda 	#0
				sta	 	VSYNC

				; -------------------------- Additional 37 scanlines of vertical blank ------------

				ldx 	#0 					
lvblank:		sta 	WSYNC
				inx
				cpx 	#37				; 37 scanlines of vertical blank
				bne 	lvblank
				
				; --------------------------- 192 lines of drawfield ------------------------------

    			ldx 	#0 					
drawfield:		lda		#%11111111		; Solid row of pixels for all PF# registers
				sta 	PF0
				sta		PF1
				sta		PF2				

        		sta 	WSYNC
    			inx  
				cpx 	#192
				bne 	drawfield

				; -------------------------- 30 scanlines of overscan -----------------------------
                lda     #%00000000
                sta     PF0
               	sta     PF1
                sta     PF2

				ldx 	#0					
overscan:       sta 	WSYNC
				inx
				cpx 	#30
				bne 	overscan

				; --------------------------- End of overscan -------------------------------------

				jmp 	startframe		; jump back up to start the next frame

				; --------------------------- Pad until end of main segment -----------------------

				org 	$FFFA
	
irqvectors:
				.word reset         	; NMI
				.word reset         	; RESET
				.word reset         	; IRQ

				; -------------------------- End of main segment ----------------------------------
