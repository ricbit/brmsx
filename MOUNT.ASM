; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: MOUNT.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pmode.inc

extrn mountdir_name: byte

public mount_disk_image

; DATA ---------------------------------------------------------------

align 4

filename        db      128 dup (0)
pos             dd      0

; mount_disk_image ---------------------------------------------------
; mount a directory pointed by mountdir_name
; into the diskimage

mount_disk_image:

                ; find the end of the mountdir_name string
                mov     esi,offset mountdir_name                
mount_disk_name_loop:
                mov     al,[esi]
                or      al,al
                jz      mount_disk_found
                inc     esi
                jmp     mount_disk_name_loop

                ; append the name with "\*.*"
mount_disk_found:
                mov     dword ptr [esi],'*.*\'
                mov     byte ptr [esi+4],0
                mov     eax,offset mountdir_name
                call    printnul
                call    crlf

                mov     edi,offset mountdir_name
                mov     edx,offset filename
                call    find_first

mount_disk_outer_loop:
                jc      _ret
                mov     eax,offset filename
                call    printnul
                call    crlf
                mov     edi,offset mountdir_name
                mov     edx,offset filename
                call    find_next
                jmp     mount_disk_outer_loop

                ret

code32          ends
                end


