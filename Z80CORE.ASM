; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80CORE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include vdp.inc
include io.inc
include bit.inc
include fetch.inc

extrn   iset:dword
extrn   start_counter: near
extrn   end_counter: near

public emulate
public emulate_break
public emulate_histogr

; DATA ---------------------------------------------------------------

; --------------------------------------------------------------------

; emulate ------------------------------------------------------------

BREAK           EQU     0
NOBREAK         EQU     1
TRAP            EQU     2
HISTOGRAM       EQU     3

NORMAL          EQU     0
FAST            EQU     1       
TURBO           EQU     2       

JUMP            macro   jump,jpoint,emtype,brtype

                jump    emtype&_&brtype&_&jpoint

                endm

EMULABEL        macro   point,emtype,brtype

                emtype&_&brtype&_&point&:

                endm

EMULATE         macro   emtype,brtype

                xor     eax,eax
                xor     ecx,ecx
                mov     error,eax
                mov     exit_now,eax
                mov     interrupt,eax
                mov     firstscreen,1
                mov     ebp,clockcounter
                mov     clocksleft,ebp  
                movzx   edi,regpc
                movzx   edx,regaf

EMULABEL        loop,emtype,brtype

                ;and     edi,0ffffh
                
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                JUMP    je,exit,emtype,brtype
                endif

                FETCHMACRO 0

                if      brtype EQ HISTOGRAM
                inc     dword ptr [offset histogr+eax*4]
                endif

                inc     rcounter
                call    [offset iset + eax*4]
                
                if      (emtype EQ FAST)
                  cmp   interrupt,1
                  JUMP  je,interrupt,emtype,brtype
                  JUMP  jmp,loop,emtype,brtype
                else
                  cmp   ebp,0
                  JUMP  jg,loop,emtype,brtype
                endif

                if      (brtype EQ TRAP)
                mov     interrupt,1
                mov     exit_now,1
                endif

                cmp     fakeirq,1
                JUMP    je,fakeirq,emtype,brtype

                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                
                call    compose_sound
                
                xor     eax,eax
                
                if      emtype EQ NORMAL
                call    synch_emulation
                endif

EMULABEL        interrupt,emtype,brtype

                pushad
                call    check_mouse

                if      (emtype EQ TURBO)
                
                cmp     interrupt,1
                JUMP    jne,turbo_skip,emtype,brtype
                call    process_frame
EMULABEL        turbo_skip,emtype,brtype
                
                else
                call    process_frame
                endif
                
                popad
                
                ; must be called without pushads
                call    z80paused

                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax

                add     ebp,TC
                ;mov     ebp,TC
                call    checkpsg
                mov     interrupt,0
                
                cmp     error,1
                JUMP    je,exit,emtype,brtype
                cmp     exit_now,1
                JUMP    je,exit,emtype,brtype
                
                pushad
                call    set_keyboard_leds
                call    check_joystick
                call    check_client
                popad
                
                test    byte ptr [vdpregs+1],00100000b
                JUMP    jz,vdpdisabled,emtype,brtype
                
                test    vdpstatus,BIT_7
                JUMP    jnz,loop,emtype,brtype
                
                call    set_vdp_interrupt
                
                mov     iline,1
                cmp     iff1,1
                JUMP    jne,loop,emtype,brtype
                
                mov     iff1,0 
                mov     fakeirq,0
                inc     rcounter
                call    z80_interrupt
                JUMP    jmp,loop,emtype,brtype

EMULABEL        exit,emtype,brtype

                mov     regpc,di
                mov     regaf,dx
                mov     clockcounter,ebp
                ret

EMULABEL        fakeirq,emtype,brtype

                mov     eax,0
                mov     ebp,clocksleft
                ;
                ;
                mov     fakeirq,0
                mov     iff1,0
                inc     rcounter
                call    z80_interrupt
                JUMP    jmp,loop,emtype,brtype

EMULABEL        vdpdisabled,emtype,brtype

                call    set_vdp_interrupt
                JUMP    jmp,loop,emtype,brtype
                
                endm

; emulate ------------------------------------------------------------
; starts emulation, stop with any error

emulate:        
                cmp     emulatemode,NORMAL
                jne     emulate1
                EMULATE NORMAL,NOBREAK
emulate1:       cmp     emulatemode,FAST
                jne     emulate2
                EMULATE FAST,NOBREAK
emulate2:       EMULATE TURBO,NOBREAK

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:        
                cmp     emulatemode,NORMAL
                jne     emulate1_break
                EMULATE NORMAL,BREAK
emulate1_break: cmp     emulatemode,FAST
                jne     emulate2_break
                EMULATE FAST,BREAK
emulate2_break: EMULATE TURBO,BREAK

; emulate_trap -------------------------------------------------------
; starts emulation with trap, stop with any error

emulate_trap:        
                cmp     emulatemode,NORMAL
                jne     emulate1_trap
                EMULATE NORMAL,TRAP
emulate1_trap:  cmp     emulatemode,FAST
                jne     emulate2_trap
                EMULATE FAST,TRAP
emulate2_trap:  EMULATE TURBO,TRAP

; emulate_histogr ----------------------------------------------------
; starts emulation with histogram evaluation, stop with any error

emulate_histogr:        
                cmp     emulatemode,NORMAL
                jne     emulate1_histogr
                EMULATE NORMAL,HISTOGRAM
emulate1_histogr:  
                cmp     emulatemode,FAST
                jne     emulate2_histogr
                EMULATE FAST,HISTOGRAM
emulate2_histogr:  
                EMULATE TURBO,HISTOGRAM



code32          ends
                end


