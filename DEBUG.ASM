; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97
; module DEBUG

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include io.inc
include z80.inc
include msx.inc
include pentium.inc

extrn msxrom:near

public debug
public showreg

; DATA ---------------------------------------------------------------

tabregaf        db      'AF=$'
tabregbc        db      ' BC=$'
tabregde        db      ' DE=$'
tabreghl        db      ' HL=$'
tabregsp        db      ' SP=$'
tabregpc        db      ' PC=$'
tabspace        db      ' $'
tabprompt       db      '> $'

; showreg ------------------------------------------------------------
; show the contents of Z80 registers

showreg:
                pushad

                mov     eax,offset tabregaf
                call    printmsg
                movzx   eax,regaf
                call    printhex4
                
                mov     eax,offset tabregbc
                call    printmsg
                movzx   eax,regbc
                call    printhex4

                mov     eax,offset tabregde
                call    printmsg
                movzx   eax,regde
                call    printhex4

                mov     eax,offset tabreghl
                call    printmsg
                movzx   eax,reghl
                call    printhex4

                mov     eax,offset tabregsp
                call    printmsg
                movzx   eax,regsp
                call    printhex4

                mov     eax,offset tabregpc
                call    printmsg
                movzx   eax,regpc
                call    printhex4

                call    crlf
                call    crlf

                movzx   eax,regpc
                call    printhex4
                mov     eax,offset tabspace
                call    printmsg
                mov     eax,0
                mov     ecx,0
                movzx   edi,regpc
                call    print
                call    crlf

                popad
                ret

; dumpmem ------------------------------------------------------------
; show a dump of a region of memory pointed by eax
; in    eax=pointer to msx mem

dumpmem:
                push    eax
                mov     edi,eax
                call    printhex4
                mov     eax,offset tabspace
                call    printmsg

                mov     ecx,16
dumpmem1:       call    fetch
                call    printhex2
                mov     eax,offset tabspace
                call    printmsg
                inc     edi
                loop    dumpmem1

                pop     edi
                mov     eax,offset tabspace
                call    printmsg
                mov     ecx,16
dumpmem2:       call    fetch
                cmp     al,32
                jl      dumpmem3
                cmp     al,128
                jl      dumpmem4
dumpmem3:       mov     al,'.'
dumpmem4:       call    printasc
                inc     edi
                loop    dumpmem2
                call    crlf

                ret


; --------------------------------------------------------------------

debug:          
                call    showreg
debug_loop:                
                mov     eax,offset tabprompt                                
                call    printmsg
                call    getchar
                call    toupper
                call    printasc
                call    crlf
                cmp     al,'D'
                je      command_d      
                cmp     al,'K'
                je      command_k
                cmp     al,'V'
                je      command_v
                cmp     al,'S'
                je      command_s
                cmp     al,'B'
                je      command_b
                cmp     al,'R'
                je      command_r
                cmp     al,'T'
                je      command_t
                cmp     al,'X'
                je      command_x
                cmp     al,'P'
                je      command_p
                cmp     al,'1'
                je      command_1
                cmp     al,'2'
                je      command_2
                cmp     al,'Q'
                je      command_exit
                cmp     al,27
                je      command_exit
                jmp     debug_loop

command_d:
                call    gethex4
                pushad
                call    crlf
                popad
                call    dumpmem
                jmp     debug_loop

command_k:      
                call    turnon_kb_irq
                mov exit_now,0
                loop1:
                cmp exit_now,1
                jne loop1
                call    turnoff_kb_irq
                jmp     debug_loop

command_b:
                call    gethex4
                and     eax,0ffffh
                mov     breakpoint,eax
                call    crlf
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    emulate_break
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                call    crlf
                jmp     debug_loop

command_v:
                call    setgraphmode
                rdtsc
                push    eax
                call    render_screen0
                pop     ebx
                rdtsc
                sub     eax,ebx
                push    eax
                call    getchar
                call    settextmode
                pop     eax
                mov     ebx,eax
                shr     eax,16
                call    printhex4
                mov     eax,ebx
                call    printhex4
                call    crlf
                jmp     debug_loop

command_s:      call    setgraphmode
                call    turnon_kb_irq
                call    turnon_irq
                call    emulate
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

command_1:
                call    setgraphmode
                call    render_screen1
                call    getchar
                call    settextmode
                jmp     debug_loop

command_2:
                call    setgraphmode
                call    clear
                rdtsc
                push    eax
                call    render_screen2
                pop     ebx
                rdtsc
                sub     eax,ebx
                push    eax
                call    getchar
                call    settextmode
                pop     eax
                mov     ebx,eax
                shr     eax,16
                call    printhex4
                mov     eax,ebx
                call    printhex4
                call    crlf
                jmp     debug_loop

command_r:
                call    showreg
                jmp     debug_loop

command_x:      call    emulate
                call    crlf
                jmp     command_r

command_p:      call    gethex4
                and     eax,0ffffh
                mov     breakpoint,eax
                call    crlf
                call    emulate_echo
                jmp     debug_loop

command_t:
                movzx   edi,regpc
                movzx   edx,regaf
                mov     eax,0
                mov     ecx,0
                call    trace
                jmp     command_r

command_exit:
                ret

code32          ends
                end


