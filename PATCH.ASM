; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PATCH.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc

extrn emulC9: near
extrn diskimage: dword

public emulEDFF

; DATA ---------------------------------------------------------------

align 4

boot:           db      512 dup (0)
saveslot        db      0

; --------------------------------------------------------------------

; emulEDFF -----------------------------------------------------------
; main patch selector
; select patch through the PC

emulEDFF:
                cmp     edi,04010h+1
                je      patch_PHYDIO

                cmp     edi,04013h+1
                je      patch_DSKCHG

                cmp     edi,04016h+1
                je      patch_GETDPB

                jmp     emulC9

patch_PHYDIO:
                ; only drive A emulated
                cmp     dh,0
                jne     emulC9

                ; if regb=0 then exit [security trap]
                cmp     regb,0
                je      emulC9

                ; read or write?
                and     dl,1
                jnz     emulC9

                push    ebp

                ; enable all RAM
                
                mov     al,prim_slotreg
                mov     saveslot,al
                mov     bl,0AAh
                call    outemulA8

                ; find initial offset on disk image
                mov     esi,regede
                shl     esi,9
                add     esi,diskimage
                mov     ecx,regehl
                mov     al,regb
                push    eax

patch_PHYDIO1:

                mov     ebp,512

patch_PHYDIO2:

                mov     al,byte ptr [esi]
                push    esi
                call    writemem
                pop     esi
                inc     esi
                inc     ecx
                dec     ebp
                jnz     patch_PHYDIO2

                dec     regb
                jnz     patch_PHYDIO1

                pop     eax
                mov     regb,al
                mov     edx,0

                ; enable previous slot configuration
                mov     bl,saveslot
                call    outemulA8

                pop     ebp

                jmp     emulC9


patch_DSKCHG:
                mov     regb,0
                and     dl,NBIT_0
                jmp     patch_GETDPB

patch_GETDPB:
                mov     esi,diskimage
                mov     edi,offset boot
                mov     ecx,512/4
                rep     movsd
                mov     edi,offset boot
                mov     ecx,regehl
                inc     ecx

                ; format ID [F8-FF]
                mov     al,byte ptr [edi+015h]
                call    writemem
                inc     ecx

                ; sector size
                mov     al,byte ptr [edi+0bh]
                call    writemem
                inc     ecx
                mov     al,byte ptr [edi+0ch]
                call    writemem
                inc     ecx

                ; directory mask/shift
                movzx   ebx,word ptr [edi+0bh]
                shr     ebx,5
                dec     ebx
                mov     al,bl
                call    writemem
                inc     ecx
                call    patch_GETDPB1
                call    writemem
                inc     ecx

                ; cluster mask/shift
                mov     bl,byte ptr [edi+0dh]
                dec     bl
                mov     al,bl
                call    writemem
                inc     ecx
                call    patch_GETDPB1
                inc     al
                call    writemem
                inc     ecx

                ; sector number of first fat
                mov     al,byte ptr [edi+0eh]
                call    writemem
                inc     ecx
                mov     al,byte ptr [edi+0fh]
                call    writemem
                inc     ecx

                ; number of fats
                mov     al,byte ptr [edi+10h]
                call    writemem
                inc     ecx

                ; number of directory entries
                mov     al,byte ptr [edi+11h]
                call    writemem
                inc     ecx

                ; daqui pra frente torrou o saco
                ; sector number of data
                mov     al,0eh
                call    writemem
                inc     ecx
                mov     al,0
                call    writemem
                inc     ecx

                ; number of clusters
                mov     al,0c9h
                call    writemem
                inc     ecx
                mov     al,02h
                call    writemem
                inc     ecx

                ; sectors per fat
                mov     al,03h
                call    writemem
                inc     ecx

                ; sector number of directory
                mov     al,07h
                call    writemem
                inc     ecx
                mov     al,0
                call    writemem
                inc     ecx
                and     dl,NBIT_0
                
                jmp     emulC9

patch_GETDPB1:
                push    ecx
                mov     cl,0
patch_GETDPB3:
                push    eax
                mov     bh,1
                shl     bh,cl
                and     al,bh
                pop     eax
                jz      patch_GETDPB2
                inc     cl
                jmp     patch_GETDPB3
patch_GETDPB2:
                mov     al,cl
                pop     ecx
                ret

code32          ends
                end


