; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc

; DATA ---------------------------------------------------------------

include isetCB.inc

; --------------------------------------------------------------------


code32          ends
                end


