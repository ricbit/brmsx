; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include bit.inc

extrn msxvram: near
extrn vdpregs: near

public render_screen0
public render_screen1
public render_screen2
public render
public clear

; DATA ---------------------------------------------------------------

include screen0.inc
include scr2fore.inc
include scr2back.inc
include scr2frcl.inc
include scr2bkcl.inc

enabled         dd      1
lastscreen      db      0

; render_screen0 -----------------------------------------------------
; render a screen 0 page

render_screen0:
                mov     dx,03C8h
                mov     al,0
                out     dx,al
                inc     dx
                out     dx,al
                out     dx,al
                out     dx,al
                mov     al,32
                out     dx,al
                out     dx,al
                out     dx,al
                mov     esi,offset msxvram                
                mov     ebx,offset msxvram+0800h
                mov     edi,0a0000h+40
                sub     edi,_code32a
                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06:
                push    ebp
                mov     ebp,40
                ; draw a line

render05:
                push    ebp
                mov     cl,[esi]
                mov     ebp,8
                ; draw a char
render04:
                mov     dl,[ebx+ecx*8]
                mov     ax,[offset screen0_table+edx*8]
                inc     ebx
                mov     [edi],ax
                mov     eax,[offset screen0_table+edx*8+2]
                mov     [edi+2],eax
                add     edi,320
                dec     ebp
                jnz     render04                

                sub     ebx,8
                pop     ebp
                inc     esi
                sub     edi,320*8-6
                dec     ebp
                jnz     render05

                pop     ebp
                add     edi,320*7+80
                dec     ebp
                jnz     render06

                ret

; render_screen1 -----------------------------------------------------
; render a screen 1 page

render_screen1:
                ; esi = name table
                movzx   eax,byte ptr [offset vdpregs+2]
                and     eax,0fh
                shl     eax,10
                mov     eax,1800h ;;
                lea     esi,[offset msxvram+eax]

                ; ebx = character pattern table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,07h
                shl     eax,11
                mov     eax,0 ;;
                lea     ebx,[offset msxvram+eax]

                ; ecx = color table
                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     eax,2000h ;;
                lea     ecx,[offset msxvram+eax]

                ; edi = pentium video memory
                mov     edi,0a0000h+32
                sub     edi,_code32a

                ; mask the temporary registers
                xor     edx,edx
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10:       push    ebp

                ; for each char
                mov     ebp,32
render11:       push    ebp

                ; fetch the character
                mov     al,[esi]

                ; fetch the color for that character
                mov     dl,al
                shr     dl,3
                mov     dl,[ecx+edx]
                push    ecx
                mov     ecx,edx
                push    esi

                ; for each subline
                mov     ebp,8
render12:       push    ebp

                ; fetch the pattern for that subline
                mov     dl,[ebx+eax*8]

                ; get the foreground mask
                mov     ebp,[offset foregroundmask+edx*8]

                ; get the background mask
                mov     esi,[offset backgroundmask+edx*8]

                ; blend with the foreground color
                and     ebp,[offset foregroundcolor+ecx*4]

                ; blend with the background color
                and     esi,[offset backgroundcolor+ecx*4]

                ; mix the colors
                or      ebp,esi

                ; display the subline
                mov     [edi],ebp

                ; do it again for the next four pixels
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]
                or      ebp,esi
                mov     [edi+4],ebp

                add     edi,320
                inc     ebx

                pop     ebp
                dec     ebp
                jnz     render12

                sub     edi,320*8-8
                sub     ebx,8

                pop     esi
                pop     ecx

                inc     esi

                pop     ebp
                dec     ebp
                jnz     render11

                sub     edi,8*32-320*8

                pop     ebp
                dec     ebp
                jnz     render10

                jmp     sprite_render

; render_screen2 -----------------------------------------------------
; render a screen 2 page

render_screen2:
                ; esi = name table
                movzx   eax,byte ptr [offset vdpregs+2]
                and     eax,0fh
                shl     eax,10
                lea     esi,[offset msxvram+eax]

                ; ebx = character pattern table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,04h
                shl     eax,11
                lea     ebx,[offset msxvram+eax]

                ; ecx = color table
                movzx   eax,byte ptr [offset vdpregs+3]
                and     eax,080h
                shl     eax,6
                lea     ecx,[offset msxvram+eax]

                ; edi = pentium video memory
                mov     edi,0a0000h+32
                sub     edi,_code32a

                ; mask the temporary registers
                xor     eax,eax
                xor     edx,edx

                ; for each sector
                mov     ebp,3
render23:       push    ebp

                ; for each line
                mov     ebp,8
render20:       push    ebp

                ; for each char
                mov     ebp,32
render21:       push    ebp

                ; fetch the character
                mov     al,[esi]
                push    esi

                ; for each subline
                mov     ebp,8
render22:       push    ebp

                ; fetch the pattern for that subline
                mov     dl,[ebx+eax*8]
                
                ; get the foreground mask
                mov     ebp,[offset foregroundmask+edx*8]
                
                ; get the background mask
                mov     esi,[offset backgroundmask+edx*8]

                ; fetch the color for that subline
                mov     dl,[ecx+eax*8]

                ; blend with the foreground color
                and     ebp,[offset foregroundcolor+edx*4]

                ; blend with the background color
                and     esi,[offset backgroundcolor+edx*4]

                ; mix the colors
                or      ebp,esi

                ; display the subline
                mov     [edi],ebp
                
                ; do it again for the next four pixels
                mov     dl,[ebx+eax*8]
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                mov     dl,[ecx+eax*8]
                and     ebp,[offset foregroundcolor+edx*4]
                and     esi,[offset backgroundcolor+edx*4]
                or      ebp,esi
                mov     [edi+4],ebp
                
                add     edi,320

                inc     ebx
                inc     ecx

                pop     ebp
                dec     ebp
                jnz     render22

                sub     edi,320*8
                add     edi,8

                pop     esi
                inc     esi
                sub     ebx,8
                sub     ecx,8

                pop     ebp
                dec     ebp
                jnz     render21

                sub     edi,32*8
                add     edi,320*8

                pop     ebp
                dec     ebp
                jnz     render20

                add     ebx,256*8
                add     ecx,256*8

                pop     ebp
                dec     ebp
                jnz     render23

                ret

; sprite_render ------------------------------------------------------
; draw the sprites directly on the pentium video memory

sprite_render:

                test    byte ptr [offset vdpregs+1],BIT_1
                jnz     sprite16
                ret

sprite16:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     sprite16M

                ; sprites 16x16 without magnification

                ; esi = sprite attribute table
                movzx   eax,byte ptr [offset vdpregs+5]
                and     eax,07fh
                shl     eax,7
                lea     esi,[offset msxvram+eax]

                ret

sprite16M:      ret

; render -------------------------------------------------------------
; render the MSX screen, based on VDP registers and VRAM

render:
                mov     bl,byte ptr [offset vdpregs]                        
                shr     bl,1
                and     bl,1
                mov     bh,byte ptr [offset vdpregs+1]
                ; test for "video enable" flag
                test    bh,01000000b
                jnz     render1
                cmp     enabled,0
                je      render2
                mov     enabled,0
                jmp     clear
render1:
                mov     enabled,1
                shr     bh,2
                and     bh,00000110b
                or      bl,bh
                cmp     bl,lastscreen
                jz      render0
                call    clear
                mov     lastscreen,bl
render0:
                cmp     bl,0
                je      render_screen1
                cmp     bl,1
                je      render_screen2
                cmp     bl,4
                je      render_screen0
render2:
                ret

; clear --------------------------------------------------------------
; clear the PC screen
                
clear:
                push    es
                mov     ax,gs
                mov     es,ax
                mov     eax,0
                mov     edi,0a0000h
                mov     ecx,16000
                rep     stosd
                mov     dx,03C8h
                mov     al,0
                out     dx,al
                inc     dx
                out     dx,al
                out     dx,al
                out     dx,al
                out     dx,al
                out     dx,al
                out     dx,al
                pop     es
                ret

code32          ends
                end


