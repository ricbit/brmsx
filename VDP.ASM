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
include io.inc

extrn msxvram: dword
extrn vdpregs: near
extrn blitbuffer: dword

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
public enabled
public enginetype

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
falsesprite     db      2*256 dup (0)
spriteline      db      192 dup (0)
lastscreen      db      0
actualscreen    db      0
enginetype      dd      1

DOS_ENGINE      EQU     0
WIN_ENGINE      EQU     1
MMX_ENGINE      EQU     2

; render_screen0 -----------------------------------------------------
; render a screen 0 page

render_screen0:
                mov     esi,msxvram                
                add     esi,nametable
                
                mov     ebx,msxvram
                add     ebx,patterntable
                
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

                call    wash_sprite
                
                ; esi = name table
                mov     esi,nametable
                add     esi,msxvram

                ; ebx = character pattern table
                
                mov     ebx,patterntable
                add     ebx,msxvram

                ; ecx = color table
                mov     ecx,colortable
                add     ecx,msxvram

                ; edi = blit buffer
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
                jnz     render1_dirty_draw

                movzx   eax,byte ptr [esi]
                cmp     byte ptr [offset dirtypattern+eax],1
                jne     render1_dirty_next
                mov     byte ptr [edx],1

render1_dirty_draw:
                push    edx
                PIPE1
                pop     edx

render1_dirty_next:

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

                ; edi = blit buffer
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

; render_screen2_dirty (macro version) -------------------------------

RENDER_SCREEN2_DIRTY_MACRO macro videoengine

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

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; edx = dirty table name
                ; ebx = dirty table pattern
                mov     edx,offset dirtyname
                mov     ebx,offset dirtypattern

                ; mask the temporary registers
                xor     eax,eax

                ; for each sector
                mov     ebp,3

EMULABEL        render23d,videoengine

                push    ebp

                if      (videoengine EQ DOS_ENGINE)
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8

EMULABEL        render20d,videoengine

                push    ebp

                ; for each char
                mov     ebp,32

EMULABEL        render21d,videoengine

                mov     al,[edx]
                or      al,al
                JUMP    jnz,render2d_draw,videoengine

                mov     al,[esi]
                cmp     byte ptr [ebx+eax],0
                JUMP    je,render2d_next,videoengine
                mov     byte ptr [edx],1


EMULABEL        render2d_draw,videoengine

                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi

                push    ebx
                push    edx

                xor     edx,edx
                mov     ebx,patternsave

                if      (videoengine EQ DOS_ENGINE)
                  PIPE2_DOS
                else
                  if (videoengine EQ MMX_ENGINE)
                    PIPE2_MMX
                  else
                    PIPE2_WIN
                  endif
                endif

                pop     edx
                pop     ebx

                pop     esi
                pop     ebp
                
EMULABEL        render2d_next,videoengine

                inc     esi
                add     edi,8
                inc     edx
                dec     ebp
                JUMP    jnz,render21d,videoengine

                pop     ebp
                add     edi,256*7
                dec     ebp
                JUMP    jnz,render20d,videoengine

                add     ebx,256                                         
                add     patternsave,256*8
                add     colorsave,256*8

                pop     ebp
                dec     ebp
                JUMP    jnz,render23d,videoengine

                mov     spriteenable,1
                ret

                endm

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

                mov     dl,[esi+i+1]
                
                ;;movq    MM1,MM0
                movq
                db      11001000b

                ; blend with the foreground color
                ;;pand    MM0,[offset foregroundcolor_MMX+eax*8]
                pand
                db      00000100b
                db      11000101b
                dd      offset foregroundcolor_MMX
                
                ; blend with the background color
                ;;pandn    MM1,[offset backgroundcolor_MMX+eax*8]
                pandn
                db      00001100b
                db      11000101b
                dd      offset backgroundcolor_MMX
                
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

; macro definitions --------------------------------------------------

EMULABEL           macro   name,engine

name&_&engine:

                endm

JUMP            macro   jump,name,engine

                jump    name&_&engine

                endm

; render_screen2_dirty -----------------------------------------------
; render a screen 2 page using dirty blocks
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2_dirty:

                cmp     enginetype,0
                jne     render_screen2_dirty_win
                RENDER_SCREEN2_DIRTY_MACRO DOS_ENGINE

render_screen2_dirty_win:
                cmp     enginetype,1
                jne     render_screen2_dirty_mmx
                RENDER_SCREEN2_DIRTY_MACRO WIN_ENGINE

render_screen2_dirty_mmx:
                RENDER_SCREEN2_DIRTY_MACRO MMX_ENGINE

; render_screen2 (macro version) -------------------------------------

RENDER_SCREEN2_MACRO macro videoengine                
                
                cmp     imagetype,1
                je      render_screen2_dirty

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

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; mask the temporary registers
                xor     eax,eax
                xor     edx,edx

                ; for each sector
                mov     ebp,3

EMULABEL        render23,videoengine

                push    ebp

                if   (videoengine EQ DOS_ENGINE)
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8

EMULABEL        render20,videoengine
                
                push    ebp

                ; for each char
                mov     ebp,32

EMULABEL        render21,videoengine
                
                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi

                if (videoengine EQ DOS_ENGINE)
                  PIPE2_DOS
                else
                  if (videoengine EQ MMX_ENGINE)
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
                JUMP    jnz,render21,videoengine

                pop     ebp
                add     edi,256*7
                dec     ebp
                JUMP    jnz,render20,videoengine

                add     ebx,256*8
                add     colorsave,256*8

                pop     ebp
                dec     ebp
                JUMP    jnz,render23,videoengine

                mov     spriteenable,1
                ret

                endm

; render_screen2 -----------------------------------------------------
; render a screen 2 page
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2:
                
                cmp     enginetype,0
                jne     render_screen2_win
                RENDER_SCREEN2_MACRO DOS_ENGINE

render_screen2_win:
                cmp     enginetype,1
                jne     render_screen2_mmx
                RENDER_SCREEN2_MACRO WIN_ENGINE

render_screen2_mmx:
                RENDER_SCREEN2_MACRO MMX_ENGINE


; render_screen3 -----------------------------------------------------
; render a screen 3 page

render_screen3:
                mov     edi,blitbuffer

                mov     ecx,nametable
                add     ecx,msxvram

                mov     esi,patterntable
                add     esi,msxvram

                mov     eax,0
                mov     edx,0

                mov     ebp,6
render_screen3_outerloop:
                push    ebp

                irp     i,<0,1,2,3,4,5,6,7>

                mov     ebx,0
render_screen3_innerloop_&i:
                
                mov     al,[ecx]
                
                mov     dl,[esi+eax*8+i]
                mov     ebp,[offset foregroundcolor+edx*4]
                irp     j,<0,1,2,3>
                mov     [edi+j*256],ebp
                endm
                
                mov     ebp,[offset backgroundcolor+edx*4]
                irp     j,<0,1,2,3>
                mov     [edi+j*256+4],ebp
                endm

                add     edi,8
                inc     ecx

                inc     ebx
                cmp     ebx,32
                jne     render_screen3_innerloop_&i

                add     edi,3*256
                add     ecx,((i AND 1)*32)-32

                endm

                pop     ebp
                dec     ebp
                jnz     render_screen3_outerloop

                mov     spriteenable,1
                ret

; sprite_render ------------------------------------------------------
; draw the sprites directly on the blit buffer

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
                ;call    clear_sprite_buffer
                
                ; esi = sprite attribute table
                mov     esi,msxvram
                add     esi,sprattrtable

                ; ecx = sprite image table
                mov     ecx,msxvram
                add     ecx,sprpatttable

                ; edi = blit buffer
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
                jz      _ret

                ; for each sprite
sprite16N1:     push    ecx eax

                ; check if the sprite is transparent
                mov     cl,[esi+3]
                and     cl,0Fh
                jz      sprite16N3

                call    eval_sprite_coords
                cmp     ecx,0
                js      sprite_crop
                cmp     ecx,256-16
                jge     sprite_crop
                cmp     eax,0
                jl      sprite_crop
                cmp     eax,192-16
                jge     sprite_crop

                ;;;
                jmp     sprite_crop
                
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

                ; get the contents of blit buffer
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

sprite_crop:
                ; address of sprite image
                movzx   eax,byte ptr [esi+2]
                and     al,11111100b
                mov     ecx,sprpatttable
                add     ecx,msxvram
                lea     ecx,[ecx+eax*8]

                ; color mask
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,16
                mov     edi,offset falsesprite
                mov     ebx,0

                push    esi ebp
                
sprite_crop_loop:

                ; fetch the image for the subline
                mov     bl,[ecx]

                ; get the sprite mask
                mov     esi,[offset backgroundmask+ebx*8]

                ; get the sprite color
                mov     ebp,eax

                ; blend with the sprite image
                and     ebp,[offset foregroundmask+ebx*8]

                ; put back to screen
                mov     [edi],esi
                mov     [edi+4],ebp

                ; do it again for the next four pixels
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+8],esi
                mov     [edi+4+8],ebp
                
                ; do it again for the next eight pixels
                
                mov     bl,[ecx+16]
                
                mov     esi,[offset backgroundmask+ebx*8]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8]
                mov     [edi+16],esi
                mov     [edi+4+16],ebp
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+16+8],esi
                mov     [edi+4+16+8],ebp
                
                add     edi,32
                inc     ecx
                dec     edx
                jnz     sprite_crop_loop

                pop     ebp esi

                call    eval_sprite_coords                
                push    esi ebp
                mov     esi,offset falsesprite
                mov     edx,16
                mov     edi,eax
                sal     edi,8
                add     edi,blitbuffer
                add     edi,ecx
                cmp     ecx,256-16
                jae     sprite_crop_draw_x

sprite_crop_draw:
                cmp     eax,192
                jae     sprite_crop_draw_nextline
                
                irp     i,<0,1,2,3>

                mov     ebp,[edi+i*4]
                and     ebp,[esi+i*8]
                or      ebp,[esi+i*8+4]
                mov     [edi+i*4],ebp

                endm

sprite_crop_draw_nextline:
                add     esi,32
                add     edi,256
                inc     eax
                dec     edx
                jnz     sprite_crop_draw

                pop     ebp esi
                jmp     sprite16N3

sprite_crop_draw_x:
                cmp     eax,192
                jae     sprite_crop_draw_x_nextline

                mov     ebp,0
                mov     bh,4

sprite_crop_draw_x_loop:
                push    ecx
                add     ecx,ebp
                cmp     ecx,255
                ja      sprite_crop_draw_x_nextpixel

                mov     bl,[edi]
                and     bl,[esi]
                or      bl,[esi+4]
                mov     [edi],bl

sprite_crop_draw_x_nextpixel:
                dec     bh
                jnz     sprite_crop_draw_x_nocorrection
                add     esi,4
                mov     bh,4

sprite_crop_draw_x_nocorrection:
                pop     ecx                
                inc     esi
                inc     edi
                inc     ebp
                cmp     ebp,16
                jne     sprite_crop_draw_x_loop

sprite_crop_draw_x_nextline:
                add     edi,256-16
                inc     eax
                dec     edx
                jnz     sprite_crop_draw_x

                pop     ebp esi
                jmp     sprite16N3

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
                test    byte ptr [offset vdpregs+1],BIT_6
                jnz     render_enabled

                ; video is disabled
                cmp     enabled,0
                je      _ret

                mov     enabled,0
                jmp     clear

render_enabled:
                ; video is enabled
                cmp     enabled,0
                jne     render_check_screen

                ; video is enabled after being disabled for a while
                ; now it must be fully restored
                mov     firstscreen,1

render_check_screen:
                mov     enabled,1
                
                ; check if the SCREEN mode has changed
                mov     bl,actualscreen
                cmp     bl,lastscreen
                je      render_check_first

                ; SCREEN mode has changed
                ; clear blitbuffer to avoid border problems
                ; also copy a new palette
                mov     lastscreen,bl
                call    clear
                call    set_correct_palette

render_check_first:
                cmp     firstscreen,1            
                jne     render_draw

                ; first screen after a major change in display
                ; must update all the display
                mov     firstscreen,0
                mov     eax,01010101h
                mov     edi,offset dirtyname
                mov     ecx,32*24/4
                rep     stosd

                ; check if the GUI is enabled
                cmp     cpupaused,1
                je      render_draw

                ; GUI is not enabled: update the border color
                call    set_border_color

render_draw:
                mov     bl,actualscreen

                cmp     bl,0
                je      render_screen0

                cmp     bl,1
                je      render_screen1

                cmp     bl,2
                je      render_screen2

                cmp     bl,3
                je      render_screen3

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
                pop     es
                ret

; eval_sprite_coords -------------------------------------------------
; evaluate sprite coordinates
; enter: esi = start of sprite attribute in vram
; exit: eax = offset y ; ecx = offset x (both are signed numbers)

eval_sprite_coords:
                xor     ecx,ecx
                mov     al,[esi+3]      ; "early clock" attribute
                mov     cl,[esi+1]      ; x coordinate
                and     eax,080h
                shr     eax,2
                sub     ecx,eax

                mov     al,[esi]        ; y coordinate
                cmp     al,0F0h         ; 0BEh ??
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
                jz      eval_base_address_scr1

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
                mov     ecx,32*24/64/4
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

eval_base_address_scr1:

                test    byte ptr [offset vdpregs+1],(BIT_4 OR BIT_3)
                jnz     eval_base_address_scr0

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

eval_base_address_scr0:
                test    byte ptr [offset vdpregs+1],BIT_4
                jz      eval_base_address_scr3

                ; M3,M1 set, M2 reset - screen 0

                mov     actualscreen,0

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
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

eval_base_address_scr3:
                
                ; M3,M2 set, M1 reset - screen 3
                
                mov     actualscreen,3

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
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen3_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen3_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen3_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen3_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen3_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen3_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx
                xor     eax,eax
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
                and     eax,03h
                jnz     dirty_screen2_sprattr2
                cmp     bl,0D0h
                jne     dirty_screen2_sprattr2
                mov     firstscreen,1
                mov     [ecx+esi],bl
                mov     eax,0
                ret
dirty_screen2_sprattr2:
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
                mov     [ecx+esi],bl
                ret

dirty_screen1_name:
                cmp     [ecx+esi],bl
                je      _ret
                mov     eax,ecx
                sub     ecx,nametable
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtyname+ecx],1
                xor     eax,eax
                ret

dirty_screen1_pattern:
                mov     eax,ecx
                sub     ecx,patterntable
                shr     ecx,3
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtypattern+ecx],1
                xor     eax,eax
                ret

dirty_screen1_color:
                mov     eax,ecx
                sub     ecx,colortable
                shl     ecx,3
                mov     [eax+esi],bl
                mov     ebx,01010101h
                ; there is no problem because the two upper
                ; dirty pattern tables aren't used in scr1
                mov     dword ptr [offset dirtypattern+ecx],ebx
                mov     dword ptr [offset dirtypattern+ecx+4],ebx
                xor     eax,eax
                ret

dirty_screen1_sprattr:
                mov     eax,ecx
                and     eax,03h
                jnz     dirty_screen1_sprattr2
                cmp     bl,0D0h
                jne     dirty_screen1_sprattr2
                mov     firstscreen,1
                mov     [ecx+esi],bl
                ret
dirty_screen1_sprattr2:
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

dirty_screen1_sprpatt:
                mov     eax,ecx
                sub     ecx,sprpatttable
                shr     ecx,5
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtysprite+ecx],1
                xor     eax,eax
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 0

dirty_screen0_nothing:
dirty_screen0_name:
dirty_screen0_color:
dirty_screen0_pattern:
dirty_screen0_sprpatt:
dirty_screen0_sprattr:
                mov     [ecx+esi],bl
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 3

dirty_screen3_nothing:
dirty_screen3_name:
dirty_screen3_color:
dirty_screen3_pattern:
dirty_screen3_sprpatt:
dirty_screen3_sprattr:
                mov     [ecx+esi],bl
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
                ;cmp     byte ptr [esi],0D0h
                ;je      wash_sprite_end
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
