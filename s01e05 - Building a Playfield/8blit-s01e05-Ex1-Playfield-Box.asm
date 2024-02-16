				processor 6502			; s01e05 Ex1. Draw the playfield on an Atari 2600
				include	 "vcs.h"		; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
										; Registers to draw a border around the screen. We're setting the top and
										; bottom border before and at the end of the main 192 screen frame which will result in
										; thicker than expected top and bottom boarders when executed in the 
										; Stella emulator because it shows the number of scanlines that could be displayed on some CRT's.
										; However, on most CRT's usually 192 (+/- a few) scanlines are visible so the thickness of the
										; boarder would look the same all around. For this, we're not even going to use VBLANK.
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

BORDERCOLOR		equ 	#$9A
BORDERHEIGHT	equ		#8				; How many scan lines are our top and bottom borders

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

				lda		#BORDERCOLOR			
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
				sta		VSYNC

				; -------------------------- Additional 37 scanlines of vertical blank ------------

				lda    	#%11111111		; Solid line of pixels
				sta    	PF0				; Set them in all the PF# registers
				sta 	PF1
				sta    	PF2	

				ldx 	#0 					
				lda 	#0
lvblank:		sta 	WSYNC
				inx
				cpx 	#37				; 37 scanlines of vertical blank
				bne 	lvblank
				
				; --------------------------- 192 lines of drawfield ------------------------------

    			ldx 	#0 					
drawfield:		cpx		#BORDERHEIGHT-1	; Borderheight-1 will be interpreted by the assembler (-1 because the index starts at 0)
				beq		borderwalls

				cpx 	#192-BORDERHEIGHT	; will be interpreted by the assembler
				beq		borderbottom

				jmp 	borderdone

borderbottom:  	lda		#%11111111		; Solid row of pixels for all PF# registers
				sta 	PF0
				sta		PF1
				sta		PF2				

				jmp 	borderdone

borderwalls:	lda     #%00010000		; Set the first pixel of PF0. Uses the 4 hight bits and rendered in reverse.
				sta     PF0				; Set PF0 register
				lda		#%00000000		; Clear the PF1-2 registers to have an empty middle
				sta 	PF1
				sta     PF2	

borderdone:		sta 	WSYNC
    			inx  
				cpx 	#192
				bne 	drawfield

				; -------------------------- 30 scanlines of overscan -----------------------------

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
				.word reset          	; NMI
				.word reset          	; RESET
				.word reset          	; IRQ

				; -------------------------- End of main segment ----------------------------------
