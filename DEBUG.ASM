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
extrn isize: dword

public debug
public printmsgd

; DATA ---------------------------------------------------------------

align 4

temp_screen     db      3840 dup (0)
memdump         dd      0
tabspace        db      ' $'
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
intdi           db      'DI$'
intei           db      'EI$'

; COORD --------------------------------------------------------------
; convert coordinates from ASCII.EXE system to 
; the dh,dl format used by printmsgd

COORD           macro   x,y

                mov     dx,(y-1)*256+(x-1)

                endm

; clear_text ---------------------------------------------------------
; clear the text screen

clear_text:
                push    eax edi ecx es
                mov     ax,gs
                mov     es,ax
                mov     eax,00070007h
                mov     edi,0b8000h+80*24*2
                mov     ecx,80*2/4
                rep     stosd
                pop     es ecx edi eax
                ret

; printmsgd ----------------------------------------------------------
; print a message in dos format, 
; drawing directly in the temp buffer
; enter: dh=row, dl=column
;        eax= offset of message

printmsgd:
                push    eax edi edx
                movzx   edi,dh
                lea     edi,[edi+edi*4]
                shl     edi,5
                movzx   edx,dl
                lea     edi,[edi+edx*2]
                add     edi,offset temp_screen
printmsgd1:
                mov     dl,[eax]
                cmp     dl,'$'
                je      printmsgd2
                mov     [edi],dl
                add     edi,2
                inc     eax
                jmp     printmsgd1
printmsgd2:
                pop     edx edi eax
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

                irp     i,<0,1,2,3>
                mov     eax,memdump
                add     eax,i*8

                ; print the address
                push    eax                
                call    convhex4
                COORD   4,16+i
                mov     eax,offset tmphex4
                call    printmsgd
                pop     eax

                ; print the contents in hex format
                xor     ecx,ecx
                COORD   9,16+i
print_dump1&i:
                push    eax
                lea     edi,[eax+ecx]
                call    fetch
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                pop     eax
                add     edx,3
                inc     ecx
                cmp     ecx,8
                jnz     print_dump1&i
                
                ; print the contents in ascii format
                xor     ecx,ecx
                COORD   33,16+i
print_dump2&i:
                push    eax
                lea     edi,[eax+ecx]
                call    fetch
                cmp     al,32
                jb      print_dump3&i
                cmp     al,128
                jae     print_dump3&i
                mov     tabspace,al
                push    edx
                mov     eax,offset tabspace
                call    printmsgd
                pop     edx
print_dump3&i:
                pop     eax
                inc     ecx                
                inc     edx
                cmp     ecx,8
                jnz     print_dump2&i

                endm

; --------------------------------------------------------------------
                
                ; print the contents of VDP registers

                mov     ecx,0
                mov     esi,offset vdpregs
                COORD   73,2
print_vdp1:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,8
                jnz     print_vdp1

; --------------------------------------------------------------------
                
                ; print the contents of PSG registers

                mov     ecx,0
                mov     esi,offset psgreg
                COORD   77,2
print_psg1:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_psg1

; --------------------------------------------------------------------
                
                ; print the actual screen mode

                cmp     lastscreen,4
                jne     print_screen1
                mov     tabspace,'0'
                jmp     print_screen0
print_screen1:
                cmp     lastscreen,0
                jne     print_screen2
                mov     tabspace,'1'
                jmp     print_screen0
print_screen2:
                mov     tabspace,'2'
                cmp     lastscreen,1
                je      print_screen0
                mov     tabspace,'X'
print_screen0:
                COORD   74,19
                mov     eax,offset tabspace
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print contents of Z80 register "I"

                mov     al,regi
                call    convhex4
                COORD   48,10
                mov     eax,offset tmphex2
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print contents of iff1 flag: DI or EI

                cmp     iff1,0
                je      print_iff1
                mov     eax,offset intei
                jmp     print_iff0
print_iff1:
                mov     eax,offset intdi
print_iff0:
                COORD   51,10
                call    printmsgd

; --------------------------------------------------------------------
                
                ; disassemble the program

                mov     ecx,0
                mov     edi,regepc
print_dis0:
                xor     eax,eax
                COORD   23,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    edi
                call    print
                pop     edi
                
                ; print the address
                COORD   4,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,edi
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the opcode
                COORD   10,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    ecx
                mov     ecx,isize
print_dis1:
                call    fetch                                
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd
                add     edx,3
                inc     edi
                and     edi,0FFFFh
                dec     ecx
                jnz     print_dis1
                pop     ecx

                inc     ecx
                cmp     ecx,11
                jne     print_dis0

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
                call    render_debug
                COORD   12,23
                call    set_cursor_position
                call    getchar
                call    clear_text
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
                and     eax,0FFFFh
                mov     memdump,eax
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
                call    clear
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
                mov     edi,regepc
                mov     edx,regeaf
                mov     eax,0
                call    trace
                jmp     debug_loop

command_exit:
                ret

code32          ends
                end


