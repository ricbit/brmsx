; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include msx.inc
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
public reset_sb
public set_border_color
public palette

; DATA ---------------------------------------------------------------

align 4

include keyboard.inc
include palette.inc

extrn blitbuffer: dword

tmphex4         db      '0000$'         ; temp buffer for print routines
tmphex2         equ     tmphex4+2
tmpasc          equ     tmphex2+1
tmpspace        db      ' $'

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

; setgraphmode --------------------------------------------------------
; set video mode 13h (320x200x256)

setgraphmode:
                mov     v86r_ax,13h
                mov     al,10h
                int     33h
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
                ret

; set_border_color ----------------------------------------------------
; set color 0 of VGA as VDP border color

set_border_color:
                pushad
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
                popad
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
                call    render
                call    blit
my_irq_handler0:
                or      vdpstatus,10000000b
                mov     interrupt,1
                mov     al,20h
                out     20h,al
                pop     gs ds
                popad
                sti
                iretd

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
                push    es
                mov     ax,cs:_selzero
                mov     es,ax
                mov     edi,0a0000h
                mov     esi,blitbuffer
                mov     ecx,64000/4
                rep     movsd
                pop     es
                ret

; set_sb_reg ---------------------------------------------------------
; set a sound blaster register
; al: port number
; bl: value

set_sb_reg:
                push    eax
                push    ebx
                pushfd
                cli
                mov     dx,0330h
                out     dx,al
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                inc     dx
                mov     al,bl
                out     dx,al
                popfd
                dec     dx
                
                ;1
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;2
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;3
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;4
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;5
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;6
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                ;7
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx
                in      al,dx

                pop     ebx
                pop     eax

                ret

; reset_sb -----------------------------------------------------------
; reset the sound blaster

reset_sb:
                mov     al,0
                mov     bl,0
reset_sb1:
                call    set_sb_reg
                inc     al
                cmp     al,0f5h
                jbe     reset_sb1

                ret

code32          ends
                end


