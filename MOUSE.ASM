; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: MOUSE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc

public mousedriver
public init_mouse

; DATA ---------------------------------------------------------------

mousedriver     dd      0

; init_mouse ---------------------------------------------------------
; check for mouse driver

init_mouse:
                mov     v86r_ax,0
                mov     al,33h
                int     33h
                cmp     v86r_ax,0FFFFh
                jne     _ret
                mov     mousedriver,1
                ret

code32          ends
                end


