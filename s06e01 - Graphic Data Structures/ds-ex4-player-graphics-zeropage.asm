; S06E01 Optimizing Atari 2600 Data Structures for Graphics - Example 4
;
; The Atari 2600 is severely limited in resources, so optimizing your data structures so you can
; draw graphics in tight RAM/ROM constraints within only 76 machine cycles per scanline is
; critical. This episode covers the foundational basics of Atari 2600 kernel development that
; developers can build upon for their own kernels.
;
; This version builds on the pointer technique shown in Example 3. Instead of reading graphics
; directly from pointer tables during drawing, we first copy the sprite data into zero-page RAM,
; then use those zero-page locations as the source when rendering during vout.
;
; This Episode on Youtube - https://youtu.be/jjPdUFzuI40
;
; Become a Patron - https://patreon.com/8blit
; Subscribe to 8Blit - https://www.youtube.com/8blit?sub_confirmation=1
; 8blit Merch - https://8blit.myspreadshop.com/
; Join us on Discord - https://discord.gg/KD3ff9qMR7
; Visit the Website - https://www.8blit.com

                 processor 6502

                 include "vcs.h"
                 include "macro.h"

; constants
GRCOLP0          equ 44                 ; player 0 color
GRCOLP1          equ 66                 ; player 1 color
GRHEIGHT         equ 10                 ; player graphics height
VOUTTOP          equ 84                 ; top spacer
VOUTBOTTOM       equ 85                 ; bottom spacer

MOVE_FRAMES      equ 67
PAUSE_FRAMES     equ 60

                 seg.u zeropage
                 org $80

zp_gfx0          ds GRHEIGHT+1          ; player 0 graphic buffer in zero page
zp_gfx1          ds GRHEIGHT+1          ; player 1 graphic buffer in zero page

player0_ptr      ds 2                   ; pointer to player 0 graphic in rom
player1_ptr      ds 2                   ; pointer to player 1 graphic in rom

frame_count0     ds 1                   ; 0-4 counter for player 0
frame_count1     ds 1                   ; 0-4 counter for player 1

current_frame0   ds 1                   ; 0-4 walking, 5 standing
current_frame1   ds 1

last_frame0      ds 1
last_frame1      ds 1

motion_timer     ds 1

                 seg rom
                 org $f000

reset            CLEAN_START

                 lda #30
                 ldx #0
                 jsr Pos_x              ; horizontal placement of player 0

                 lda #60
                 ldx #1
                 jsr Pos_x              ; horizontal placement of player 1

                 sta WSYNC
                 sta HMOVE              ; lock them in

                 ; Start with different walking frames for offset animation
                 lda #0
                 sta current_frame0     ; Player 0 starts at frame 0
                 lda #2                 ; Player 1 starts at frame 2 → nice alternating walk
                 sta current_frame1

                 lda #0
                 sta frame_count0
                 sta frame_count1
                 sta motion_timer
                 sta last_frame0
                 sta last_frame1

                 jsr LoadGraphicsToZP   ; initial load

frame            VERTICAL_SYNC
                 ldx #(37 * 76) / 64
                 stx TIM64T

                 lda #GRCOLP0
                 sta COLUP0
                 lda #GRCOLP1
                 sta COLUP1

                 lda #101
                 sta NUSIZ0
                 sta NUSIZ1

                 ; reflect during left movement
                 lda motion_timer
                 cmp #(MOVE_FRAMES + PAUSE_FRAMES)
                 bcc .no_reflect
                 lda #$08
                 jmp .set_reflect
.no_reflect      lda #$00
.set_reflect     sta REFP0
                 sta REFP1

                 ; horizontal motion
                 lda motion_timer
                 cmp #MOVE_FRAMES
                 bcc .move_right
                 cmp #(MOVE_FRAMES + PAUSE_FRAMES)
                 bcc .pause
                 cmp #(MOVE_FRAMES + PAUSE_FRAMES + MOVE_FRAMES)
                 bcc .move_left
.pause           lda #$00
                 jmp .set_motion
.move_right      lda #$F0
                 jmp .set_motion
.move_left       lda #$10
.set_motion      sta HMP0
                 sta HMP1

                 sta WSYNC
                 sta HMOVE

                 ; ----- Phase detection -----
                 lda motion_timer
                 cmp #MOVE_FRAMES
                 bcc .walking
                 lda motion_timer
                 sec
                 sbc #(MOVE_FRAMES + PAUSE_FRAMES)
                 cmp #MOVE_FRAMES
                 bcc .walking
                 jmp .standing

.walking
                 ; Rrset each player if coming from standing
                 lda current_frame0
                 cmp #5
                 bne .no_reset_p0
                 lda #0
                 sta current_frame0
                 sta frame_count0
.no_reset_p0

                 lda current_frame1
                 cmp #5
                 bne .no_reset_p1
                 lda #2                 ; restart player 1 at offset frame
                 sta current_frame1
                 lda #0
                 sta frame_count1
.no_reset_p1

                 ; Independent animation for Player 0
                 inc frame_count0
                 lda frame_count0
                 cmp #5
                 bcc .anim_p1
                 lda #0
                 sta frame_count0
                 inc current_frame0
                 lda current_frame0
                 cmp #5
                 bne .anim_p1
                 lda #0
                 sta current_frame0

.anim_p1         ; Independent animation for Player 1
                 inc frame_count1
                 lda frame_count1
                 cmp #5
                 bcc .check_load
                 lda #0
                 sta frame_count1
                 inc current_frame1
                 lda current_frame1
                 cmp #5
                 bne .check_load
                 lda #0
                 sta current_frame1

                 jmp .check_load

.standing
                 lda #5
                 sta current_frame0
                 sta current_frame1

.check_load
                 lda current_frame0
                 cmp last_frame0
                 bne .load_needed
                 lda current_frame1
                 cmp last_frame1
                 beq .no_load

.load_needed     jsr LoadGraphicsToZP
                 lda current_frame0
                 sta last_frame0
                 lda current_frame1
                 sta last_frame1

.no_load

vblank           lda INTIM              ; burn any unused cycles on the timer
                 bne vblank

                 sta WSYNC
                 lda #%00000000
                 sta VBLANK

                 ldy #VOUTTOP
top_blank        sta WSYNC
                 dey
                 bpl top_blank

                 ldy #GRHEIGHT
draw             lda zp_gfx0,y
                 sta GRP0
                 lda zp_gfx1,y
                 sta GRP1
                 sta WSYNC
                 sta WSYNC
                 dey
                 bpl draw

                 ldy #VOUTBOTTOM
bottom_blank     sta WSYNC
                 dey
                 bpl bottom_blank

                 ; overscan
                 lda #%00000010
                 sta VBLANK
                 ldx #(30 * 76) / 64
                 stx TIM64T

overscan_loop    lda INTIM
                 bne overscan_loop

                 ; timer update
                 inc motion_timer
                 lda motion_timer
                 cmp #(2 * (MOVE_FRAMES + PAUSE_FRAMES))
                 bne .no_wrap
                 lda #0
                 sta motion_timer
.no_wrap

                 jmp frame

; --------------------------------------------------
LoadGraphicsToZP SUBROUTINE
                 ldx current_frame0
                 lda frame_ptrs_lo,x
                 sta player0_ptr
                 lda frame_ptrs_hi,x
                 sta player0_ptr+1

                 ldy #GRHEIGHT
.copy0           lda (player0_ptr),y
                 sta zp_gfx0,y
                 dey
                 bpl .copy0

                 ldx current_frame1
                 lda frame_ptrs_lo,x
                 sta player1_ptr
                 lda frame_ptrs_hi,x
                 sta player1_ptr+1

                 ldy #GRHEIGHT
.copy1           lda (player1_ptr),y
                 sta zp_gfx1,y
                 dey
                 bpl .copy1

                 rts

Pos_x:           SUBROUTINE
                 sta WSYNC
                 sec
.loop            sbc #15
                 bcs .loop
                 eor #7
                 asl
                 asl
                 asl
                 asl
                 sta RESP0,x
                 sta HMP0,x
                 rts

; Graphics data unchanged
player_frame1    .byte %0
                 .byte %00000100
                 .byte %01001001
                 .byte %00101010
                 .byte %00011100
                 .byte %00011100
                 .byte %00110100
                 .byte %01111110
                 .byte %01101010
                 .byte %00111110
                 .byte %00011100

player_frame2    .byte %0
                 .byte %10010000
                 .byte %01001001
                 .byte %00101010
                 .byte %00111100
                 .byte %00011100
                 .byte %00110100
                 .byte %01111110
                 .byte %01101010
                 .byte %00111110
                 .byte %00011100

player_frame3    .byte %0
                 .byte %10000001
                 .byte %01010010
                 .byte %00101010
                 .byte %00111100
                 .byte %00110100
                 .byte %01111110
                 .byte %01101010
                 .byte %00111110
                 .byte %00011100
                 .byte %00000000

player_frame4    .byte %0
                 .byte %10000001
                 .byte %01000010
                 .byte %00101010
                 .byte %00111100
                 .byte %00011110
                 .byte %00011010
                 .byte %00111111
                 .byte %00110101
                 .byte %00011111
                 .byte %00001110

player_frame5    .byte %0
                 .byte %00000010
                 .byte %10001010
                 .byte %01001010
                 .byte %00111100
                 .byte %00011100
                 .byte %00110100
                 .byte %01111110
                 .byte %01101010
                 .byte %00111110
                 .byte %00011100

player_frame6    .byte %0
                 .byte %01010001
                 .byte %01001010
                 .byte %00101010
                 .byte %00011100
                 .byte %00011100
                 .byte %00110110
                 .byte %01111111
                 .byte %01101011
                 .byte %00111110
                 .byte %00011100

frame_ptrs_lo    .byte <player_frame1, <player_frame2, <player_frame3
                 .byte <player_frame4, <player_frame5, <player_frame6

frame_ptrs_hi    .byte >player_frame1, >player_frame2, >player_frame3
                 .byte >player_frame4, >player_frame5, >player_frame6

                 org $fffa
                 .word reset
                 .word reset
                 .word reset
