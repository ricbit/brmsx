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
include saveload.inc
include blit.inc
include bit.inc
include compiler.inc
include serial.inc
include psg.inc
include mouse.inc

include debugsrc.inc
include helpsrc.inc
include srsrc.inc
include clsrc.inc

extrn msxrom: near
extrn pentiumfound: dword
extrn isize: dword
extrn setup_profile: near
extrn end_profile: near
extrn dirtycode: dword
extrn compbuffer: dword

public debug
public printmsgd
public writemessage

public change_sound
public changebargraph

public quitnow
public vesa2found

; DATA ---------------------------------------------------------------

align 4

temp_screen     db      3840 dup (0)
message         db      80*2 dup (0)
messagepointer  dd      0
memdump         dd      0
tabspace        db      ' $'
tabindicator    db      '>$'
flags           db      '00000000$'
msgmega00       db      'megarom type 0 - konami 8kb',13,10,'$'
msgmega05       db      'megarom type 5 - ascii 16kb',13,10,'$'
msgpentiumonly  db      'This option requires a Pentium$'
res320          db      '320x200$'
res256          db      '256x200$'
res512          db      '512x384$'
modenormal      db      'NORMAL$'
modefast        db      'FAST  $'
modeturbo       db      'TURBO $'
stateon         db      'ON $'
stateoff        db      'OFF$'
intdi           db      'DI$'
intei           db      'EI$'
imagedynamic    db      ' OFF   $'
imagestatic     db      ' ON    $'
com1            db      '1$'
com2            db      '2$'
com3            db      '3$'
com4            db      '4$'
sessionsingle   db      'SINGLE$'
sessionserver   db      'SERVER$'
sessionclient   db      'CLIENT$'

align 4

quitnow         dd      0
vesa2found      dd      0

; COORD --------------------------------------------------------------
; convert coordinates from ASCII.EXE system to 
; the dh,dl format used by printmsgd

COORD           macro   x,y

                mov     dx,(y-1)*256+(x-1)

                endm

; clear_text ---------------------------------------------------------
; clear the text screen

clear_text:
                push    eax edi ecx
                mov     eax,07200720h
                mov     edi,offset message
                mov     ecx,80*2/4
                rep     stosd
                mov     eax,offset message
                mov     messagepointer,eax
                pop     ecx edi eax
                jmp     printmessage

; printmessage -------------------------------------------------------
; print the message in bottom line of screen

printmessage:
                push    eax esi edi ecx es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset message
                mov     edi,0b8000h+80*24*2
                mov     ecx,80*2/4
                rep     movsd
                pop     es ecx edi esi eax
                ret

; writemessage -------------------------------------------------------
; write a dos string in the message space

writemessage:
                mov     edx,messagepointer
                mov     bl,[eax]
                cmp     bl,'$'
                je      _ret
                mov     [edx],bl
                add     messagepointer,2
                inc     eax
                jmp     writemessage

; write8 -------------------------------------------------------------
; write a 8-byte hex number in the message field

write8:
                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                pop     eax
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
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
                and     edx,0FFh
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
                
emulate_client:                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset client_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    turnon_kb_irq
                call    UART_init
                call    UART_send_idstring

emulate_client_loop:
                ;call    UART_receive_idstring

                mov     bl,byte ptr [offset keymatrix+4]
                mov     al,0
                rcr     bl,3
                rcl     al,1
                
                mov     bl,byte ptr [offset keymatrix+8]
                rcr     bl,1
                rcl     al,1

                mov     bl,byte ptr [offset keymatrix+8]
                rcl     bl,1
                rcl     al,1
                rcl     bl,3
                rcl     al,1
                
                mov     bl,byte ptr [offset keymatrix+8]
                rcl     bl,2
                rcl     al,1
                rcl     bl,1
                rcl     al,1

                call    UART_send

                mov     al,byte ptr [offset keymatrix+7]
                test    al,BIT_2
                jnz     emulate_client_loop

                mov     byte ptr [offset keymatrix+7],0FFh

                call    turnoff_kb_irq
                jmp     debug_loop

; --------------------------------------------------------------------

changemode:
                inc     emulatemode
                cmp     emulatemode,3
                jne     _ret
                mov     emulatemode,0
                ret

; --------------------------------------------------------------------

changevideomode:
                add     videomode,1
                cmp     videomode,2
                je      changevideomode_vesa2
                cmp     videomode,3
                jne     _ret
                mov     videomode,0
                ret
changevideomode_vesa2:
                cmp     vesa2found,0
                jne     _ret
                mov     videomode,0
                ret

; --------------------------------------------------------------------

change_sound:
                mov     eax,sounddetected
                xor     soundenabled,eax
                ret

; --------------------------------------------------------------------

changebargraph:
                mov     eax,pentiumfound
                xor     bargraphmode,eax
                ret

; --------------------------------------------------------------------

change_vsync:
                xor     vsyncflag,1
                ret

; --------------------------------------------------------------------

changesession:
                inc     sessionmode
                cmp     sessionmode,3
                jne     _ret
                mov     sessionmode,0
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
                call    writemessage
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
                jae     print_res1
                mov     eax,offset res320
                jmp     print_res0
print_res1:
                cmp     videomode,2
                jae     print_res2
                mov     eax,offset res256
                jmp     print_res0
print_res2:
                mov     eax,offset res512
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

                ; print the vsync mode

                cmp     vsyncflag,0
                jne     print_vsync1
                mov     eax,offset stateoff
                jmp     print_vsync_done
print_vsync1:
                mov     eax,offset stateon
print_vsync_done:
                COORD   30,22
                call    printmsgd

; --------------------------------------------------------------------

                ; print the sound mode

                cmp     soundenabled,0
                jne     print_sound1
                mov     eax,offset stateoff
                jmp     print_sound_done
print_sound1:
                mov     eax,offset stateon
print_sound_done:
                COORD   18,22
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

                ; print the COM port being used

                COORD   57,22
                cmp     comport,1
                jne     print_com2
                mov     eax,offset com1
                call    printmsgd
                jmp     print_com_exit
print_com2:
                cmp     comport,2
                jne     print_com3
                mov     eax,offset com2
                call    printmsgd
                jmp     print_com_exit
print_com3:
                cmp     comport,3
                jne     print_com4
                mov     eax,offset com3
                call    printmsgd
                jmp     print_com_exit
print_com4:
                mov     eax,offset com4
                call    printmsgd
print_com_exit:

; --------------------------------------------------------------------

                ; print the session mode

                COORD   44,22
                cmp     sessionmode,0
                jne     print_session1
                mov     eax,offset sessionsingle
                call    printmsgd
                jmp     print_session_exit
print_session1:
                cmp     sessionmode,1
                jne     print_session2
                mov     eax,offset sessionserver
                call    printmsgd
                jmp     print_session_exit
print_session2:
                mov     eax,offset sessionclient
                call    printmsgd
print_session_exit:

; --------------------------------------------------------------------

                ; print the frame skipping factor

                mov     eax,framerate
                call    convhex4
                mov     eax,offset tmphex4
                COORD   40,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the image type

                cmp     imagetype,0
                jne     print_image0
                mov     eax,offset imagedynamic
                jmp     print_image1
print_image0:
                mov     eax,offset imagestatic
print_image1:
                COORD   72,22
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

                ; print the pc indicator
                cmp     edi,regepc
                jne     print_dis2
                COORD   8,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,offset tabindicator
                call    printmsgd

print_dis2:
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
                
                ; print the Z80 flags

                mov     ecx,8
                mov     eax,offset flags+7
                mov     ebx,regeaf
print_flags0:
                xor     edx,edx
                shr     ebx,1
                adc     dl,'0'
                mov     [eax],dl
                dec     eax
                dec     ecx
                jnz     print_flags0
                COORD   55,8
                mov     eax,offset flags
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print the Z80 register "R"

                mov     eax,rcounter
                and     eax,07Fh
                or      al,rmask
                call    convhex4
                mov     eax,offset tmphex2
                COORD   61,10
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print the PPI registers

                mov     al,prim_slotreg
                call    convhex4
                mov     eax,offset tmphex2
                COORD   48,13
                call    printmsgd
                
                mov     al,ppic
                call    convhex4
                mov     eax,offset tmphex2
                COORD   48,14
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print primary slot configuration

                irp     i,<0,1,2,3>
                mov     al,prim_slotreg
                shr     al,i*2
                and     al,3
                add     al,'0'
                mov     tabspace,al
                mov     eax,offset tabspace
                COORD   52,16+i
                call    printmsgd
                endm

; --------------------------------------------------------------------
                
                ; print megarom block information

                mov     ecx,0
                mov     esi,offset megablock
print_mega:
                mov     eax,[esi]
                call    convhex4
                COORD   61,12
                mov     edi,ecx
                shl     edi,8
                add     edx,edi
                mov     eax,offset tmphex2
                call    printmsgd
                add     esi,4
                inc     ecx
                cmp     ecx,8
                jne     print_mega

                
; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset temp_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                ret

; init_compiler ------------------------------------------------------
; initialize the luts for the compile pipeline

init_compiler:
                mov     ecx,131072 ; 64kb*8 /4
                mov     eax,0
                mov     edi,dirtycode
                rep     stosd
                mov     ecx,262144 ;1048576/4
                mov     eax,0C3C3C3C3h
                mov     edi,compbuffer
                rep     stosd
                mov     ebx,compbuffer
                mov     nextopcode,ebx
                ret

; --------------------------------------------------------------------

debug:          
                ;call    init_compiler
                call    set_com_baseaddr
                call    clear_text
                jmp     command_s
debug_loop:                
                cmp     quitnow,1
                je      _ret
                call    render_debug
                call    printmessage
                COORD   12,23
                call    set_cursor_position
                call    getchar
                or      al,al
                je      command_extended
                call    clear_text
                call    toupper
                call    printasc
                call    crlf
                cmp     al,'D'
                je      command_d      
                cmp     al,'C'
                je      command_c
                cmp     al,'0'
                je      command_0
                cmp     al,'M'
                je      command_m
                cmp     al,'S'
                je      command_s
                cmp     al,'B'
                je      command_b
                cmp     al,'P'
                je      command_p
                cmp     al,'Y'
                je      command_y
                cmp     al,'F'
                je      command_f
                cmp     al,'H'
                je      command_help
                cmp     al,'J'
                je      command_j
                cmp     al,'K'
                je      command_k
                cmp     al,'R'
                je      command_r
                cmp     al,'A'
                je      command_a
                cmp     al,'I'
                je      command_i
                cmp     al,'L'
                je      command_l
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
                cmp     al,'Z'
                je      command_z
                cmp     al,'N'
                je      command_n
                cmp     al,'E'
                je      command_e
                cmp     al,'Q'
                je      command_exit
                cmp     al,27
                je      command_exit
                jmp     debug_loop

command_extended:
                call    crlf
                cmp     ah,59
                je      command_help
                jmp     debug_loop

command_e:
                call    init_compiler
                jmp     debug_loop

command_n:
                call    changesession
                jmp     debug_loop

command_d:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                mov     memdump,eax
                jmp     debug_loop

command_y:              
                call    change_vsync
                jmp     debug_loop

command_z:
                call    UART_init
                call    UART_send_idstring
                jmp     debug_loop

command_r:
                call    UART_init
                call    UART_receive_idstring
                mov     eax,offset modenormal
                call    writemessage
                jmp     debug_loop

command_help:
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset help_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    getchar
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

command_j:
                call    save_histogram
                jmp     debug_loop

command_v:      call    changevideomode
                jmp     debug_loop

command_i:
                xor     imagetype,1
                jmp     debug_loop

command_a:
                call    save_state
                jmp     debug_loop

command_l:
                call    load_state
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

command_p:
                call    change_sound
                jmp     debug_loop

command_h:
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    setup_profile
                call    emulate_histogr
                call    end_profile
                push    edx eax
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                pop     eax
                call    write8
                add     messagepointer,2
                pop     eax
                call    write8
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
                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                pop     eax
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                call    crlf
                jmp     debug_loop

command_s:      
                cmp     sessionmode,2
                je      emulate_client
                cmp     sessionmode,1
                jne     command_s_go
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset server_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    UART_init
                call    UART_receive_idstring
command_s_go:
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate
                call    sound_off
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

command_c:      
                mov     firstscreen,1
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    compile_pipeline
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

;command_k:
;                call    change_megamode
;                jmp     debug_loop

command_k:
                inc     comport
                cmp     comport,5
                jne     command_k_print
                mov     comport,1
command_k_print:
                call    set_com_baseaddr
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
                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                pop     eax
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                call    crlf
                jmp     debug_loop

command_2:
                call    checkpentium
                jc      debug_loop
                call    setgraphmode
                call    clear
                call    set_border_color
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
                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                pop     eax
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
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


