; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: BLIT.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc
include vdp.inc
include io.inc

extrn blitbuffer: dword
extrn dirtyname: dword
extrn dirtypattern: dword

public blit

; DATA ---------------------------------------------------------------

; CODE ---------------------------------------------------------------

; blit ---------------------------------------------------------------
; copy the contents of blit buffer to pentium video memory

blit:              
                cmp     videomode,0
                je      blit0
                mov     edi,0a0000h
                mov     esi,blitbuffer
                sub     edi,_code32a
                mov     ecx,256*192/4
                rep     movsd                
                ret
blit0:
                cmp     imagetype,1
                je      blit_dirty_320

blit_linear_320:
                mov     esi,blitbuffer
                mov     edi,0a0000h+32
                sub     edi,_code32a
                mov     edx,192
blit0_0:
                mov     ecx,256/4
                rep     movsd
                add     edi,64
                dec     edx
                jnz     blit0_0
                ret

blit_dirty_320:
                cmp     lastscreen,4
                je      blit_linear_320
                mov     ebx,dirtyname
                mov     esi,blitbuffer
                mov     edi,0a0000h+32
                sub     edi,_code32a
                mov     ecx,24

blit_dirty_320_line:
                mov     edx,32

blit_dirty_320_char:

                mov     al,[ebx]
                or      al,al
                jz      blit_dirty_320_next
                mov     byte ptr [ebx],0

                irp     i,<0,1,2,3,4,5,6,7>

                mov     eax,[esi+i*256]
                mov     ebp,[esi+i*256+4]
                mov     [edi+i*320],eax
                mov     [edi+i*320+4],ebp

                endm

blit_dirty_320_next:

                inc     ebx
                add     esi,8
                add     edi,8
                dec     edx
                jnz     blit_dirty_320_char

                add     esi,8*256-8*32
                add     edi,8*320-8*32
                dec     ecx
                jnz     blit_dirty_320_line

                mov     eax,0
                mov     edi,dirtypattern
                mov     ecx,256*8/4
                rep     stosd

                ret



code32          ends
                end


