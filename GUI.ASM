; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: GUI.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include z80.inc
include io.inc
include number.inc
include vdp.inc
include blit.inc

extrn blitbuffer: dword

public rendercounter
public spritecounter
public blitcounter
public guicounter
public psgcounter

public renderrate
public spriterate
public blitrate
public guirate
public psgrate

public draw_gui
public start_gui

; DATA ---------------------------------------------------------------

include logo.inc

align 4

rendercounter   db      8 dup (0)
spritecounter   db      8 dup (0)
blitcounter     db      8 dup (0)
guicounter      db      8 dup (0)
psgcounter      db      8 dup (0)

z80acc          db      8 dup (0)
renderacc       db      8 dup (0)
spriteacc       db      8 dup (0)
blitacc         db      8 dup (0)
guiacc          db      8 dup (0)
psgacc          db      8 dup (0)

renderrate      dd      0
spriterate      dd      0
blitrate        dd      0
guirate         dd      0
psgrate         dd      0

z80number       dd      0
rendernumber    dd      0
spritenumber    dd      0
blitnumber      dd      0
guinumber       dd      0
psgnumber       dd      0

framenumber     dd      0

; CODE ---------------------------------------------------------------

; draw_gui -----------------------------------------------------------
; draw the gui in blitbuffer

draw_gui:
                cmp     bargraphmode,0
                je      _ret

; --------------------------------------------------------------------
                
                ; draw the bar graph

                mov     edi,0
                mov     ebp,z80number
                mov     eax,z80rate
                call    drawline
                mov     edi,8
                mov     ebp,rendernumber
                mov     eax,renderrate
                call    drawline
                mov     edi,16
                mov     ebp,spritenumber
                mov     eax,spriterate
                call    drawline
                mov     edi,24
                mov     ebp,blitnumber
                mov     eax,blitrate
                call    drawline
                mov     edi,32
                mov     ebp,guinumber
                mov     eax,guirate
                call    drawline
                mov     edi,40
                mov     ebp,psgnumber
                mov     eax,psgrate
                call    drawline
                
; --------------------------------------------------------------------
                
                ; update the counters

                mov     eax,z80rate
                mov     ebx,offset z80acc
                mov     ecx,offset z80number
                call    evalcounter

                mov     eax,renderrate
                mov     ebx,offset renderacc
                mov     ecx,offset rendernumber
                call    evalcounter

                mov     eax,spriterate
                mov     ebx,offset spriteacc
                mov     ecx,offset spritenumber
                call    evalcounter

                mov     eax,blitrate
                mov     ebx,offset blitacc
                mov     ecx,offset blitnumber
                call    evalcounter

                mov     eax,guirate
                mov     ebx,offset guiacc
                mov     ecx,offset guinumber
                call    evalcounter

                mov     eax,psgrate
                mov     ebx,offset psgacc
                mov     ecx,offset psgnumber
                call    evalcounter

                inc     framenumber
                cmp     framenumber,10
                jne     draw_update0
                mov     framenumber,0
draw_update0:

; --------------------------------------------------------------------
                
                ; update the dirty table

                mov     eax,001010101h
                mov     ebx,000010101h
                mov     edi,offset dirtyname
                irp     j,<0,1,2,3,4,5>
                or      [edi+j*32],eax
                or      [edi+4+j*32],ebx
                endm

                ret

; drawline -----------------------------------------------------------
; draw a single bar in blitbuffer

drawline:
                mov     ebx,100
                mul     ebx                
                xor     edx,edx
                mov     ebx,dword ptr [offset clockrate]
                div     ebx
                mov     ecx,50
                mov     esi,eax
                shr     esi,1
                shl     edi,8
                add     edi,blitbuffer
                mov     ebx,0F0Dh
drawline1:      
                cmp     ecx,esi
                jbe     drawline2
                irp     i,<0,1,2,3,4,5,6>
                mov     byte ptr [edi+256*i],bh
                endm
                jmp     drawline_loop
drawline2:
                irp     i,<0,1,2,3,4,5,6>
                mov     byte ptr [edi+256*i],bl
                endm
drawline_loop:
                inc     edi
                dec     ecx
                jnz     drawline1

                mov     eax,ebp
                sub     edi,33
                mov     ebx,100
                xor     edx,edx
                div     ebx
                mov     esi,eax
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256],ebx
                and     [edi+(i+1)*256+4],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256],ebx
                or      [edi+(i+1)*256+4],ecx
                endm
                
                mov     eax,edx
                mov     ebx,10
                xor     edx,edx
                div     ebx
                mov     esi,eax
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256+5],ebx
                and     [edi+(i+1)*256+4+5],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256+5],ebx
                or      [edi+(i+1)*256+4+5],ecx
                endm
                
                mov     byte ptr [edi+5*256+10],04h

                mov     esi,edx
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256+12],ebx
                and     [edi+(i+1)*256+4+12],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256+12],ebx
                or      [edi+(i+1)*256+4+12],ecx
                endm
                
                ret

; evalcounter --------------------------------------------------------
; update a counter

evalcounter:
                add     dword ptr [ebx],eax
                adc     dword ptr [ebx+4],0
                cmp     framenumber,0
                jnz     _ret

                mov     eax,dword ptr [ebx]
                mov     edi,100
                mul     edi
                mov     esi,edx
                mov     dword ptr [ebx],eax
                mov     eax,dword ptr [ebx+4]
                mul     edi
                add     eax,esi
                mov     dword ptr [ebx+4],eax

                mov     eax,dword ptr [ebx]
                mov     edx,dword ptr [ebx+4]
                mov     edi,dword ptr [offset clockrate]
                div     edi
                mov     dword ptr [ecx],eax

                mov     dword ptr [ebx],0
                mov     dword ptr [ebx+4],0

                ret

; start_gui ----------------------------------------------------------
; start the gui

start_gui:
                ; update palette
                
                mov     ebx,offset gui_palette
                mov     ecx,256
                call    fill_palette

                mov     firstscreen,1
                call    render
                call    sprite_render

                ; draw logo

                mov     edi,135*256
                add     edi,blitbuffer
                mov     esi,offset logo_bitmap
                mov     ecx,57

start_gui_drawlogo:
                mov     ebx,89

start_gui_drawlogo_loop:
                mov     al,[esi]
                or      al,al
                jz      start_gui_drawlogo_next

                mov     [edi],al

start_gui_drawlogo_next:
                inc     edi
                inc     esi
                dec     ebx
                jnz     start_gui_drawlogo_loop

                add     edi,256-89
                dec     ecx
                jnz     start_gui_drawlogo

                call    set_border_color_dark
                call    blit

start_gui_loop:
                cmp     cpupaused,1
                je      start_gui_loop
                
                mov     firstscreen,1
                mov     ebx,offset palette
                mov     ecx,16
                call    fill_palette

                ret

code32          ends
                end


