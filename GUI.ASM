; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: 
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include z80.inc
include io.inc
include number.inc

extrn blitbuffer: dword
extrn dirtyname: dword

public rendercounter
public spritecounter
public blitcounter
public guicounter

public renderrate
public spriterate
public blitrate
public guirate

public draw_gui

; DATA ---------------------------------------------------------------

rendercounter   db      8 dup (0)
spritecounter   db      8 dup (0)
blitcounter     db      8 dup (0)
guicounter      db      8 dup (0)

renderrate      dd      0
spriterate      dd      0
blitrate        dd      0
guirate         dd      0

; CODE ---------------------------------------------------------------

; draw_gui -----------------------------------------------------------
; draw the gui in blitbuffer

draw_gui:
                cmp     bargraphmode,0
                je      _ret
                mov     edi,0
                mov     eax,z80rate
                call    drawline
                mov     edi,8
                mov     eax,renderrate
                call    drawline
                mov     edi,16
                mov     eax,spriterate
                call    drawline
                mov     edi,24
                mov     eax,blitrate
                call    drawline
                mov     edi,32
                mov     eax,guirate
                call    drawline
                mov     eax,0FFFFFFFFh
                mov     edi,dirtyname
                irp     j,<0,1,2,3,4>
                mov     [edi+j*32],eax
                mov     [edi+4+j*32],eax
                endm
                ret

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

                sub     edi,30
                mov     ebx,10
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
                mov     esi,edx
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
                ret


code32          ends
                end


