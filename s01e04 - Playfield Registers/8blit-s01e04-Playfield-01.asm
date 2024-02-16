				processor 6502				; s01e04 Draw the playfield on an Atari 2600
				include	 "vcs.h"			; This example uses the TIA PF0, PF1, PF2, and CTLRPF 
											; Registers to draw playfield graphics using one register at a time
											; first in normal mode, and then in mirrored
	                                        ;
    	                                    ; This Episode on Youtube - https://youtu.be/K3LcLcstZE8
        	                                ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                                   	    	;
                                   		    ; Email - 8blit0@gmail.com

PF0COL 			equ		#$38		
PF1COL	 		equ		#$B8		 
PF2COL	 		equ		#$9A		

ANISEQ		 	equ 	$80					; Animation sequence 0 = PF0, 1 = PF1, 2 = PF2, 3 = PF0-mirrored, 4 = PF1-mirrored, 5 = PF2-mirrored
CTRLPF_SHADOW 	equ		$84					; Working copy of CTRLPF register. It's write only and handles multiple functions so if we're going
											; to modify it we want to modify our clone, and they push that to the register.
ANISPEED	 	equ		120					; Speed of animation/frames per update. 1 sequence every 2 seconds.

				; ------------------------- Start of main segment ---------------------------------

				seg		main
				org 	$F000

				; ------------------------- Start of program execution ----------------------------

reset: 			ldx 	#0 					; Clear RAM and all TIA registers
				lda 	#0 
  
clear:       	sta 	0,x 				; $0 to $7F (0-127) reserved OS page zero, $80 to $FF (128-255) user zero page ram.
				inx 
				bne 	clear

				lda 	#0
				sta 	ANISEQ				; Initialize to 0
				sta 	CTRLPF_SHADOW		; Initialize to 0

				ldy 	#ANISPEED-1			; Use reg y for animation timer. Initialize with TIMETOCHANGE to trigger the first screen update. 
											; The -1 is interpreted by the compiler before execution.

				; --------------------------- Begin main loop -------------------------------------

startframe:		lda 	#0					; Start of new frame
				sta 	VBLANK				; Start of vertical blank processing
				lda 	#%0000010			; Writing a bit into the D1 vsync latch
				sta 	VSYNC 
				sta 	WSYNC
				sta 	WSYNC
				sta 	WSYNC           	; 3 scanlines of VSYNC signal
				lda 	#0
				sta	 	VSYNC

				; -------------------------- START 37 SCANLINES OF VBLANK -------------------------

				iny 						; Increment speed count by 1
				cpy 	#ANISPEED
				bne 	skipframe			; If we're not switching animation sequences then skip ahead 

				ldy 	#0					; Reset the counter

				lda 	#0					; Reset all the PF registers to clear the pf
				sta 	PF0
				sta 	PF1
				sta 	PF2

				lda 	CTRLPF_SHADOW		; Get our shadow copy of the CTRLPF register

				ldx 	ANISEQ
				cpx 	#3
				bcs 	mirrorpf			; Branch if greater than or equal to 3  (>=3)

				and 	#%11111110			; Set playfield to normal. Turn off D0 and leave all the other bits along.
				jmp 	setctrlpf

mirrorpf:		ora 	#%00000001			; Set playfield to mirrored. Turn on D0 and leave all the other bits alone.

setctrlpf:		sta 	CTRLPF_SHADOW		; Update our shadow copy of the CTRLPF register
				sta 	CTRLPF				; Apply same changes to the CTRLPF register directly

				lda 	ANISEQ				; Based on current seq, jump drawing pf
				cmp 	#0					; Animation sequence 0
				beq 	sq1					; Break if equal = 0 (=0)
				cmp 	#1					; Animation sequence 1
				beq 	sq2
				cmp 	#2					; Animation sequence 2
				beq 	sq3
				cmp 	#3					; Animation sequence 3
				beq 	sq1
				cmp 	#4					; Animation sequence 4
				beq 	sq2
				cmp 	#5					; Animation sequence 5
				beq 	sq3

sq1:			lda 	#%11110000			; The pattern we want display
				sta 	PF0					; 4 bit register, reversed
				lda 	#PF0COL
				jmp 	seqset

sq2:			lda 	#%11111111			; The pattern we want display
				sta 	PF1					; 8 bit register
				lda 	#PF1COL
				jmp 	seqset

sq3: 			lda 	#%11111111			; The pattern we want display
				sta 	PF2					; 8 bit register, reversed
				lda 	#PF2COL

seqset:			sta 	COLUPF				; Initialize the playfield color
				ldx 	ANISEQ
    			inx
				cpx 	#6
				bne 	keepseq
				ldx 	#0
	
keepseq:		stx 	ANISEQ        

				; -------------------------- 37 scanlines of vertical blank -----------------------

skipframe:		ldx 	#0 					
setvblank:  	sta 	WSYNC
				inx
				cpx 	#37					
				bne 	setvblank
				
				; --------------------------- 192 lines of drawfield ------------------------------

    			ldx 	#0 					
drawfield: 		sta 	WSYNC
    			inx  
				cpx 	#192
				bne 	drawfield

				; --------------------------- End of screen - enter blanking ----------------------

    			lda 	#%01000010 			; set D0, D6 of vblank register
    			sta 	VBLANK				    

				; -------------------------- 30 scanlines of overscan -----------------------------

				ldx 	#0					
overscan:       sta 	WSYNC
				inx
				cpx 	#30
				bne 	overscan

				; --------------------------- End of overscan -------------------------------------

				jmp 	startframe			; jump back up to start the next frame

				; --------------------------- Pad until end of main segment -----------------------

				org 	$FFFA
	
irqvectors:
				.word reset          		; NMI
				.word reset          		; RESET
				.word reset          		; IRQ

				; -------------------------- End of main segment ----------------------------------
