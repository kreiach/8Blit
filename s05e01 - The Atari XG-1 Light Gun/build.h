; calculate timings
VBLANKTIME      equ (VBLANKLINES * 76) / 64 
OVERSCANTIME    equ (OVERSCANLINES * 76) / 64 
VBLANKLINES     equ 37         
VOUTLINES       equ 192            ; height of our 2lk kernel playfield 192/2
OVERSCANLINES   equ 30

