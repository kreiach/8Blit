        processor 6502          ; S03E04 Regions (before 2)
                                ;
        include	"vcs.h"	        ; Move the timings into a preprocessor variable so they're easily editable
        include "macro.h"       ;  
                                ;
                                ; This Episode on Youtube - https://youtu.be/o9wz3pdFU6o
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
; timing
VBLANKTIME      = 43            ; the number of 64 intervals for the vertical blank       
VOUTLINES       = 96            ; height of our 2lk kernel playfield 192/2
OVERSCANTIME    = 35            ; the number of 64 intervals for the overscan
PFSEGHEIGHT     = %00001111     ; pf segements are 4 kernel lines in height

; color
RED             = $46
ORANGE          = $3c
YELLOW          = $1e
BLUE            = $a6

        seg.u	vars	        ; uninitialized segment
        org	$80                 ; origin set at base of ram 

; define variables
pf_segment      ds 1
pf_segindex     ds 1
b_y             ds 2            ; ball y pos
b_bearing       ds 2            ; (0-15) 16 angles 22.5 deg apart
b_bearing_old   ds 2            ; holds the original bearing (direction) of the ball before bounce
collision_count ds 2            ; collision count
pf_count        ds 1            ; playfield index
p_collision     ds 1            ; current players collision register value
r_seed          ds 1            ; random seed
snd_on          ds 2            ; 1 byte per audio channel - greater than 0 if sound is playing

        seg	main                ; start of main segment
        org     $F000

reset:
        CLEAN_START	            ; ouput: all ram/registers 0

        ; generate a random seed from the interval timer
        lda INTIM               ; unknown value to use as an initial random seed
        sta r_seed              

        ; set area values
        lda #%00010101          ; playfield to reflect (default behavior, not nessesary)
        sta CTRLPF
        sta VDELP0              ; draw player 0 when player 1 is drawm

soft_reset:

        ldx #0                  ; p0
        lda #80                 ; p0 horizontal position
        jsr init_object         ; p0 starting position

        inx                     ; p1
        lda #40                 ; p1 horizontal position
        jsr init_object         ; p1 starting position

        ; lock the graphic object positions
        sta WSYNC           
        sta HMOVE               ; strobe horizontal move to set fine positions  

        lda #0                  ; start on the first index of the current playfield segment to draw
        sta pf_segindex         

        ; set the game color scheme based on selected region       
        lda #RED                ; defined in build.h
        sta COLUPF 

        lda #YELLOW             ; defined in build.h
        sta COLUP0

        lda #BLUE               ; defined in build.h
        sta COLUP1

NextFrame:
	VERTICAL_SYNC	            ; output: a = 0; 3 scanlines

VerticalBlank               
        ldx #VBLANKTIME         ; defined/precalculated in build.h
        stx TIM64T              ; set 64-clock for 43 intervals. 

        ; process the sound channels to turn off volume when counter runs out
        jsr snd_process

        ; we're checking the collision between p0+pf, p1+pf, and p1+p2
        ldx #1                  ; start with p1 and work down to p0
CollisionNextObject

        ; collision detection
        lda CXP0FB,x            ; object collision with playfield?
        ora CXPPMM              ; bounce on p0+p1 collision - no reason to do for both p0 and p1 but it's a convience place
        sta p_collision 
        lda #%10000000
        and p_collision
        bne collision

        lda #0                  ; no collision, set collision count to 0
        sta collision_count,x
        jmp no_collision        ; bypass collision handling

; when a collision occures we try to reflect to a vertical bearing. If on the next frame we're still
; registering a collision then we try a horizontal bearing. If it's STILL registering a collision 
; then we reflect it back 180 degrees from the original pre-bounce bearing.

collision:
        ; a collision occured
        lda collision_count,x   ; how many times has a collision occured consecutively
        bne col_on              ; branch if collisions are already ongoing

        txa
        tay                     ; sound parameter index from sndbank_*
        jsr snd_play            ; call the subroutine to load the audio registers, use the p0/p1 value in x for channel

        lda b_bearing,x         ; get the current bearing
        sta b_bearing_old,x     ; store current b_bearing
        eor #$FF                ; reverse our bearings 
        sta b_bearing,x          
        inc b_bearing,x         ; additive reverse
        lda b_bearing,x
        and #$03                ; is bearing N,S,E,W?
        bne col_no_adj
        inc b_bearing,x         ; increment bearing by one offset to prevent continuous reflection

col_no_adj: 
        jmp collision_done

col_on: cmp #$01                ; check collision_count
	beq reverse_bearing     ; first collision in series
	cmp #$03                ; check collision_count
	bcc collision_done      ; second/third collision in series
	bne collision_done      ; more than three collisions in series
	lda b_bearing_old,x     ; retrieve pre-bounce bearing
	jmp reverse_org_bearing ; reverse bearing it 180 degrees

reverse_bearing:                ; reverse altered bearing
        lda b_bearing,x           
reverse_org_bearing:            ; reverse original bearing
        clc                     ; clear carry so it's not included in add on next instruction
	adc #$08                ; reverse bearing by 180 degrees
	sta b_bearing,x

collision_done:
        inc collision_count,x   ; increment the number of consecutive collisions
no_collision:

        ; move the ball
        lda b_bearing,x     
        and #$0F                ; strip the high nibble
        tay
        lda bearing_offsets,y   ; load the x/y offsets based on the current bearing
        sta HMP0,x              ; horizontally move the current player object
                                ; update the balls horizontal motion register which will only
                                ; use the high nibble where the x offset is stored.
        and #$0F                ; strip out the high nibble which leaves only the y offset
        sec                     ; set the carry flag
        sbc #$08                ; subtract 8 for 4bit 2's completment +/-
        clc                     ; clear carry flag so it's not used in the following add
        adc b_y,x               ; add y offset to current y position
        sta b_y,x               ; store the new y position

        dex                     ; done processing collision with current object, move on to the next p1->p0
        bpl CollisionNextObject ; when result is positive move on to p0, when negative pass through loop 

        ldy #255                ; prime for first playfield segment (kernel starts with a inc pf_segment which brings it to 0 to start)
        sty pf_segment
        ldx #VOUTLINES          ; defined in build.h
        stx pf_count            ; this is a 2 line kernel (2lk) so count is 1/2 pf height

        sta WSYNC
;--------------------------------------	

        sta HMOVE               ; set fine horizontal positioning
        sta CXCLR               ; clear all the collision registers

checktimer:
        lda INTIM               ; time remaining (or past)
        bne checktimer          ; burn remaining cycles

        lda #0	                ; D1 to 0 to end VBLANK
        sta WSYNC
;--------------------------------------	
        sta VBLANK	        ; set vertical blank off

vout:    
        lsr pf_segindex         ; 5  5 - defined in build.h (how many scanlines used for each segment. different for NTSC, PAL)
        bne skipx               ; 3  8 
        inc pf_segment          ; 5 13
        lda #PFSEGHEIGHT        ; 2 15      
        sta pf_segindex         ; 3 18
        
skipx:     
        ldy pf_segment          ; 2 20
        lda PF0_data_atari,y    ; 4 24 
        sta WSYNC               ; 3 27           
;--------------------------------------	 
      
        ; draw playfield
        sta PF0                 ; 3 29
        lda PF1_data_atari,y    ; 4 34
        sta PF1                 ; 3 37
        lda PF2_data_atari,y    ; 4 41
        sta PF2                 ; 3 44
        lda #ORANGE             ; 2 46 - defined in build.h 
        sta COLUBK              ; 3 49

        ldy #1                  ; 2 51
drawballs        
        ldx #0                  ; 2 53
        lda b_y,y               ; 4 57 - load ball y pos
        cmp pf_count            ; 2 59 - compare y pos to playfield counter
        bne noball              ; 3 62 - if it's not the same then continue with blank player graphic
        ldx p_graphic,y         ; 4 66 - ball y pos and playfield counter are same so set player graphic
noball 
        stx GRP0,y              ; 4 70 - enable current player graphic

        dey                     ; 2 72 - move on to next player graphic
        bpl drawballs           ; 2 74 - if result positive then draw next graphic which would add 75 additional cycles to the count

        sta WSYNC               ; 3 149
;--------------------------------------

        dec pf_count            ; 5 154
        bne vout                ; 3 157
        
        ; end of VOUT
        sta WSYNC               ; end kernel with a clean scan line
;--------------------------------------

        lda #$0
        sta PF0
        sta PF1
        sta PF2
        sta COLUBK
        sta GRP0
        sta GRP1
        lda #$2     	        ; set D1 = 1 to initiate VBLANK
        sta VBLANK		; turn off the beam

; ---- overscan (30 scanlines)
        ldx #OVERSCANTIME       ; defined in build.h - We'll round down, and clean up the remaining cycles with a WSYNC
        stx TIM64T              ; Set a count of 35 with 64-clock interval

        ; overscan remainder timer -----------
overscan_timer          
        ldx INTIM
        bne overscan_timer
        jmp NextFrame           ; jump back up to start the next frame

init_object
        ; a = x position, x = object	        
        sta b_y,x	        ; y pos
        jsr PositionX	        ; a = x pos, x = object (index from P0 object address)

        ; 'randomly' select an initial bearing (direction)
        jsr galois_lfsr_random  ; no need to store the seed for this one
        and #$0F                ; limit the value to 0-15
        sta b_bearing,x

        rts


; Galois 8-bit Linear Feedback Shift Registers
; https://samiam.org/blog/20130617.html
galois_lfsr_random              
        lda r_seed              ; keep calling funtion to for better entropy
        lsr                     ; shift right
        bcc noeor0              ; if carry 1, then exclusive OR the bits
        eor #$D4                ; d4 tap (11010100)
noeor0: sta r_seed
        rts

; -----------------------------------------------------------------------------
; PositionX
; A - Horizontal position of the object
; X - Object to position
;   0 - Player 0
;   1 - Player 1
;   2 - Missile 0
;   3 - Missile 1
;   4 - Ball
; -----------------------------------------------------------------------------

PositionX:          
        sec	                ;  2 +2 - set the carry flag
        sta WSYNC	        ;  3 +5 - start a new line
DivideLoop
        sbc #15		        ;  2  2 - subtract 15
	    bcs DivideLoop	;  2  4 - branch until negative
	    eor #7		;  2  6 - calculate fine offset
	    asl                 ;  2  8 - shift left
	    asl                 ;  2 10
	    asl                 ;  2 12
	    asl                 ;  2 14
	    sta HMP0,x	        ;  5 19 - set fine offset
	    sta RESP0,x	        ;  4 23 - set coarse position
	    rts		        ;  6 29 - return

; cues a sound to play. sets audio registers based on table lookup sndbank.
; parameters: x = channel (0|1), y = sound to play
snd_play:
        lda sndbank_type,y
        sta AUDC0,x             ; audio control   
        lda sndbank_vol,y
        sta AUDV0,x             ; audio volume
        lda sndbank_pitch,y
        sta AUDF0,x             ; audio frequence
        lda sndbank_len,y
        sta snd_on,x            ; len of audio in frames (>0 = sound on)
        rts

; process sound channels to turn off volume when sound length counter runs out
snd_process:
        ldx #1                  ; channel to process, start with channel 1
snd_ch     
        lda snd_on,x            ; get sound length counter for this channel
        beq snd_done            ; are we playing a sound? a>1 
        dec snd_on,x            ; yes, decrese the sound length counter for this channel
        bne snd_cont            ; did we reach the end of the sound length?
        lda #0                  ; yes
        sta AUDV0,x             ; turn off the volume for this channel 
snd_done
snd_cont
        dex                     ; do it again for channel 0
        beq snd_ch              
        rts

        align $100              ; align data

p_graphic
        .byte #%00000011        ; p0
        .byte #%00000011        ; p1

; define sounds, p0, p1
sndbank_type
        .byte $0C, $0C
sndbank_vol
        .byte $02, $02
sndbank_pitch
        .byte $0D, $0F
sndbank_len
        .byte $01, $01

                                ;index  x-move  y-move  deg     direction  
bearing_offsets                 ;------------------------------------------                                                                                            
      	.byte #%11100000        ; 0     -2       0      90.0    right
        .byte #%11100111        ; 1     -2      -2      67.5
        .byte #%11100110        ; 2     -2      -4      45.0
        .byte #%11110110        ; 3     -1      -4      22.5
      	.byte #%00000110        ; 4      0      -4      0/360   up
        .byte #%00010110        ; 5     +1      -4      337.5
        .byte #%00100110        ; 6     +2      -4      315.0
        .byte #%00100111        ; 7     +2      -2      292.5  
      	.byte #%00101000        ; 8     +2       0      270.0   left
        .byte #%00101001        ; 9     +2      +2      247.5
        .byte #%00101010        ; 10    +2      +4      225.0
        .byte #%00011010        ; 11    +1      +4      202.5
      	.byte #%00001010        ; 12     0      +4      180.0   down
        .byte #%11111010        ; 13    -1      +4      157.5
        .byte #%11101010        ; 14    -2      +4      135.0
        .byte #%11101001        ; 15    -2      +2      112.5;

        INCLUDE "playfields/pf_atari.asm"

        org $FFFA

        .word reset     	; NMI  ($FFFA)
        .word reset     	; RESET ($FFFC)
        .word reset     	; IRQ ($FFFE)