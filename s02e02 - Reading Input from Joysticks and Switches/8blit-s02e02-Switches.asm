                processor 6502		; -----------------------------------------------------
                                    ; s02e02 Ex1. Inputs
                include	 "vcs.h"	;
                include  "macro.h"	; 
                                    ;
                                    ; This Episode on Youtube - https://youtu.be/h_m0Us77r04
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
                                    ; SWACNT        Port A 8bit Data Direction Register (DDR) 
                                    ;               Used to set each individual pin to Input or Output.
                                    ;               PA0 thru PA7. Bit = 0 = input. 1 = output.  
                                    ;
                                    ; SWCHA         D7  R   P0
                                    ;               D6  L   P0
                                    ;               D5  D   P0
                                    ;               D4  U   P0
                                    ;               D3  R   P1
                                    ;               D2  L   P1
                                    ;               D1  D   P1
                                    ;               D0  U   P1
                                    ;
                                    ;               1 = switch open (no movement), 0 = switch closed (movement)
                                    ;
                                    ; SWBCNT        Port B DDR (hardwired as input)
                                    ; SWCHB         
                                    ;               D7      P1 Difficulty   0= Amateur (B), 1= Pro (A) 
                                    ;               D6      P0 Difficulty   0= Amateur (B), 1= Pro (A)
                                    ;               D5-D4   not used
                                    ;               D3      Color BW    0 = B/W, 1 = color
                                    ;               D2      not used
                                    ;               D1      Game Select 0 = switch pressed
                                    ;               D0      Game Reset  0 = switch pressed
                                    ;
                                    ;
                                    ; Dumped Input Ports
                                    ;   Four, to read paddle controllers. Output of pot charges a 
                                    ;   capacitor in the console. When charges input port gos HI. 
                                    ;   Processor discharges the capacitor by writing a 1 to D7 of 
                                    ;   VBLANK then measures the time it takes to detect a logic one at that port.
                                    ;
                                    ; Latched Input Ports
                                    ;   Two ports, both enabled by writing a 1 or disabled by writing a 0 to D6 of VBLANK.
                                    ;
                                    ; INPT0         (dumped)
                                    ; INPT1         (dumped)
                                    ; INPT2         (dumped)
                                    ; INPT3         (dumped)
                                    ; INPT4         (Latched)
                                    ; INPT5         (Latched)

                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ #192            ; playfield height
OS_H            equ #28             ; overscan height
VB_H            equ #32             ; vertical blank height - VERTICAL_SYNC macro takes 3

GHOST_H         equ #9              ; ghost sprite height
GHOST_F         equ #2              ; Number of frames in the ghost animation


                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

p0_y			ds 1	 	        ; 1 byte - player 0 y pos
tp0_y           ds 1                ; 1 byte - temporary player 0 y pos
p0_x            ds 1                ; 1 byte - player 0 x pos

scanline        ds 1                ; 1 byte - current scanline

ghost_frame     ds 1                ; current frame of ghost animation
ghostPtr        ds 2    
ghostColPtr     ds 2                ; Pointer to which color palette to use

pf_02           ds 1                ; Pattern to be used for playfield
pf_1            ds 1

selectMode      ds 1                ; Store current game mode (1 solid or 2 stripped)
selDebounceTm   ds 1                ; Time left for decouncing of switch
selDebounceOn   ds 1                ; Debouncing on


                seg	main    		; start of main segment
                org $F000

reset:			CLEAN_START			; ouput: all ram registers 0

                ; set initial player position
                lda #165		    
                sta p0_y			; initial y pos of p0

                lda #80
                sta p0_x            ; initial x pos of p0

                lda #%10101010
                sta selectMode

nextframe:		VERTICAL_SYNC	    ; output: a = 0

                ldx	#VB_H 			; (2)
vblank: 		sta	WSYNC			; (3) 
                dex					; (2) decrement x by 1
                bne	vblank 		    ; (2/3) branch if not equal 

                ; set the x position 
                lda p0_x            ; load the p0 x position
                ldx #0			    ; P0
                jsr pos_x			; set the initial course position of the player 0 graphic
                sta WSYNC
                sta HMOVE	        ; gotta apply HMOVE

                ; create a pointer to the ghost graphic instead of pointing directy to it
                inc ghost_frame     ; (5)
                lda ghost_frame     ; (2)
                and #15             ; (2)
                sta ghost_frame     ; (3)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2) 

                tax                 ; (2)
                lda ghost_pLSB,x    ; (5)
                sta ghostPtr        ; (3)
                lda ghost_pMSB,x    ; (5)
                sta ghostPtr+1      ; (3)

ghost_done:     lda p0_y            ; (2)
                sta tp0_y           ; (3)

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


draw_p0:        tay                 ; (2)

                lda (ghostPtr),y    ; (5) Indirect mode, pull graphic from pointer
               
                sta WSYNC           ; (3) 
                sta GRP0            ; (3)

                dec	scanline        ; (5)
                bne kernel		    ; (2/3)

                sta WSYNC           ; (3)

                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam
                ldx #OS_H	        ; (2)
overscan:       sta WSYNC		    ; (3)

                dex				    ; (2)
                bne overscan	    ; (2/3)
             
; Reset
input:          lda #%00000001      ; (2) read reset input
                bit SWCHB
                bne switch_noreset
                jmp reset
switch_noreset: 
    
; Game Select
switch_select_chkbounced:
                lda selDebounceOn   ; (2)
                bne switch_select_decrease   ; if debounce already on then branch out

                lda #%00000010
                bit SWCHB
                bne switch_select_end

                lda #1
                sta selDebounceOn
                lda #40
                sta selDebounceTm

                asl selectMode
                bcc switch_select_solid
                inc selectMode
                
switch_select_stripped: 
                lda #%10101010
                sta PF0
                sta PF2
                lda #%01010101
                sta PF1
                jmp switch_select_end

switch_select_solid:
                lda #0
                sta PF0
                sta PF1
                sta PF2

switch_select_decrease:
                dec selDebounceTm
                bne switch_select_end
                lda #0
                sta selDebounceOn
switch_select_end:


; B/W input
                ldx #0
                lda #%00001000
                bit SWCHB
                bne switch_color
                ldx #1
switch_color:                
                lda ghost_pColLSB,x ; (5)
                sta ghostColPtr     ; (3)
                lda ghost_pColMSB,x ; (5)
                sta ghostColPtr+1   ; (3)

                ldy #2
                lda (ghostColPtr),y
                sta COLUBK

                ldy #3
                lda (ghostColPtr),y
                sta COLUPF

; Player 0 Difficulty
                ldx #0
                lda #%01000000
                bit SWCHB
                bne switch_P0Diff1
switch_P0Diff2: ; Difficulty 2
switch_P0Diff1: ; Difficulty 1       

; Player 1 Difficulty
                ldx #0
                lda #%10000000
                bit SWCHB
                bne switch_P1Diff1
switch_P1Diff2: ; Difficulty 2
switch_P1Diff1: ; Difficulty 1       

; Read button input
                ldy #0               ; color index set to default yellow
                bit INPT4            ; check D7 of INPT4
                bmi button_nopress   ; branch if minus. D7 will me 0 is button is pressed
                ldy #1
button_nopress: 
                lda (ghostColPtr),y
                sta COLUP0          ; set the P0 color                

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


ghost_bw:       .byte #$08          ; lightest gray
                .byte #$02          ; darker gray
                .byte #$0C          ; mid gray
                .byte #$0E          ; light gray

ghost_color:    .byte #$1E          ; Bright Yellow
                .byte #$42          ; Dark Red
                .byte #$98          ; Mid Blue
                .byte #$AE          ; Bright Blue

ghost_pColLSB:  .byte <ghost_color  ; LSB
                .byte <ghost_bw

ghost_pColMSB:  .byte >ghost_color  ; MSB
                .byte >ghost_bw

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

ghost_pLSB:     .byte <ghost_f0     ; LSB
                .byte <ghost_f1

ghost_pMSB:     .byte >ghost_f0     ; MSB
                .byte >ghost_f1  

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)


