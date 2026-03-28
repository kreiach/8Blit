; S06E01 Optimizing Atari 2600 Data Structures for Graphics - Example 2
;
; The Atari 2600 is severely limited in resources, so optimizing your data structures so you can
; draw graphics in tight RAM/ROM constraints within only 76 machine cycles per scanline is
; critical. This episode covers the foundational basics of Atari 2600 kernel development that
; developers can build upon for their own kernels.
;
; This example shows both a bottom-up and a top-down approach to drawing the player graphics.
; How you choose to define your player graphics depends heavily on how you intend to draw your
; kernel. Is the top scanline of your kernel 0, or is it the height of your kernel? A full-screen
; kernel may be 192 scanlines (the usual number of visible scanlines on an NTSC CRT).
; If it's zero, then your graphics data will probably start with the top byte being index 0. If
; you're counting down, then your bottom byte will probably be zero. That means your graphics are
; actually upside down in your code. There's a timing benefit to counting down, so many kernels
; are built this way.
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
VOUTTOTAL        equ 192                ; number of scanlines in vout
VOUTTOP          equ 84                 ; top spacer
VOUTBOTTOM       equ 84                 ; bottom spacer

                 seg.u zeropage         ; start of zero page ram
                 org $80

scanline         ds 1                   ; current scanline index

                 seg rom                ; start of read only memory (rom)
                 org $f000

reset            CLEAN_START

frame            VERTICAL_SYNC          ; start of frame of 262sl (ntsc standard)

                 ldx #(37 * 76) / 64    ; roughly 37sl
                 stx TIM64T

                 ; do all your vertical blank stuff here
                 ; ------------------------------------------------------------

                 ; give the player graphics some color
                 lda #GRCOLP0
                 sta COLUP0
                 lda #GRCOLP1
                 sta COLUP1

                 ; set the player graphics at 2x size
                 lda #101
                 sta NUSIZ0
                 sta NUSIZ1

                 lda #30                ; horizontal placement of player 0
                 ldx #0
                 jsr Pos_x

                 lda #60                ; horizontal placement of player 1
                 ldx #1
                 jsr Pos_x

                 sta HMOVE              ; lock them in

vblank           lda INTIM              ; burn any unused cycles on the timer
                 bne vblank

                 sta WSYNC              ; start with a clean sl
                 ;------------------------
                 lda #%00000000         ; turn on the beam (d1 = 0)
                 sta VBLANK             ;

                 ; start of video output

                 sta WSYNC              ; start on a clean scanline
                 ;------------------------

vout             ; all your visible graphics are done in here
                 ; ------------------------------------------------------------

                 ldy #VOUTTOP
block1           sta WSYNC
                 ;------------------------
                 dey
                 bpl block1

                 ldx #0                 ; player 1 index starts at 0 (top-down)
                 ldy #GRHEIGHT          ; player 0 index starts at height (bottom-up)
draw
                 lda player_bup,y       ; load bottom-up graphic data for player 0
                 sta GRP0
                 lda player_tdown,x     ; load top-down graphic data for player 1
                 sta GRP1

                 sta WSYNC              ; wait for end of scanline
                 ;------------------------
                 sta WSYNC              ; each line of graphic is two scanlines tall
                 ;------------------------

                 inx                    ; increment player 1 index (counting up)
                 dey                    ; decrement player 0 index (counting down)

                 bpl draw               ; continue while y >= 0 (player 0 not finished)

                 ; when we reach here, Player 0 is done (y < 0 after
                 ; the last dey). because both players have the same
                 ; height (GRHEIGHT scanlines), when y becomes -1
                 ; (from dey on y=0), x has exactly reached GRHEIGHT.
                 ;
                 ; This lets us use the branch-on-negative 'bpl'
                 ; from the 'dey' alone to control the entire loop with
                 ; no extra compare needed.
                 ;
                 ; compare the two approaches:
                 ;
                 ;   efficient (counting down with y):
                 ;       dey
                 ;       bpl draw                ; 2 bytes, 2–3 cycles
                 ;
                 ;   alternative (counting up with x only):
                 ;       inx
                 ;       cpx #GRHEIGHT           ; 2 bytes, 2 cycles
                 ;       bne draw                ; 2 bytes, 2–3 cycles
                 ;       ---------------------
                 ;       total extra: 4 bytes, 4–5 cycles per iteration
                 ;
                 ; by counting down one index and using 'bpl' (which tests the N flag set by 'dey'),
                 ; we save 2 bytes and 2–3 cycles per scanline compared to 'cpx' + 'bne'.
                 ; in a 192-line kernel, that's a significant savings in ROM and cycle time.

                 ldy #VOUTBOTTOM
block2           sta WSYNC
                 ;------------------------
                 dey
                 bpl block2

                 ; end of video output
                 ; ------------------------------------------------------------

                 lda #%00000010         ; turn off the beam (d1 = 1)
                 sta VBLANK

                 ldx #(30 * 76) / 64    ; roughly 30sl
                 stx TIM64T

                 ; do all your overscan stuff here
                 ; ------------------------------------------------------------


overscan         ldx INTIM              ; burn any unused cycles on the timer
                 bne overscan

                 jmp frame              ; end of frame, start a new one

                 ; end of rom (4k)
                 ; ------------------------------------------------------------

                 ; subroutines

                 ; -- set graphics horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
Pos_x:           SUBROUTINE
                 sta WSYNC              ; (3) start a new line
                 ;------------------------
                 sec                    ; (2) set carry flag
.loop            sbc #15                ; (2) subtract 15
                 bcs .loop              ; (2/3) branch until negative
                 eor #7                 ; (2) calculate fine off
                 asl                    ; (2)
                 asl                    ; (2)
                 asl                    ; (2)
                 asl                    ; (2)
                 sta RESP0,x            ; (3) fix coarse position
                 sta HMP0,x             ; (3) set fine off
                 rts                    ; (6) return to caller

                 ; graphic data

                 ; bottow up approach
                 ; when you're counting down the scanlines
player_bup       .byte $0
                 .byte %11000000
                 .byte %01101001
                 .byte %01101010
                 .byte %01111110
                 .byte %00111110
                 .byte %00110100
                 .byte %01111110
                 .byte %01101010
                 .byte %01111110
                 .byte %00111100

                 ; top down
                 ; when you're counting up the scanlines
player_tdown     .byte %00111100
                 .byte %01111110
                 .byte %01101010
                 .byte %01111110
                 .byte %00110100
                 .byte %00111110
                 .byte %01111110
                 .byte %01101010
                 .byte %01101001
                 .byte %11000000
                 .byte $0

                 org $fffa
                 .word reset            ; NMI  ($fffa)
                 .word reset            ; RESET ($fffc)
                 .word reset            ; IRQ ($fffe)

