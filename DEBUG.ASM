; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: DEBUG.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include io.inc
include z80.inc
include vdp.inc
include pentium.inc
include debugsrc.inc

extrn msxrom: near
extrn pentiumfound: dword

public debug

; DATA ---------------------------------------------------------------

align 4

temp_screen     db      3840 dup (0)
tabspace        db      ' $'
tabprompt       db      '> $'
msgmega00       db      'megarom type 0 - konami 8kb',13,10,'$'
msgmega05       db      'megarom type 5 - ascii 16kb',13,10,'$'
msgpentiumonly  db      'this option requires a pentium',13,10,'$'
res320          db      '320x200$'
res256          db      '256x200$'
modenormal      db      'NORMAL$'
modefast        db      'FAST  $'
modeturbo       db      'TURBO $'
stateon         db      'ON $'
stateoff        db      'OFF$'

; COORD --------------------------------------------------------------
; convert coordinates from ASCII.EXE system to 
; the dh,dl format used by printmsgd

COORD           macro   x,y

                mov     dx,(y-1)*256+(x-1)

                endm

; clear_text ---------------------------------------------------------
; clear the text screen

clear_text:
                push    es
                mov     ax,gs
                mov     es,ax
                mov     edi,0b8000h
                mov     ecx,80*25*2/4
                rep     stosd
                pop     es
                ret

; printmsgd ----------------------------------------------------------
; print a message in dos format, 
; drawing directly in the temp buffer
; enter: dh=row, dl=column
;        eax= offset of message

printmsgd:
                movzx   edi,dh
                lea     edi,[edi+edi*4]
                shl     edi,5
                movzx   edx,dl
                lea     edi,[edi+edx*2]
                add     edi,offset temp_screen
printmsgd1:
                mov     dl,[eax]
                cmp     dl,'$'
                jz      _ret
                mov     [edi],dl
                add     edi,2
                inc     eax
                jmp     printmsgd1

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
                jb      dumpmem3
                cmp     al,128
                jb      dumpmem4
dumpmem3:       mov     al,'.'
dumpmem4:       call    printasc
                inc     edi
                loop    dumpmem2
                call    crlf

                ret


; --------------------------------------------------------------------

changemode:
                inc     emulatemode
                cmp     emulatemode,3
                jne     _ret
                mov     emulatemode,0
                ret

; --------------------------------------------------------------------

changevideomode:
                xor     videomode,1
                ret

; --------------------------------------------------------------------

changebargraph:
                xor     bargraphmode,1
                ret

; --------------------------------------------------------------------

change_megamode:
                xor     megarommode,5
                cmp     megarommode,0
                je      change_megamode0
                mov     eax,offset msgmega05
                jmp     change_megamodex

change_megamode0:       
                mov     eax,offset msgmega00

change_megamodex:
                call    printmsg
                mov     eax,2
                add     eax,megarommode
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax
                ret

; --------------------------------------------------------------------

checkpentium:
                cmp     pentiumfound,1
                je      checkpentium1
                mov     eax,offset msgpentiumonly
                call    printmsg
                stc
                ret
checkpentium1:
                or      eax,eax
                ret

; render_debug -------------------------------------------------------
; render a debug screen

render_debug:
                ; copy the template to temp buffer
                
                mov     esi,offset debug_screen
                mov     edi,offset temp_screen
                mov     ecx,3840/4
                rep     movsd

; --------------------------------------------------------------------
                
                ; print the resolution
                
                cmp     videomode,1
                je      print_res1
                mov     eax,offset res320
                jmp     print_res0
print_res1:
                mov     eax,offset res256
print_res0:
                COORD   15,21
                call    printmsgd
                
; --------------------------------------------------------------------

                ; print the emulation mode

                cmp     emulatemode,0
                jne     print_mode1
                mov     eax,offset modenormal
                jmp     print_mode0
print_mode1:
                cmp     emulatemode,1
                jne     print_mode2
                mov     eax,offset modefast
                jmp     print_mode0
print_mode2:
                mov     eax,offset modeturbo
print_mode0:
                COORD   73,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the bar graph status

                cmp     bargraphmode,1
                je      print_bar1
                mov     eax,offset stateoff
                jmp     print_bar0
print_bar1:
                mov     eax,offset stateon
print_bar0:
                COORD   57,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the frame skipping factor

                mov     eax,framerate
                call    convhex4
                mov     eax,offset tmphex4
                COORD   40,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the contents of Z80 registers

                mov     eax,regeaf
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,2
                call    printmsgd

                mov     eax,regebc
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,3
                call    printmsgd

                mov     eax,regede
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,4
                call    printmsgd

                mov     eax,regehl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,5
                call    printmsgd

                mov     eax,regeix
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,6
                call    printmsgd

                mov     eax,regeiy
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,7
                call    printmsgd

                mov     eax,regepc
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,8
                call    printmsgd

                mov     eax,regesp
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,9
                call    printmsgd

                mov     eax,regeafl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,2
                call    printmsgd

                mov     eax,regebcl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,3
                call    printmsgd

                mov     eax,regedel
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,4
                call    printmsgd

                mov     eax,regehll
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,5
                call    printmsgd

; --------------------------------------------------------------------
                
                ; dump the msx memory
                
; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset temp_screen
                mov     edi,0b8000h
                mov     ecx,3840/4
                rep     movsd
                pop     es

                ret

; --------------------------------------------------------------------

debug:          
                call    clear_text
debug_loop:                
                ;mov     eax,offset tabprompt                                
                ;call    printmsg      
                call    render_debug
                COORD   12,23
                call    set_cursor_position
                call    getchar
                call    toupper
                call    printasc
                call    crlf
                cmp     al,'D'
                je      command_d      
                cmp     al,'0'
                je      command_0
                cmp     al,'M'
                je      command_m
                cmp     al,'S'
                je      command_s
                cmp     al,'B'
                je      command_b
                cmp     al,'F'
                je      command_f
                ;cmp     al,'K'
                ;je      command_k
                cmp     al,'G'
                je      command_g
                cmp     al,'T'
                je      command_t
                cmp     al,'1'
                je      command_1
                cmp     al,'2'
                je      command_2
                cmp     al,'V'
                je      command_v
                cmp     al,'Q'
                je      command_exit
                cmp     al,27
                je      command_exit
                jmp     debug_loop

command_d:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                pushad
                call    crlf
                popad
                call    dumpmem
                jmp     debug_loop

command_g:
                call    checkpentium
                jc      debug_loop
                call    changebargraph
                jmp     debug_loop

command_f:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0ffffh
                mov     framerate,eax
                mov     on_off,eax
                call    crlf
                jmp     debug_loop

command_v:      call    changevideomode
                jmp     debug_loop

command_m:      
                call    changemode
                jmp     debug_loop

command_b:
                COORD   14,23
                call    set_cursor_position
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

command_0:
                call    checkpentium
                jc      debug_loop
                call    setgraphmode
                rdtsc
                push    eax
                call    render_screen0
                call    blit
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
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    emulate
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

command_k:
                call    change_megamode
                jmp     debug_loop

command_1:
                call    checkpentium
                jc      debug_loop
                call    setgraphmode
                call    clear
                rdtsc
                push    eax
                cli     
                call    render_screen1
                sti
                call    blit
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

command_2:
                call    checkpentium
                jc      debug_loop
                call    setgraphmode
                call    clear
                rdtsc
                push    eax
                cli     
                call    render_screen2
                sti
                call    blit
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

command_t:
                movzx   edi,regpc
                movzx   edx,regaf
                mov     eax,0
                mov     ecx,0
                call    trace
                jmp     debug_loop

command_exit:
                ret

code32          ends
                end


