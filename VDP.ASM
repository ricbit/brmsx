; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: VDP.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include pentium.inc
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
public lastscreen
public actualscreen
public sprite_render
public imagetype
public nametable
public patterntable
public colortable
public sprattrtable
public sprpatttable
public eval_sprite_coords
public dirty_sprite
public firstscreen
public eval_base_address
public vrammapping
public screenselect 
public dirtyname
public dirtypattern

; DATA ---------------------------------------------------------------

align 4

include screen0.inc
include scr2fore.inc
include scr2back.inc
include scr2frcl.inc
include scr2bkcl.inc
include scr2frmx.inc
include scr2bkmx.inc

align 4

enabled         dd      1
linenumber      dd      0
stacksave       dd      0
colorsave       dd      0
patternsave     dd      0
spriteenable    dd      0
imagetype       dd      1
nametable       dd      0
colortable      dd      0
patterntable    dd      0
sprattrtable    dd      0
sprpatttable    dd      0
firstscreen     dd      1
vrammapping     db      256 dup (0)
screenselect    dd      ? ; nothing
                dd      ? ; name table
                dd      ? ; pattern table
                dd      ? ; color table
                dd      ? ; sprite attribute table
                dd      ? ; sprite image table
dirtyname       db      32*24 dup (0)
dirtypattern    db      256*3 dup (0)
dirtysprite     db      32 dup (0)
spriteline      db      192 dup (0)
lastscreen      db      0
actualscreen    db      0

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
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al
                
                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                mov     esi,msxvram                
                lea     ebx,[esi+0800h]
                mov     edi,blitbuffer
                add     edi,8
                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06:
                push    ebp
                mov     ebp,40
                ; draw a line

render05:
                ; draw two chars

                mov     cl,[esi]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table1+edx*8]
                mov     [edi+i*256],eax
                mov     eax,[offset screen0_table1+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+4+i*256],eax

                endm

                mov     cl,[esi+1]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table2+edx*8]
                mov     [edi+6+i*256],ax
                mov     eax,[offset screen0_table2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+8+i*256],eax

                endm

                add     esi,2
                add     edi,12
                sub     ebp,2
                jnz     render05

                pop     ebp
                add     edi,256*7+16
                dec     ebp
                jnz     render06

                mov     spriteenable,0
                ret

; PIPE1 --------------------------------------------------------------
; this is the inner loop for render_screen1_* functions

PIPE1           macro

                ; fetch the character
                mov     al,[esi]

                ; fetch the color for that character
                xor     edx,edx
                mov     dl,al
                shr     dl,3
                mov     dl,[ecx+edx]

                push    ecx
                push    esi
                push    eax
                push    ebx
                
                lea     ebx,[ebx+eax*8]
                mov     eax,[offset foregroundcolor+edx*4]
                mov     ecx,[offset backgroundcolor+edx*4]

                ; for each subline

                ; fetch the pattern for that subline
                mov     dl,[ebx]
                
                irp     i,<0,1,2,3,4,5,6,7>

                ; get the foreground mask
                mov     ebp,[offset foregroundmask+edx*8]

                ; get the background mask
                mov     esi,[offset backgroundmask+edx*8]

                ; blend with the foreground color
                and     ebp,eax

                ; blend with the background color
                and     esi,ecx

                ; mix the colors
                or      ebp,esi
                mov     esi,[offset backgroundmask+edx*8+4]

                ; display the subline
                mov     [edi+i*256],ebp

                ; do it again for the next four pixels
                mov     ebp,[offset foregroundmask+edx*8+4]
                and     esi,ecx
                and     ebp,eax
                or      ebp,esi
                mov     dl,[ebx+i+1]
                mov     [edi+4+i*256],ebp

                endm

                pop     ebx
                pop     eax
                pop     esi
                pop     ecx
                
                endm

; render_screen1_dirty -----------------------------------------------
; render a screen 1 page using dirty blocks

render_screen1_dirty:
                
                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = pentium video memory
                mov     edi,blitbuffer

                ; edx = dirty table
                mov     edx,offset dirtyname

                ; mask the temporary registers
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10d:      push    ebp

                ; for each char
                mov     ebp,32
render11d:      push    ebp

                mov     al,[edx]
                or      al,al
                jz      render12d

                push    edx
                PIPE1
                pop     edx

render12d:

                add     edi,8
                inc     esi
                inc     edx

                pop     ebp
                dec     ebp
                jnz     render11d

                add     edi,256*7

                pop     ebp
                dec     ebp
                jnz     render10d

                mov     spriteenable,1
                ret


; render_screen1 -----------------------------------------------------
; render a screen 1 page

render_screen1:
                cmp     imagetype,1
                je      render_screen1_dirty

render_screen1_linear:
                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = pentium video memory
                mov     edi,blitbuffer

                ; mask the temporary registers
                xor     edx,edx
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10:       push    ebp

                ; for each char
                mov     ebp,32
render11:       push    ebp

                PIPE1

                add     edi,8
                inc     esi

                pop     ebp
                dec     ebp
                jnz     render11

                add     edi,256*7

                pop     ebp
                dec     ebp
                jnz     render10

                mov     spriteenable,1
                ret

; PIPE2_DOS ----------------------------------------------------------
; this is the inner loop for render_screen2 function
; it uses the esp as a general register
; and because of that, this macro doesn't run under
; multitasking environments

PIPE2_DOS       macro
                
                mov     stacksave,esp
                mov     esp,colorsave

                ; fetch the pattern for that subline
                mov     dl,[ebx+eax*8]
                mov     cl,[esp+eax*8]
                
                irp     i,<0,1,2,3,4,5,6,7>

                mov     ebp,[offset foregroundmask+edx*8]
                mov     esi,[offset backgroundmask+edx*8]

                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]

                or      ebp,esi
                mov     dl,[ebx+eax*8+i]

                mov     cl,[esp+eax*8+i]
                mov     [edi+i*256],ebp
                
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                
                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]
                
                or      ebp,esi
                mov     dl,[ebx+eax*8+(i+1)]
                
                mov     cl,[esp+eax*8+(i+1)]
                mov     [edi+4+i*256],ebp

                endm
                
                mov     esp,stacksave
                
                endm

; PIPE2_WIN ----------------------------------------------------------
; this is the inner loop for render_screen2 function
; it doesn't use the esp as a general register
; and can run under windows

PIPE2_WIN       macro
                
                mov     dl,[ebx+eax*8]
                
                irp     i,<0,1,2,3,4,5,6,7>

                ; get the foreground mask
                mov     ebp,[offset foregroundmask+edx*8]
                
                ; get the background mask
                mov     esi,[offset backgroundmask+edx*8]

                ; fetch the color for that subline
                mov     dl,[ecx+eax*8+i]

                ; blend with the foreground color
                and     ebp,[offset foregroundcolor+edx*4]

                ; blend with the background color
                and     esi,[offset backgroundcolor+edx*4]

                ; mix the colors
                or      ebp,esi

                ; display the subline
                mov     dl,[ebx+eax*8+i]
                mov     [edi+i*256],ebp
                
                ; do it again for the next four pixels
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                mov     dl,[ecx+eax*8+i]
                and     ebp,[offset foregroundcolor+edx*4]
                and     esi,[offset backgroundcolor+edx*4]
                or      ebp,esi
                mov     dl,[ebx+eax*8+(i+1)]
                mov     [edi+4+i*256],ebp

                endm
                endm

; PIPE2_MMX ----------------------------------------------------------
; this is the inner loop for render_screen2 function
; it uses the MMX instructions for better performance

PIPE2_MMX       macro

                lea     esi,[ebx+eax*8]
                lea     ebp,[ecx+eax*8]
                mov     eax,0
                
                ; pattern
                mov     dl,[esi]
                ; color
                mov     al,[ebp]
                
                irp     i,<0,1,2,3,4,5,6,7>

                ; foreground and background mask
                ;;movq    MM0,[offset foregroundmask+edx*8]
                movq
                db      00000100b
                db      11010101b
                dd      offset foregroundmask

                ;;movq    MM1,MM0
                movq
                db      11001000b

                ; blend with the foreground color
                ;;pand    MM0,[offset foregroundcolor_MMX+ebx*8]
                pand
                db      00000100b
                db      11000101b
                dd      offset foregroundcolor_MMX
                
                ; blend with the background color
                ;;pandn    MM1,[offset backgroundcolor_MMX+ebx*8]
                pandn
                db      00001100b
                db      11000101b
                dd      offset backgroundcolor_MMX
                
                mov     dl,[esi+i+1]
                
                ;;por     MM0,MM1
                por
                db      11000001b
                
                mov     al,[ebp+i+1]
                
                ;;movq    [edi+i*256],MM0
                movq_st
                db      10000111b
                dd      i*256
                
                endm

                endm

; render_screen2_dirty -----------------------------------------------
; render a screen 2 page using dirty blocks
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2_dirty:

                call    wash_sprite

                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]
                mov     patternsave,ebx

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]
                mov     colorsave,ecx

                ; edi = pentium video memory
                mov     edi,blitbuffer

                ; edx = dirty table name
                ; ebx = dirty table pattern
                mov     edx,offset dirtyname
                mov     ebx,offset dirtypattern

                ; mask the temporary registers
                xor     eax,eax

                ; for each sector
                mov     ebp,3
render23d:      
                push    ebp

                ifdef   DOS
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8
render20d:      push    ebp

                ; for each char
                mov     ebp,32
render21d:       
                mov     al,[edx]
                or      al,al
                jnz     render2d_draw

                mov     al,[esi]
                cmp     byte ptr [ebx+eax],0
                je      render2d_next
                mov     byte ptr [edx],1

render2d_draw:
                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi

                push    ebx
                push    edx

                xor     edx,edx
                mov     ebx,patternsave

                ifdef   DOS
                  PIPE2_DOS
                else
                  ifdef MMX
                    PIPE2_MMX
                  else
                    PIPE2_WIN
                  endif
                endif

                pop     edx
                pop     ebx

                pop     esi
                pop     ebp
                
render2d_next:

                inc     esi
                add     edi,8
                inc     edx
                dec     ebp
                jnz     render21d

                pop     ebp
                add     edi,256*7
                dec     ebp
                jnz     render20d

                add     ebx,256                                         
                add     patternsave,256*8
                add     colorsave,256*8

                pop     ebp
                dec     ebp
                jnz     render23d

                mov     spriteenable,1
                ret

; render_screen2 -----------------------------------------------------
; render a screen 2 page
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2:
                cmp     imagetype,1
                je      render_screen2_dirty

render_screen2_linear:
                
                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]
                mov     colorsave,ecx

                ; edi = pentium video memory
                mov     edi,blitbuffer

                ; mask the temporary registers
                xor     eax,eax
                xor     edx,edx

                ; for each sector
                mov     ebp,3
render23:       push    ebp

                ifdef   DOS
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8
render20:       push    ebp

                ; for each char
                mov     ebp,32
render21:       
                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi

                ifdef   DOS
                  PIPE2_DOS
                else
                  ifdef MMX
                    PIPE2_MMX
                  else
                    PIPE2_WIN
                  endif
                endif

                add     edi,8

                pop     esi
                pop     ebp
                
                inc     esi
                dec     ebp
                jnz     render21

                pop     ebp
                add     edi,256*7
                dec     ebp
                jnz     render20

                add     ebx,256*8
                add     colorsave,256*8

                pop     ebp
                dec     ebp
                jnz     render23

                mov     spriteenable,1
                ret

; sprite_render ------------------------------------------------------
; draw the sprites directly on the pentium video memory

align 4

sprite_render:

                cmp     spriteenable,1
                jne     _ret

                test    byte ptr [offset vdpregs+1],BIT_1
                jnz     sprite16
                ret

sprite16:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jz      sprite16N
                ret

                ; sprites 16x16 without magnification

sprite16N:
                ; clear sprite line buffer
                call    clear_sprite_buffer
                
                ; esi = sprite attribute table
                movzx   eax,byte ptr [offset vdpregs+5]
                and     eax,07fh
                shl     eax,7
                mov     sprattrtable,eax
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
sprite16N1:     push    ecx eax

                call    eval_sprite_coords
                cmp     eax,0
                js      sprite16N3
                cmp     eax,192-16
                jge     sprite16N3
                cmp     ecx,0
                js      sprite16N3
                cmp     ecx,256-16
                jge     sprite16N3
                mov     ch,al
                mov     edi,blitbuffer
                add     edi,ecx
                
                ; load effective initial address in edi
                push    edi

                ; load address of sprite image in ecx
                mov     al,[esi+2]
                and     al,11111100b
                mov     ecx,sprpatttable
                add     ecx,msxvram
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

sprite16N8:

                add     edi,256
                inc     ecx
                dec     edx
                jnz     sprite16N4

                pop     ebp
                pop     esi
                pop     edi

sprite16N3:
                pop     eax ecx
                sub     esi,4
                dec     ebp
                jnz     sprite16N1
                ret

sprite16N2:
                pop     ecx
sprite16N7:
                ret

; clear_sprite_buffer ------------------------------------------------

clear_sprite_buffer:

                mov     eax,0
                mov     ecx,192/4
                mov     edi,offset spriteline
                rep     stosd
                ret

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
                cmp     enabled,0
                jne     render3
                mov     firstscreen,1
render3:
                mov     enabled,1
                shr     bh,2
                and     bh,00000110b
                or      bl,bh
                cmp     bl,lastscreen
                jz      render0
                call    clear
                mov     lastscreen,bl
render0:
                cmp     firstscreen,1
                jne     render4
                mov     eax,001010101h
                mov     edi,offset dirtyname
                mov     ecx,32*24/4
                rep     stosd
                mov     firstscreen,0
                
render4:
                cmp     bl,0
                je      render_screen1
                cmp     bl,1
                je      render_screen2
                cmp     bl,4
                je      render_screen0
render2:
                ret

; clear --------------------------------------------------------------
; clear the blit buffer
                
clear:
                push    es
                mov     ax,ds
                mov     es,ax
                mov     eax,0
                mov     edi,blitbuffer
                mov     ecx,320*200/4
                rep     stosd
                mov     dx,03C8h
                mov     al,1
                out     dx,al
                inc     dx
                mov     al,0
                out     dx,al
                out     dx,al
                out     dx,al
                pop     es
                ret

; eval_sprite_coords -------------------------------------------------
; evaluate sprite coordinates
; enter: esi = start of sprite attribute in vram
; exit: eax = offset y ; ecx = offset x (both are signed numbers)

eval_sprite_coords:
                xor     ecx,ecx
                mov     al,[esi+3]
                mov     cl,[esi+1]
                and     eax,080h
                shr     eax,2
                sub     ecx,eax

                mov     al,[esi]
                cmp     al,0BEh
                jbe     eval_sprite_coords1
                movsx   eax,al

eval_sprite_coords1:
                inc     eax
                ret
                
; CHECK --------------------------------------------------------------
; mark one block as dirty

CHECK           macro   offx,offy,name

                push    ecx eax

                add     eax,offy
                js      check_sprite_&name&_exit
                cmp     eax,24
                jge     check_sprite_&name&_exit
                add     ecx,offx
                js      check_sprite_&name&_exit
                cmp     ecx,32
                jge     check_sprite_&name&_exit
                shl     eax,5
                add     eax,ecx
                add     eax,offset dirtyname
                mov     byte ptr [eax],1

check_sprite_&name&_exit:
                pop     eax ecx

                endm

; dirty_sprite -------------------------------------------------------
; make the screen behind the sprite dirty
; enter: eax = offset y ; ecx = offset x (both are signed numbers)

dirty_sprite:
                sar     eax,3
                js      dirty_sprite_crop_ecx
                cmp     eax,23-3
                jg      dirty_sprite_crop_ecx
                sar     ecx,3
                js      dirty_sprite_crop_all
                cmp     ecx,31-3
                jg      dirty_sprite_crop_all

dirty_sprite_fast:
                shl     eax,5
                add     eax,ecx
                add     eax,offset dirtyname
                or      dword ptr [eax],000010101h
                or      dword ptr [eax+32],000010101h
                or      dword ptr [eax+64],000010101h
                ret
                
dirty_sprite_crop_ecx:
                sar     ecx,3
dirty_sprite_crop_all:

                CHECK   0,0,0
                CHECK   1,0,1
                CHECK   2,0,2
                CHECK   0,1,3
                CHECK   1,1,4
                CHECK   2,1,5
                CHECK   0,2,6
                CHECK   1,2,7
                CHECK   2,2,8

                ret

; eval_base_address --------------------------------------------------
; evaluate the new bases for vdp tables

eval_base_address:

                ; first we need to determine the actual screen

                test    byte ptr [offset vdpregs+0],BIT_1
                jz      eval_base_address0

                ; M3 set - screen 2

                mov     actualscreen,2

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                and     al,80h
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,04h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/4
                add     edi,offset vrammapping
                rep     stosd

                mov     eax,02020202h
                mov     ecx,32*24*8/64/4
                mov     edi,patterntable
                shr     edi,6
                add     edi,offset vrammapping
                rep     stosd

                mov     eax,03030303h
                mov     ecx,32*24*8/64/4
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                rep     stosd

                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     [edi],ax

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64/4
                add     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen2_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen2_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen2_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen2_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen2_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen2_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx eax

                xor     eax,eax
                ret

eval_base_address0:

                test    byte ptr [offset vdpregs+1],(BIT_4 OR BIT_3)
                jnz     eval_base_address1

                ; M3,M2,M1 reset - screen 1

                mov     actualscreen,1

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,07h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/64/4
                add     edi,offset vrammapping
                rep     stosd
                
                mov     eax,02020202h
                mov     edi,patterntable
                shr     edi,6
                mov     ecx,256*8/64/4
                add     edi,offset vrammapping
                rep     stosd

                mov     al,03h
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                mov     [edi],al

                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     [edi],ax

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64/4
                add     edi,offset vrammapping
                rep     stosd
                
                mov     eax,offset dirty_screen1_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen1_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen1_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen1_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen1_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen1_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx eax

                xor     eax,eax
                ret

eval_base_address1:

                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 2

dirty_screen2_nothing:
                mov     [ecx+esi],bl
                ret

dirty_screen2_name:
                cmp     [ecx+esi],bl
                je      dirty_screen2_nothing
                mov     eax,ecx
                sub     ecx,nametable
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtyname+ecx],1
                xor     eax,eax
                ret

dirty_screen2_pattern:
                mov     eax,ecx
                sub     ecx,patterntable
                shr     ecx,3
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtypattern+ecx],1
                xor     eax,eax
                ret

dirty_screen2_color:
                mov     eax,ecx
                sub     ecx,colortable
                shr     ecx,3
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtypattern+ecx],1
                xor     eax,eax
                ret

dirty_screen2_sprattr:                
                mov     eax,ecx
                and     ecx,0FFFFFFFCh
                push    esi eax ecx
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                pop     ecx eax esi
                mov     [esi+eax],bl
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                xor     eax,eax
                ret

dirty_screen2_sprpatt:
                mov     eax,ecx
                sub     ecx,sprpatttable
                shr     ecx,5
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtysprite+ecx],1
                xor     eax,eax
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 1

dirty_screen1_nothing:
dirty_screen1_pattern:
dirty_screen1_color:
dirty_screen1_sprattr:
dirty_screen1_sprpatt:
                mov     [ecx+esi],bl
                ret

dirty_screen1_name:
                cmp     [eax+esi],bl
                je      dirty_screen1_nothing
                mov     eax,ecx
                sub     ecx,nametable
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtyname+ecx],1
                xor     eax,eax
                ret

; wash_sprite --------------------------------------------------------
; this function removes the "dirty" conditions of sprite 
; by passing the condition to the screen behind it

wash_sprite:

                mov     edx,32
                mov     esi,sprattrtable
                add     esi,msxvram
                xor     eax,eax

wash_sprite_loop:
                cmp     byte ptr [esi],0D0h
                je      wash_sprite_end
                mov     al,[esi+2]
                shr     al,2
                cmp     byte ptr [offset dirtysprite+eax],1
                jne     wash_sprite_next

                call    eval_sprite_coords
                call    dirty_sprite

wash_sprite_next:
                add     esi,4
                dec     edx
                jnz     wash_sprite_loop

wash_sprite_end:
                mov     edi,offset dirtysprite
                mov     eax,0
                mov     ecx,32/4
                rep     stosd
                ret

code32          ends
                end
