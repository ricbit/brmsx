; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PENTIUM.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pentium.inc
include pmode.inc

public detect_cpu

; DATA ---------------------------------------------------------------

; detect_cpu ---------------------------------------------------------
; this function detect the cpuid instruction
; and then use it to determine the processor type
; return eax=0 if cpuid is not found
; else return 3=386, 4=486, 5=pentium, 6=ppro

detect_cpu:
                pushfd
                pop     eax
                mov     ebx,eax
                xor     eax,200000h
                push    eax
                popfd
                pushfd
                pop     eax
                xor     eax,ebx
                jz      _ret
                xor     eax,eax
                inc     eax
                cpuid
                and     eax,0F00h
                shr     eax,8
                ret

code32          ends
                end


