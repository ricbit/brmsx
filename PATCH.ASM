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

                ; patch not found
                inc     edi
                sub     ebp,4
                ret
; --------------------------------------------------------------------
; PHYDIO: read/write sectors

patch_PHYDIO:
                mov     iff1,1
                
                ; only drive A emulated
                cmp     dh,0
                jne     patch_PHYDIO_driveb

                ; if regb=0 then exit [security trap]
                cmp     regb,0
                je      emulC9

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

                ; read or write?
                and     dl,1
                jnz     patch_PHYDIO_writesector

patch_PHYDIO1:

                mov     ebp,512

patch_PHYDIO2:

                mov     al,byte ptr [esi]
                push    esi
                call    writemem
                pop     esi
                inc     esi
                inc     cx
                dec     ebp
                jnz     patch_PHYDIO2

                dec     regb
                jnz     patch_PHYDIO1

patch_PHYDIO_done:  
                pop     eax
                mov     regb,al
                mov     edx,0

                ; enable previous slot configuration
                mov     bl,saveslot
                call    outemulA8

                pop     ebp

                jmp     emulC9

patch_PHYDIO_driveb:
                or      dl,1
                mov     dh,2
                jmp     emulC9

patch_PHYDIO_readonly:
                or      dl,1
                mov     dh,0
                mov     regb,0
                jmp     emulC9

patch_PHYDIO_writesector:

                mov     ebp,512

patch_PHYDIO_writesector_loop:

                push    esi
                call    readmem
                pop     esi
                mov     byte ptr [esi],al
                inc     esi
                inc     cx
                dec     ebp
                jnz     patch_PHYDIO_writesector_loop

                dec     regb
                jnz     patch_PHYDIO_writesector

                jmp     patch_PHYDIO_done

; --------------------------------------------------------------------
; DSKCHG: update DPB when disk has changed

patch_DSKCHG:
                mov     regb,0
                mov     iff1,1
                jmp     patch_GETDPB

; --------------------------------------------------------------------
; GETDPB: adjust DPB by looking the data on boot sector

patch_GETDPB:
                mov     ecx,regehl
                inc     ecx

                ; format ID [F8-FF]
                mov     al,0F9h
                call    writemem
                inc     ecx

                ; sector size
                mov     al,0
                call    writemem
                inc     ecx
                
                mov     al,2
                call    writemem
                inc     ecx

                ; directory mask/shift
                mov     al,0fh
                call    writemem
                inc     ecx
                
                mov     al,04h
                call    writemem
                inc     ecx

                ; cluster mask/shift
                
                mov     al,1
                call    writemem
                inc     ecx
                
                mov     al,2
                call    writemem
                inc     ecx

                ; sector number of first fat
                mov     al,1
                call    writemem
                inc     ecx
                
                mov     al,0
                call    writemem
                inc     ecx

                ; number of fats
                mov     al,2
                call    writemem
                inc     ecx

                ; number of directory entries
                mov     al,70h
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

                mov     edx,0
                
                jmp     emulC9

; --------------------------------------------------------------------

code32          ends
                end


