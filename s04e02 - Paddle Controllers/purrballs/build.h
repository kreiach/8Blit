VBLANKLINES     = 37         
VOUTLINES       = 88            ; height of our 2lk kernel playfield 192/2
OVERSCANLINES   = 30
PFSEGHEIGHT     = %00001111     ; pf segements are 4 kernel lines in height

; calculate timings
VBLANKTIME      = (VBLANKLINES * 76) / 64 
OVERSCANTIME    = (OVERSCANLINES * 76) / 64 
	
RED             = $46
ORANGE          = $3c
YELLOW          = $1e
BLUE            = $a6
WHITE           = $0e

