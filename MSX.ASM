; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include bit.inc

extrn msxvram: dword
extrn vdpregs: near
extrn blitbuffer: dword
extrn palette: near

public render_screen0
public render_screen1
public render_screen2
public render
public clear

; DATA ---------------------------------------------------------------

align 4

include screen0.inc
include scr2fore.inc
include scr2back.inc
include scr2frcl.inc
include scr2bkcl.inc

align 4

enabled         dd      1
lastscreen      db      0

; render_screen0 -----------------------------------------------------
; render a screen 0 page

render_screen0:
                mov     dx,03C8h
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,0
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
                
                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,[ebx]
                shr     al,2
                out     dx,al
                mov     al,[ebx+1]
                shr     al,2
                out     dx,al
                mov     al,[ebx+2]
                shr     al,2
                out     dx,al

                mov     esi,msxvram                
                lea     ebx,[esi+0800h]
                mov     edi,blitbuffer
                add     edi,40
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
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,07h
                shl     eax,11
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = pentium video memory
                mov     edi,blitbuffer
                add     edi,32

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
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,04h
                shl     eax,11
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                movzx   eax,byte ptr [offset vdpregs+3]
                and     eax,080h
                shl     eax,6
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = pentium video memory
                mov     edi,blitbuffer
                add     edi,32

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

                sub     edi,320*8-8

                pop     esi
                inc     esi
                sub     ebx,8
                sub     ecx,8

                pop     ebp
                dec     ebp
                jnz     render21

                sub     edi,32*8-320*8

                pop     ebp
                dec     ebp
                jnz     render20

                add     ebx,256*8
                add     ecx,256*8

                pop     ebp
                dec     ebp
                jnz     render23

                jmp     sprite_render

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

sprite16N:
                ; esi = sprite attribute table
                movzx   eax,byte ptr [offset vdpregs+5]
                and     eax,07fh
                shl     eax,7
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ecx = sprite image table
                movzx   eax,byte ptr [offset vdpregs+6]
                and     eax,07h
                shl     eax,11
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = pentium video memory
                mov     edi,blitbuffer
                add     edi,32

                ; mask temporary registers
                xor     eax,eax
                xor     ebx,ebx

                ; find last sprite
                mov     ebp,32
sprite16N5:
                mov     ah,[esi]
                cmp     ah,0D0h
                je      sprite16N6
                add     esi,4
                dec     ebp
                jnz     sprite16N5
sprite16N6:     
                sub     esi,4
                mov     eax,32
                sub     eax,ebp
                mov     ebp,eax
                jz      sprite16N7

                ; for each sprite
sprite16N1:     push    ecx
                ; ah = vertical position of sprite
                mov     ah,[esi]

                ; check if it is 0D0h, in this case exit
                cmp     ah,0D0h
                je      sprite16N2

                ; check if it is bounded
                inc     ah
                cmp     ah,191-16
                ja      sprite16N3

                ; check for horizontal bound
                mov     al,[esi+1]
                cmp     al,255-16
                ja      sprite16N3

                ; load effective initial address in ebx
                push    edi
                xor     ebx,ebx
                mov     bl,ah
                lea     ebx,[ebx+ebx*4]
                and     eax,0ffh
                shl     ebx,6
                add     ebx,eax
                add     edi,ebx

                ; load address of sprite image in ecx
                mov     al,[esi+2]
                and     al,11111100b
                lea     ecx,[ecx+eax*8]

                ; for each subline
                xor     ebx,ebx
                xor     eax,eax
                mov     edx,16
                push    esi
                push    ebp
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]
sprite16N4:
                ; fetch the image for the subline
                mov     bl,[ecx]

                ; get the pentium screen
                mov     esi,[edi]

                ; blend with the sprite image
                and     esi,[offset backgroundmask+ebx*8]

                ; get the sprite color
                mov     ebp,eax

                ; blend with the sprite image
                and     ebp,[offset foregroundmask+ebx*8]

                ; mix the sprite color with the sprite image
                or      esi,ebp

                ; put back to screen
                mov     [edi],esi

                ; do it again for the next four pixels
                mov     esi,[edi+4]
                and     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                or      esi,ebp
                mov     [edi+4],esi
                
                ; and one more time for the next eight pixels
                mov     bl,[ecx+16]
                mov     esi,[edi+8]
                and     esi,[offset backgroundmask+ebx*8]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8]
                or      esi,ebp
                mov     [edi+8],esi
                mov     esi,[edi+12]
                and     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                or      esi,ebp
                mov     [edi+12],esi

                add     edi,320
                inc     ecx
                dec     edx
                jnz     sprite16N4

                pop     ebp
                pop     esi
                pop     edi

sprite16N3:
                pop     ecx
                sub     esi,4
                dec     ebp
                jnz     sprite16N1
                ret

sprite16N2:
                pop     ecx
sprite16N7:
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
                mov     ax,ds
                mov     es,ax
                mov     eax,0
                mov     edi,blitbuffer
                mov     ecx,16000
                rep     stosd
                mov     dx,03C8h
                mov     al,1
                out     dx,al
                inc     dx
                out     dx,al
                out     dx,al
                out     dx,al
                pop     es
                ret

code32          ends
                end


