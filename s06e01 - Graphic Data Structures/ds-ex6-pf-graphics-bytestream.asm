; S06E01 Optimizing Atari 2600 Data Structures for Graphics - Example 6
;
; The Atari 2600 is severely limited in resources, so optimizing your data structures so you can
; draw graphics in tight RAM/ROM constraints within only 76 machine cycles per scanline is
; critical. This episode covers the foundational basics of Atari 2600 kernel development that
; developers can build upon for their own kernels.
;
; Expanding on example 5, this version uses several different playfield screens to animate a large
; graphicacter. Each playfield screen is accessible using pointers and an index to the ROM address
; for each graphic frame. Each frame is encoded as a tight byte stream and stored in hex format.
; Each frame of the byte stream encodes all the playfield registers in succession, from the bottom
; to the top as one data table. We pull this data and store it in zero page so it's quickly and
; easily accessible by vout.
;
; You can grab a copy of the spreadsheet used in this episode from here :
; https://docs.google.com/spreadsheets/d/1OqW7LrnDes31m5Tj24O4OwcgnnVEWINkcUMx8B-bGoA/template/preview
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
PFCOL            equ 44
VOUTTOP          equ 5
VOUTBOTTOM       equ 6
FRATE            equ 8

                 seg.u zeropage
                 org $80

graphic_ptr      ds 2                   ; pointer to the graphicacter graphic
graphic          ds 1
graphic_ram      ds graphicBuffSize     ; size of zero page buffer forcurrent graphic graphic

pf1a             ds 1                   ; left pf1
pf2a             ds 1                   ; left pf2
pf0b             ds 1                   ; right pf0
pf1b             ds 1                   ; right pf1
pf_y             ds 1

frame_count      ds 1

                 seg rom                ; start of rom
                 org $f000

reset            CLEAN_START

                 lda #PFCOL
                 sta COLUPF

                 lda #FRATE
                 sta frame_count

                 lda #4
                 sta graphic

frame            VERTICAL_SYNC
                 ldx #(37 * 76) / 64
                 stx TIM64T

                 ; Vertical Blank
                 dec frame_count
                 lda frame_count
                 bpl contframe
                 lda #FRATE
                 sta frame_count
                 dec graphic
                 lda graphic
                 bpl contframe
                 lda #4
                 sta graphic
contframe

                 jsr loadgraphic        ; jump to the graphic load routine

vblank           lda INTIM
                 bne vblank
                 sta WSYNC
                 lda #%00000000
                 sta VBLANK


                 ldy #VOUTTOP
top_blank        sty WSYNC
                 ;------------------------
                 dey
                 bpl top_blank

                 ldx #graphicRows - 1
                 stx pf_y

                 ; pre-vout prime pf0b and pf1b (right side) for first line to distribute the load
                 lda offsetgraphic,x
                 tax
                 lda graphic_ram+2,x
                 sta pf0b
                 lda graphic_ram+3,x
                 sta pf1b

                 sta WSYNC
                 ; ----------------------

vout_graphic     ; asymetrical playfield to draw the 17 lines of
                 ; playfield graphic data, repeating each line
                 ; for 7 scanlines.

                 ; for more on asymetrical playfields, refer to the following episode
                 ; https://www.youtube.com/watch?v=lUJmDX1fd18

                 ; left
                 lda #0                 ; 2   2
                 sta PF0                ; 3   5 PF0 is not populated on the left side

                 lda graphic_ram+0,x    ; 4   9
                 sta pf1a               ; 3  12
                 sta PF1                ; 3  15
                 lda graphic_ram+1,x    ; 4  19
                 sta pf2a               ; 3  22
                 sta PF2                ; 3  25
                 ; right
                 lda pf0b               ; 2  27
                 sta PF0                ; 3  30
                 lda pf1b               ; 2  32
                 nop                    ; 2  34
                 sta PF1                ; 3  37
                 nop                    ; 2  39
                 nop                    ; 2  41
                 nop                    ; 2  43
                 lda #0                 ; 2  45
                 sta PF2                ; 3  48

                 ldy #16                ; 2  50
graphicLoop
                 sta WSYNC              ; 3  53
                 ; ----------------------
                 lda #0                 ; 2   2
                 sta PF0                ; 3   5 PF0 is not populated on the left side
                 lda pf1a               ; 2   7
                 sta PF1                ; 3  10
                 lda pf2a               ; 2  12
                 sta PF2                ; 3  15
                 nop                    ; 2  17
                 nop                    ; 2  19
                 lda pf0b               ; 2  21
                 sta PF0                ; 3  24
                 nop                    ; 2  26
                 nop                    ; 2  28
                 nop                    ; 2  30
                 nop                    ; 2  32
                 nop                    ; 2  34
                 lda pf1b               ; 2  36
                 sta PF1                ; 3  39
                 lda #0                 ; 2  41
                 sta PF2                ; 3  44
                 dey                    ; 2  46
                 bpl graphicLoop        ;2/3 49

                 dec pf_y               ; 5  54
                 bmi vout_graphic_done  ;2/3 57
                 ldx pf_y               ; 2  59
                 lda offsetgraphic,x    ; 4  63
                 tax                    ; 2  65
                 lda graphic_ram+2,x    ; 4  69
                 sta pf0b               ; 3  72
                 lda graphic_ram+3,x    ; 4  76
                 sta pf1b               ; 3  79

                 jmp vout_graphic

vout_graphic_done
                 lda #0
                 sta PF0
                 sta PF1
                 sta PF2

                 ldy #VOUTBOTTOM
bottom_blank     sty WSYNC
                 ;------------------------
                 dey
                 bpl bottom_blank

                 ; Overscan
                 lda #%00000010
                 sta VBLANK
                 ldx #(30 * 76) / 64
                 stx TIM64T

overscan_loop    lda INTIM
                 bne overscan_loop

                 jmp frame

graphicCols      equ 4
graphicRows      equ 10
graphicBuffSize  equ ((graphicRows) * graphicCols)

loadgraphic      SUBROUTINE
                 ldx graphic            ; get current lgraphic
                 lda graphicLSB,x
                 sta graphic_ptr
                 lda graphicMSB,x       ; calc rom position of graphic data
                 sta graphic_ptr+1      ; set pointer to graphic data
                 ldy #graphicBuffSize-1
.load            lda (graphic_ptr),y
                 sta graphic_ram,y
                 dey
                 bpl .load
                 rts

; each frame is 10 lines of 4 PF columns, encoded one column at a time in reverse order.
;
;	example of a 3x3
;
; 	123
;   456
;   789
;
;	encoded as 789456123

; hex encoded
; -------------
frame1           hex 0000E00007C0101C00C710E000F8F00000F8F000003FE00007FFF0E007C710E000FFF0E000F8F000
frame2           hex 3838000007C0101C00C710E000FFF00000F8F000003FE00007FFF0E007C710E000FFF0E000F8F000
frame3           hex 3800001C073800E000C710E000FFF000003FE00007FFF0E007C710E000FFF0E000F8F00000000000
frame4           hex 380000E007C010E000FFF00000FFF0E000F810E000FFF0FC003FE01C00F8F0FC00C0F0E000000000
frame5           hex 38C010E007C010E000FFF00000F8F000003FE00007FFF0E007C710E000FFF0E000F8F00000000000

graphicLSB       .byte <frame5
                 .byte <frame4
                 .byte <frame3
                 .byte <frame2
                 .byte <frame1

graphicMSB       .byte >frame5
                 .byte >frame4
                 .byte >frame3
                 .byte >frame2
                 .byte >frame1


;calculates a table of offsets to locations storing the first byte of each line of graphic data
offsetgraphic
off              set 0
                 repeat graphicRows
                 .byte off
off              set off + graphicCols
                 repend

                 org $fffa
                 .word reset
                 .word reset
                 .word reset
