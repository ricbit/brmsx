; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: IO.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn blitbuffer: dword
extrn start_counter: near
extrn end_counter: near

include pmode.inc
include pentium.inc
include vdp.inc
include z80.inc
include bit.inc

public printmsg
public printasc
public printhex4
public printhex2
public printspace
public getchar
public toupper
public gethex4
public setgraphmode
public settextmode
public crlf
public testkbd
public turnon_irq
public turnoff_irq
public turnon_kb_irq
public turnoff_kb_irq
public exit_now
public open_file
public read_file
public read_size_file
public blit
public framerate
public on_off
public set_border_color
public palette
public videomode
public measurespeed
public clockrate
public printdecimal
public bargraphmode

; DATA ---------------------------------------------------------------

align 4

include keyboard.inc
include palette.inc

tmphex4         db      '0000$'         ; temp buffer for print routines
tmphex2         equ     tmphex4+2
tmpasc          equ     tmphex2+1
tmpspace        db      ' $'
tmpdecimal      db      20 dup (' ')
                db      '$'

irq_stub_buf    db      21 dup (0)
oldpirqvect     dd      0
oldrirqvect     dd      0

kbd_stub_buf    db      21 dup (0)
oldkbpirqvect   dd      0
oldkbrirqvect   dd      0

align 4

framerate       dd      1
exit_now        dd      0
on_off          dd      1
videomode       dd      0

clockrate       db      8 dup (0)
measurestatus   dd      0
measureend      dd      0

bargraphmode    dd      0

rendercounter   db      8 dup (0)
renderrate      dd      0
blitcounter     db      8 dup (0)
blitrate        dd      0
guicounter      db      8 dup (0)
guirate         dd      0

msg00           db      13,10,'$'

; printmsg -----------------------------------------------------------
; print a dos message
; eax=address of message

printmsg:       push    ebx eax
                add     eax,_code32a
                shld    ebx,eax,28
                and     eax,0fh
                mov     v86r_ds,bx
                mov     v86r_dx,ax
                mov     v86r_ah,9
                mov     al,21h
                int     33h
                pop     eax ebx
                ret

; printasc -----------------------------------------------------------
; print a single ascii code
; al=code

printasc:       push    eax
                mov     tmpasc,al                
                mov     eax,offset tmpasc
                call    printmsg     
                pop     eax
                ret

        
; printspace ---------------------------------------------------------
; print a space

printspace:  
                push    eax
                mov     eax,offset tmpspace
                call    printmsg     
                pop     eax
                ret

        
; getchar ------------------------------------------------------------
; wait for key and return ascii code in al

getchar:
                mov     v86r_ah,0           
                mov     al,16h
                int     33h
                mov     al,v86r_al
                ret

; testkbd ------------------------------------------------------------
; check if there is a char in the keyboard buffer
; return zero flag if char found

testkbd:
                mov     v86r_ah,1
                mov     al,16h
                int     33h
                ret

; gethex -------------------------------------------------------------
; get a hex digit from the kdb and return in al with echo

gethex:
                call    getchar
                call    toupper
                push    eax
                mov     tmpasc,al
                mov     eax,offset tmpasc
                call    printmsg
                pop     eax
                cmp     al,'A'
                jae     gethex1
                sub     al,'0'
                ret
gethex1:        sub     al,'A'-10
                ret

; gethex4 ------------------------------------------------------------
; get a four-digit hex from the kdb and return in ax (with echo)

gethex4:
                call    gethex
                and     eax,0fh
                mov     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                mov     eax,ecx
                ret

; toupper -------------------------------------------------------------
; upcase a char
; in/out = al

toupper:
        cmp     al,'a'
        jb      toupper1
        cmp     al,'z'
        ja      toupper1
        sub     al,'a'-'A'
toupper1:
        ret

; SET_VGA_REG ---------------------------------------------------------
; set a vga register

SET_VGA_REG     macro   reg,index,value

                mov     dx,reg
                mov     al,index
                out     dx,al
                inc     dx
                mov     al,value
                out     dx,al

                endm

; fill_palette --------------------------------------------------------
; fill the upper palette with the color to make the color bar

fill_palette:
                mov     ebx,offset palette
                mov     ecx,48
fill_palette0:
                movzx   eax,byte ptr [ebx]
                add     eax,100
                cmp     ah,0
                jz      fill_palette1
                mov     al,255
fill_palette1:  
                mov     [ebx+48],al
                inc     ebx
                dec     ecx
                jnz     fill_palette0
                ret

; setgraphmode --------------------------------------------------------
; set video mode 13h (320x200x256)

setgraphmode:
                mov     v86r_ax,13h
                mov     al,10h
                int     33h
                call    fill_palette
                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx
                mov     ebx,offset palette
                mov     ecx,16*3
setgraphmode1:  
                mov     al,[ebx]
                shr     al,2
                out     dx,al
                inc     ebx
                loop    setgraphmode1

                cmp     videomode,0
                je      _ret

                mov     edx,03D4h
                mov     al,11h
                out     dx,al
                inc     edx
                in      al,dx
                and     al,07Fh
                out     dx,al

                SET_VGA_REG 03D4h,0,77
                SET_VGA_REG 03D4h,1,63
                SET_VGA_REG 03D4h,2,64
                SET_VGA_REG 03D4h,3,128+3
                SET_VGA_REG 03D4h,4,68
                SET_VGA_REG 03D4h,5,0
                SET_VGA_REG 03D4h,013h,32

                ret

; set_border_color ----------------------------------------------------
; set color 0 of VGA as VDP border color

set_border_color:
                push    eax ebx edx
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0fh
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx
                mov     al,[ebx]
                shr     al,2
                out     dx,al
                mov     al,[ebx+1]
                shr     al,2
                out     dx,al
                mov     al,[ebx+2]
                shr     al,2
                out     dx,al
                pop     edx ebx eax
                ret

; settextmode ---------------------------------------------------------
; set text mode 3h (80x25 color)

settextmode:
        mov v86r_ax,03h
        mov al,10h
        int 33h
        ret

; convhex ------------------------------------------------------------
; convert a hex number in ax to string in tmphex
; ax= hex number

convhexdig:     push    eax
                and     eax,0fh
                cmp     eax,0ah
                jae     convhexdig1
                add     eax,'0'
                jmp     convhexdig2
convhexdig1:    add     eax,'A'-10
convhexdig2:    mov     [bx],al
                pop     eax
                ret

convhex4:       push    eax ebx
                mov     ebx,offset tmphex4+3
                call    convhexdig
                shr     eax,4
                dec     ebx
                call    convhexdig
                shr     eax,4
                dec     ebx
convhex41:      call    convhexdig
                shr     eax,4
                dec     ebx
                call    convhexdig
                pop     ebx eax
                ret

convhex2:       push    eax ebx
                mov     ebx,offset tmphex2+1
                jmp     convhex41

; printhex -----------------------------------------------------------
; print a hex number
; ax= hex number

printhex4:      push    eax
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsg
                pop     eax
                ret

printhex2:      push    eax
                call    convhex2
                mov     eax,offset tmphex2
                call    printmsg
                pop     eax
                ret

; printdecimal -------------------------------------------------------
; print a decimal number
; eax = decimal 

printdecimal:
                mov     ebx,eax
                mov     ecx,20/4
                mov     eax,20202020h
                mov     edi,offset tmpdecimal
                rep     stosd
                mov     edi,offset tmpdecimal+19
                mov     eax,ebx
                mov     ebx,10
printdecimal1:
                xor     edx,edx
                div     ebx
                add     edx,30h
                mov     [edi],dl
                dec     edi
                cmp     eax,0
                jnz     printdecimal1

                lea     eax,[edi+1]
                call    printmsg
                ret

; crlf ---------------------------------------------------------------
; prints a cr/lf

crlf:           push    eax
                mov     eax,offset msg00
                call    printmsg
                pop     eax
                ret

; turnon_irq ---------------------------------------------------------
; turn on the irq handler

turnon_irq:
                mov     bl,0
                call    _getirqvect
                mov     oldpirqvect,edx
                mov     edx,offset my_irq_handler
                call    _setirqvect
                mov     edi,offset irq_stub_buf
                call    _rmpmirqset
                mov     oldrirqvect,eax
                mov     al,034h
                out     043h,al
                mov     al,0aeh
                out     040h,al
                mov     al,04dh
                out     040h,al
                ret

; turnoff_irq --------------------------------------------------------
; turn off the timer irq handler

turnoff_irq:
                mov     bl,0
                mov     eax,oldrirqvect
                call    _rmpmirqfree
                mov     edx,oldpirqvect
                call    _setirqvect
                mov     al,034h
                out     043h,al
                mov     al,0
                out     040h,al
                mov     al,0
                out     040h,al
                ret

; measurespeed -------------------------------------------------------
; measure how many clock cycles the computer spends
; between one one interrupt and another

measurespeed:                
                cli
                mov     measurestatus,0
                mov     measureend,0
                mov     bl,0
                call    _getirqvect
                mov     oldpirqvect,edx
                mov     edx,offset measure_handler
                call    _setirqvect
                mov     edi,offset irq_stub_buf
                call    _rmpmirqset
                mov     oldrirqvect,eax
                mov     al,034h
                out     043h,al
                mov     al,0aeh
                out     040h,al
                mov     al,04dh
                out     040h,al
                sti
measurespeed0:
                cmp     measureend,1
                jne     measurespeed0

                cli
                mov     bl,0
                mov     eax,oldrirqvect
                call    _rmpmirqfree
                mov     edx,oldpirqvect
                call    _setirqvect
                mov     al,034h
                out     043h,al
                mov     al,0
                out     040h,al
                mov     al,0
                out     040h,al
                sti
                ret

; turnon_kb_irq ------------------------------------------------------
; turn on the keyboard irq handler

turnon_kb_irq:
                mov     bl,1
                call    _getirqvect
                mov     oldkbpirqvect,edx
                mov     edx,offset my_kb_irq_handler
                call    _setirqvect
                mov     edi,offset kbd_stub_buf
                call    _rmpmirqset
                mov     oldkbrirqvect,eax
                ret

; turnoff_kb_irq -----------------------------------------------------
; turn off the keyboard irq handler

turnoff_kb_irq:
                mov     bl,1
                mov     eax,oldkbrirqvect
                call    _rmpmirqfree
                mov     edx,oldkbpirqvect
                call    _setirqvect
                ret

; measure_handler ----------------------------------------------------
; this handler is used to measure the clock of the processor

measure_handler:
                pushad
                push    ds
                inc     measurestatus
                cmp     measurestatus,5
                jb      measure_handler_exit
                ja      measure_handler1
                rdtsc
                mov     dword ptr [offset clockrate],eax
                mov     dword ptr [offset clockrate+4],edx
                jmp     measure_handler_exit
measure_handler1:
                rdtsc
                sub     eax,dword ptr [offset clockrate]
                sbb     edx,dword ptr [offset clockrate+4]
                mov     dword ptr [offset clockrate],eax
                mov     dword ptr [offset clockrate+4],edx
                mov     measureend,1
measure_handler_exit:
                mov     al,20h
                out     20h,al
                pop     ds
                popad
                sti
                iretd

; my_irq_handler -----------------------------------------------------
; this is the handler of the timer irq

my_irq_handler:
                pushad
                push    ds gs
                mov     ds,cs:_seldata
                mov     gs,cs:_selzero
                
                dec     on_off
                jnz     my_irq_handler0
                mov     eax,framerate
                mov     on_off,eax
                cli

                mov     eax,offset rendercounter
                call    start_counter
                call    render
                mov     eax,offset rendercounter
                call    end_counter
                mov     eax,dword ptr [offset rendercounter]
                mov     renderrate,eax

                mov     eax,offset guicounter
                call    start_counter
                call    draw_gui
                mov     eax,offset guicounter
                call    end_counter
                mov     eax,dword ptr [offset guicounter]
                mov     guirate,eax

                mov     eax,offset blitcounter
                call    start_counter
                call    blit
                mov     eax,offset blitcounter
                call    end_counter
                mov     eax,dword ptr [offset blitcounter]
                mov     blitrate,eax

my_irq_handler0:
                or      vdpstatus,10000000b
                mov     interrupt,1
                mov     al,20h
                out     20h,al
                pop     gs ds
                popad
                sti
                iretd

; draw_gui -----------------------------------------------------------

draw_gui:
                cmp     bargraphmode,0
                je      _ret
                mov     edi,0
                mov     eax,z80rate
                call    drawline
                mov     edi,5
                mov     eax,renderrate
                call    drawline
                mov     edi,10
                mov     eax,blitrate
                call    drawline
                mov     edi,15
                mov     eax,guirate
                call    drawline
                ret

drawline:
                mov     ebx,100
                mul     ebx                
                xor     edx,edx
                mov     ebx,dword ptr [offset clockrate]
                div     ebx
                mov     ecx,100
                shl     edi,8
                add     edi,blitbuffer
                mov     ebx,0F0Dh
drawline1:      
                cmp     ecx,eax
                jbe     drawline2
                mov     byte ptr [edi],bh
                mov     byte ptr [edi+256],bh
                mov     byte ptr [edi+256*2],bh
                mov     byte ptr [edi+256*3],bh
                jmp     drawline_exit
drawline2:
                mov     byte ptr [edi],bl
                mov     byte ptr [edi+256],bl
                mov     byte ptr [edi+256*2],bl
                mov     byte ptr [edi+256*3],bl
drawline_exit:
                inc     edi
                dec     ecx
                jnz     drawline1
                ret

; my_kb_irq_handler --------------------------------------------------
; this is the handler of the keyboard irq

my_kb_irq_handler:
                pushad
                push    ds 
                mov     ds,cs:_seldata
                
                in      al,060h                
                cmp     al,44h
                jne     my_kb_irq_handler1
                mov     ds:exit_now,1

my_kb_irq_handler1:
                
                test    al,080h
                jnz     my_kb_irq_handler2
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboardtable+eax*2]
                mov     cl,byte ptr [offset keyboardtable+eax*2+1]
                xor     cl,255
                and     byte ptr [offset keymatrix+ebx],cl
                jmp     my_kb_irq_handler3

my_kb_irq_handler2:                
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboardtable+eax*2]
                mov     cl,byte ptr [offset keyboardtable+eax*2+1]
                or      byte ptr [offset keymatrix+ebx],cl

my_kb_irq_handler3:

                mov     al,20h
                out     20h,al
                pop     ds
                popad
                sti
                iretd
                
; open_file ----------------------------------------------------------
; open a file
; in: edx = ASCIIZ filename
; out: v86r_bx = file handle
;      carry = 1 -> error                

open_file:                
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_dx,ax
                mov     v86r_ds,dx
                mov     v86r_ax,03d02h
                mov     al,21h
                int     33h
                mov     ax,v86r_ax
                mov     v86r_bx,ax
                ret

; read_file ----------------------------------------------------------
; read a file
; in: v86r_bx = file handle
;     edx = address of read buffer
;     ecx = number of bytes to read (must be <0ffffh)

read_file:                
                push    eax
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_ds,dx
                mov     v86r_dx,ax
                mov     v86r_cx,cx
                mov     v86r_ax,03f00h
                mov     al,21h
                int     33h
                pop     eax
                ret

; read_size_file -----------------------------------------------------
; read the size of the file
; in: v86r_bx = file handle

read_size_file:
                mov     v86r_ax,4201h
                xor     eax,eax
                mov     v86r_cx,ax
                mov     v86r_dx,ax
                mov     al,21h
                int     33h
                push    v86r_dx
                push    v86r_ax
                mov     v86r_ax,4202h
                xor     eax,eax
                mov     v86r_cx,ax
                mov     v86r_dx,ax
                mov     al,21h
                int     33h
                mov     ax,v86r_dx
                shl     eax,16
                mov     ax,v86r_ax
                pop     v86r_dx
                pop     v86r_cx
                mov     v86r_ax,4200h
                push    eax
                mov     al,21h
                int     33h
                pop     eax
                ret

; blit ---------------------------------------------------------------
; copy the contents of blit buffer to pentium video memory

blit:              
                cmp     videomode,0
                je      blit0
                push    es
                mov     ax,cs:_selzero
                mov     es,ax
                mov     edi,0a0000h
                mov     esi,blitbuffer
                mov     ecx,256*192/4
                rep     movsd
                pop     es
                ret
blit0:
                push    es
                mov     ax,cs:_selzero
                mov     es,ax
                mov     esi,blitbuffer
                mov     edi,0a0000h+32
                mov     edx,192
blit0_0:
                mov     ecx,256/4
                rep     movsd
                add     edi,64
                dec     edx
                jnz     blit0_0
                pop     es
                ret

code32          ends
                end


