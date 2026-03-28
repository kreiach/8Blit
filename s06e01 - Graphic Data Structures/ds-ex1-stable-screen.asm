; S06E01 Optimizing Atari 2600 Data Structures for Graphics - Example 1
;
; The Atari 2600 is severely limited in resources, so optimizing your data structures so you can
; draw graphics in tight RAM/ROM constraints within only 76 machine cycles per scanline is
; critical. This episode covers the foundational basics of Atari 2600 kernel development that
; developers can build upon for their own kernels.
;
; This example is a template for a stable screen. It draws nothing other than producing the
; proper number of scanlines for a NTSC CRT television.
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

                 seg.u zeropage
                 org $80

scanline         ds 1

                 seg rom
                 org $f000

reset            CLEAN_START

frame            VERTICAL_SYNC          ; start of frame of 262sl (ntsc standard)

                 ldx #(37 * 76) / 64    ; roughly 37sl
                 stx TIM64T

                 ; do all your vertical blank stuff here
                 ; ------------------------------------------------------------


vblank           lda INTIM              ; burn any unused cycles on the timer
                 bne vblank

                 sta WSYNC              ; start with a clean sl
                 ;------------------------
                 lda #%00000000         ; turn on the beam (d1 = 0)
                 sta VBLANK             ;

                 ; start of video output

                 lda #192
                 sta scanline

                 sta WSYNC              ; start on a clean scanline
                 ;------------------------

vout             ; all your visible graphics are done in here
                 ; ------------------------------------------------------------


                 sta WSYNC              ;
                 ;------------------------
                 dec scanline
                 bne vout

                 sta WSYNC              ; end on a full scanline
                 ;------------------------

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

                 org $fffa
                 .word reset            ; NMI  ($fffa)
                 .word reset            ; RESET ($fffc)
                 .word reset            ; IRQ ($fffe)

