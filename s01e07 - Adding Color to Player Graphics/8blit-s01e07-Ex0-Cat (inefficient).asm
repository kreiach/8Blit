                processor 6502				; s01e07 Ex0. A colorful cat in two dimensions with an inefficient drawing routine
                include	 "vcs.h"			;
                include  "macro.h"			; Draw a cat sprite at a specific location on the screen and apply color
                                            ;
                                            ; This Episode on Youtube - https://youtu.be/T-6WY-JdjFo
                                            ;
                                            ; Become a Patron - https://patreon.com/8blit
                                            ; Subscribe to 8Blit - https://www.youtube.com/8blit
                                            ; Follow on Facebook - https://www.facebook.com/8Blit
                                            ; Follow on Instagram - https://www.instagram.com/8blit
                                            ; Tweet on Twitter - https://twitter.com/8blit0
                                            ; Visit the Website - https://www.8blit.com 
                                            ;
                                            ; Email - 8blit0@gmail.com

pf_h            equ     #192                ; playfield height
os_h            equ     #34                 ; overscan height
vb_h            equ     #37                 ; vertical blank height

cat_h           equ     #11                 ; cat sprite height

bnd_y_t         equ     #0                  ; top y bound of the screen
cat_bnd_y_b     equ     #bnd_y_t-#pf_h+#cat_h ; bottom y bound of the screen

                seg.u	vars				; uninitialized segment
                org		$80

p0_y			ds      1	 				; 1 byte - player 0 y pos
p0_i            ds      1
scanline        ds      1                   ; 1 byte - current scanline

                seg		main				; start of main segment
                org 	$F000


reset:			CLEAN_START					; macro included in macro.h file

                lda		#$9A			    ; (2)
                sta		COLUBK				; (3) set the PF color

                lda		#100	            ; (2) 
                sta 	p0_y				; (3) initial y pos of p0

                lda     #80                 ; (2) a = hpos
                ldx 	#0			        ; (2) x = object 0-1 player, 2-3 missiles, 4 ball
                jsr 	pos_x				; (6) set the initial course position of the player 0 graphic

nextframe:		VERTICAL_SYNC				; macro included in macro.h file

                ldx 	#vb_h 				; (2)
lvblank:		sta 	WSYNC				; (3) each scanline is 228 color clocks, 76 machine cycles
                dex							; (2) decrement x by 1
                bne 	lvblank				; (2/3) branch if not equal x != 37

                lda     #%00000000			; (2) set D1 to 0 to end VBLANK
                sta		WSYNC				; (3)
                sta     VBLANK				; (3) turn on the beam

                lda 	#pf_h			    ; (2)
                sta     scanline

        
                lda     #0                  ; (2)
                sta     p0_i                ; (3)
kernel:		  
                ldx     #0                  ; (2) default to no pixels
                lda     scanline            ; (2)

                sec                         ; (2) set carry flag
                sbc     p0_y                ; (3)
                beq     p0_nodraw           ; (2/3) register less than or equal to data

                sbc     #cat_h              ; (2)
                bcs     p0_nodraw           ; (2/3)

                ldy     p0_i                ; (2)
                ldx     cat_a,y             ; (4)
                inc     p0_i                ; (5)            
p0_nodraw:
                sta     WSYNC               ; (3) 
                stx     GRP0                ; (2)
        
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

; cat sprite bottom->top, left->right
cat_a                                       ;10 bytes
                .byte %00000010   
                .byte %00000100
                .byte %00000100
                .byte %00110010
                .byte %00111110
                .byte %00111110
                .byte %00011110
                .byte %00011110
                .byte %00010010
                .byte %00010010          

                org 	$FFFA


irq:
                .word reset          		; NMI  ($FFFA)
                .word reset          		; RESET ($FFFC)
                .word reset          		; IRQ ($FFFE)


