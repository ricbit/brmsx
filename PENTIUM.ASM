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

public pentiumfound

public detect_cpu
public start_counter
public end_counter

; DATA ---------------------------------------------------------------

align 4

pentiumfound    dd      0

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
                cmp     eax,5
                jb      _ret
                mov     pentiumfound,1
                ret

; start_counter ------------------------------------------------------
; this function starts a counter using the tsc
; enter eax=counter

start_counter:
                cmp     pentiumfound,1
                jne     _ret
                push    esi edx
                mov     esi,eax
                rdtsc
                mov     [esi],eax
                mov     [esi+4],edx
                pop     edx esi
                ret

; end_counter --------------------------------------------------------
; this function ends a counter using the tsc
; enter eax=counter

end_counter:
                cmp     pentiumfound,1
                jne     _ret
                push    esi edx
                mov     esi,eax
                rdtsc
                sub     eax,[esi]
                sbb     edx,[esi+4]
                mov     [esi],eax
                mov     [esi+4],edx
                pop     edx esi
                ret

code32          ends
                end


