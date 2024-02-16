				processor 6502				; -----------------------------------------------------
											; Special01: 125th Subscriber - Asymmetrical Playfield
				include	 "vcs.h"			;   
				include  "macro.h"			; Demonstrates a basic asymmetrical playfield
                                            ; 
                                            ; This Episode on Youtube - https://youtu.be/3SIfWrnCjpQ
                                            ;
											; Become a Patron - https://patreon.com/8blit
											; 8blit Merch - https://8blit.myspreadshop.com/
											; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
											; Follow on Facebook - https://www.facebook.com/8Blit
											; Follow on Instagram - https://www.instagram.com/8blit
											; Visit the Website - https://www.8blit.com 
                   	            			;
                       	        			; Email - 8blit0@gmail.com


COLPF = #$46                                ; Play field static color
ANIMDELAY = #180                            ; Frames between color change
COLMAXINDEX = #14                           ; Total number of colors in the data

				seg.u	vars				; uninitialized segment 
				org		$80

pf_index		ds 1                        ; current index we're reading for the pf data
pf_count		ds 1                        ; number of scanlines left in the pf segment
anim_count      ds 1                        ; number of frames left to display current color
col_index       ds 1                        ; current index of the color we're displaying

				seg		main				; start of main segment
				org 	$F000


reset:			CLEAN_START					; macro included in macro.h file

                lda     #1                  ; (2) start with one because going into the frame we're going to decrement
                sta     col_index           ; (3)
                sta     anim_count          ; (3)

				lda 	#COLPF				; (2)
                sta 	COLUPF				; (3) set the playfield color

				lda		#%10001011			; (2) stripped line
				sta		GRP0				; (3) graphic Player 0 
				lda 	#%11110000			; (2) set the horizontal movement player 0 (HMP0) register to adjust the position of
				sta		HMP0				; (3) 

				lda		#%11010001			; (2) stripped line
				sta		GRP1				; (3) graphic Player 1                 
				lda 	#%00100000			; (2) set the horizontal movement player 1 (HMP0) register to adjust the position of
				sta		HMP1				; (3) 

                lda     #%00000010          ; (2) enaable
                sta     ENAM0               ; (3) missle 0
                sta     ENAM1               ; (3) missle 1

                lda     #%00010000          ; (2) move left by 1
                sta     HMM0                ; (3) apply move to missle 0
                lda     #%00110000          ; (2) move left by 3
                sta     HMM1                ; (3) apply move to missle 1

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

				ldx 	#35 				; (2)	
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
				dex							; (2) decrement x by 1
				bne 	lvblank				; (2/3) branch if not equal x != 37

				sta 	HMOVE				; (3) horizontal move. this will move ALL the player, missle, and ball graphics at the same time
											; HMOVE needs to execute during horizontal blanking so it should be done immediatly following 
											; a WSYNC. Additionally, any of the horizontal movement registers should not be modified within at least
											; 24 machine cycles after an HMOVE. 

                dec     anim_count          ; (5) 
                bne     continuecount       ; (2/3) branch is index is NOT 0

                lda     #ANIMDELAY          ; (2)
                sta     anim_count          ; (3) reset anim_count

                dec     col_index           ; (5)
                bne     positiveindex       ; (2/3) branch if index is NOT 0

                ldy     #COLMAXINDEX        ; (2)
                sty     col_index           ; (3) reset color index

positiveindex:

                ldy     col_index           ; (2) get color index
                ldx     pcolors,y           ; (2) get the color at the specified index
                stx		COLUBK              ; (3) set background color
                stx     COLUP0              ; (3) set player 0 color
                stx     COLUP1              ; (3) set player 1 color

continuecount:

                sta 	WSYNC               ; (3)
        				; 76543210
				lda     #%00000000			; (2) set D1 to 0 to end VBLANK
				sta     VBLANK				; (3) turn on the beam
                
		        ldy     #0                  ; (2) start playfield index at 0
		        sty     pf_index            ; (3) which index in the pf data
		        sty     pf_count            ; (3) which segment of playfield we're currently on
                inc     pf_count            ; (5) start on the first segment

                sta     WSYNC               ; (3)

kernel:		

		        ; do we need to draw a line?

		        dec     pf_count            ; (5)
                beq     newsegment          ; (2/3) branch if 0

                lda     pf_index            ; (2) get the current index
                sbc     #2                  ; (2) move back 2 spaces
                tay                         ; (2)

                jmp     continuesegment     ; (3)

newsegment:     

		        lda     pf_0,y              ; (4) get how many lines in the segment
		        beq     pfdone              ; (2) there are no more lines to draw

                sta     pf_count	        ; (3) keep a running count of lines remaining
                iny                         ; (2)

continuesegment: 

                sta     WSYNC               ; (3)      
        
                ; left side

                lda     #0                  ; (2) load PF0
                sta     PF0                 ; (3)                   
                lda     pf_1,y              ; (4) load PF1
                sta     PF1                 ; (3)                   
                lda     pf_2,y              ; (4) load PF2
                sta     PF2                 ; (3)                   
                iny                         ; (2)

                ; right side
                lda     pf_0,y              ; (4) load PF0
                sta     PF0                 ; (3)             
                lda     pf_1,y              ; (4) load PF1    
                iny                         ; (2)
        		sty     pf_index            ; (3) save the current index
                sta     PF1                 ; (3)             
                lda     #0                  ; (2) load PF2
                nop
                nop
                sta     PF2                 ; (3)              
                
		        jmp     kernel		        ; (3)

pfdone:

                sta 	WSYNC

				        ; 76543210
				lda     #%00000010			; (2) set D1 = 1 to initiate VBLANK 
				sta     VBLANK				; (3) turn off the beam                 


				ldx 	#37			        ; (2)
overscan:       sta 	WSYNC				; (3)
				dex							; (2)
				bne 	overscan			; (2/3)
										
				jmp 	nextframe			; (3) jump back up to start the next frame

                align $100; 

pcolors
    .byte #$1E, #$2E, #$3E, #$4E, #$5E, #$6E, #$7E, #$8E, #$9E, #$AE, #$BE, #$CE, #$DE, #$EE, #$FE

; pf_0 in reverse order

pf_0            ;  left     right  
    .byte 38, %00000000, %00000000
    .byte 15, %00000000, %00000000
    .byte 15, %00000000, %00110000
    .byte 15, %00000000, %00110000
    .byte 15, %00000000, %00000000
    .byte 15, %00000000, %00000000
    .byte 15, %00000000, %00000000
    .byte 15, %00000000, %00110000
    .byte 38, %00000000, %00000000
    .byte 0

pf_1       ;  left     right  
    .byte 60, %00000000, %00000000
    .byte 15, %00001100, %01111111
    .byte 15, %00011100, %01100000
    .byte 15, %00001100, %01100000
    .byte 15, %00001100, %00011100
    .byte 15, %00001100, %00000011
    .byte 15, %00001100, %00000011
    .byte 15, %00011110, %01111100
    .byte 60, %00000000, %00000000
    .byte 0        

; pf_2 in reverse order 
 
pf_2           ;  left     right 
    .byte 0, %00000000, %00000000
    .byte 0, %11110000, %00000000
    .byte 0, %00001100, %00000000
    .byte 0, %00000000, %00000000
    .byte 0, %11000000, %00000000
    .byte 0, %00110000, %00000000
    .byte 0, %00001100, %00000000
    .byte 0, %11111100, %00000000
    .byte 0, %00000000, %00000000

     
				org 	$FFFA				
	
irq:
				.word reset          		; NMI  ($FFFA)
				.word reset          		; RESET ($FFFC)
				.word reset          		; IRQ ($FFFE)


