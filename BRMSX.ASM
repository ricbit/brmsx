; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include io.inc
include debug.inc

public _main

; DATA ---------------------------------------------------------------

msg00           db      'BrMSX 1.0',13,10
                db      'by Ricardo Bittencourt',13,10,10,'$'

; --------------------------------------------------------------------

_main:          sti
                
                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                ; enter debug mode
                call    debug

                ; exit to dos
                jmp     _exit

code32          ends
                end


