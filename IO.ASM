; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include msx.inc
include z80.inc

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

; DATA ---------------------------------------------------------------

align 4

include keyboard.inc

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
exit_now        dd      0

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
        mov v86r_ax,13h
        mov al,10h
        int 33h
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
                
                call    render
                or      vdpstatus,10000000b
                cmp     iff1,1                
                jne     my_irq_handler1
                mov     interrupt,1

my_irq_handler1:
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

code32          ends
                end


