; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: SAVELOAD.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc

extrn msxram: dword
extrn msxvram: dword
extrn transf_buffer: dword
extrn writemessage: near

public save_state
public load_state

; DATA ---------------------------------------------------------------

filename        db      'BRMSX.STA',0
fileid          db      'MSXSTATE',26,0
msgfnf          db      'File not found$'

; WRITE_DWORD --------------------------------------------------------
; write a word in the state file, but by reading a dword

WRITE_DWORD     macro   dword_data
                
                mov     eax,dword_data
                mov     edx,transf_buffer
                mov     [edx],ax
                mov     ecx,2
                call    write_file

                endm

; READ_DWORD ---------------------------------------------------------
; read a word from the state file, placing in a dword

READ_DWORD      macro   dword_data
                
                mov     edx,transf_buffer
                mov     ecx,2
                call    read_file
                xor     eax,eax
                mov     edx,transf_buffer
                mov     ax,[edx]
                mov     dword_data,eax

                endm

; WRITE_BYTE ---------------------------------------------------------
; write a byte in the state file

WRITE_BYTE      macro   byte_data
                
                mov     al,byte_data
                mov     edx,transf_buffer
                mov     [edx],al
                mov     ecx,1
                call    write_file

                endm

; READ_BYTE ----------------------------------------------------------
; read a byte from the state file

READ_BYTE       macro   byte_data
                
                mov     edx,transf_buffer
                mov     ecx,1
                call    read_file
                mov     edx,transf_buffer
                mov     al,[edx]
                mov     byte_data,al

                endm

; WRITE_IMM ----------------------------------------------------------
; write a immediate byte loaded in al in the state file

WRITE_IMM       macro   
                
                mov     edx,transf_buffer
                mov     [edx],al
                mov     ecx,1
                call    write_file

                endm

; READ_IMM -----------------------------------------------------------
; read a immediate byte from the state file and store it in al

READ_IMM        macro   
                
                mov     edx,transf_buffer
                mov     ecx,1
                call    read_file
                mov     edx,transf_buffer
                mov     al,[edx]

                endm

; custom_write -------------------------------------------------------
; write to a file pointed in v86r_bx
; but first move the data to the low memory transfer buffer

custom_write:
                push    ecx
                mov     esi,edx
                mov     edi,transf_buffer
                rep     movsb
                pop     ecx
                mov     edx,transf_buffer
                jmp     write_file

; custom_read --------------------------------------------------------
; read from a file pointed in v86r_bx
; the data is then moved from the transf buffer to location
; pointed by edx

custom_read:
                push    ecx edx
                mov     edx,transf_buffer
                call    read_file
                pop     edx ecx
                mov     esi,transf_buffer
                mov     edi,edx
                rep     movsb
                ret

; save_state ---------------------------------------------------------
; save the entire state of MSX machine in
; a file called "BRMSX.STA"

save_state:
                mov     edx,offset filename
                call    create_file

; --------------------------------------------------------------------
                
                ; write the file ID and the version

                mov     edx,offset fileid
                mov     ecx,10
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of Z80 registers

                WRITE_DWORD     regeaf
                WRITE_DWORD     regebc
                WRITE_DWORD     regede
                WRITE_DWORD     regehl
                WRITE_DWORD     regepc
                WRITE_DWORD     regesp
                WRITE_DWORD     regeix
                WRITE_DWORD     regeiy
                WRITE_DWORD     regeafl
                WRITE_DWORD     regebcl
                WRITE_DWORD     regedel
                WRITE_DWORD     regehll
                WRITE_BYTE      regi
                
                mov     eax,rcounter
                and     al,07Fh
                or      al,rmask
                WRITE_IMM

                mov     eax,iff1
                WRITE_IMM

                mov     al,1
                WRITE_IMM
                WRITE_IMM

; --------------------------------------------------------------------
                
                ; write the contents of VDP registers

                mov     edx,offset vdpregs
                mov     ecx,8
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of PPI registers

                WRITE_BYTE      prim_slotreg

                mov     al,0FFh
                WRITE_IMM

                WRITE_BYTE      ppic

                mov     al,082h
                WRITE_IMM

; --------------------------------------------------------------------
                
                ; write the contents of megarom block selectors

                irp     i,<0,1,2,3,4,5,6,7>

                mov     eax,dword ptr [offset megablock+i*4]
                WRITE_IMM

                endm

; --------------------------------------------------------------------
                
                ; write the contents of the RAM

                mov     edx,msxram
                mov     ecx,32768
                call    custom_write

                mov     edx,msxram
                add     edx,32768
                mov     ecx,32768
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of the VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_write

; --------------------------------------------------------------------
                
                call    close_file
                ret

; load_state ---------------------------------------------------------
; load the entire state of MSX machine from
; a file called "BRMSX.STA"


load_state:

                mov     edx,offset filename
                call    open_file
                jc      file_not_found

; --------------------------------------------------------------------

                ; skip file ID
                
                mov     edx,transf_buffer
                mov     ecx,10
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of Z80 registers

                READ_DWORD      regeaf
                READ_DWORD      regebc
                READ_DWORD      regede
                READ_DWORD      regehl
                READ_DWORD      regepc
                READ_DWORD      regesp
                READ_DWORD      regeix
                READ_DWORD      regeiy
                READ_DWORD      regeafl
                READ_DWORD      regebcl
                READ_DWORD      regedel
                READ_DWORD      regehll
                READ_BYTE       regi

                READ_IMM
                push    eax
                and     eax,0FFh
                mov     rcounter,eax
                pop     eax
                and     eax,080h
                mov     rmask,al

                READ_IMM
                and     eax,0FFh
                mov     iff1,eax

                READ_IMM
                READ_IMM

; --------------------------------------------------------------------
                
                ; read the contents of VDP registers

                mov     edx,offset vdpregs
                mov     ecx,8
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of PPI registers

                READ_BYTE       prim_slotreg
                READ_IMM
                READ_BYTE       ppic
                READ_IMM

; --------------------------------------------------------------------
                
                ; read the contents of megarom block selectors

                irp     i,<0,1,2,3,4,5,6,7>

                READ_IMM
                mov     esi,i
                and     eax,0FFh
                call    megarom0_switchbank

                endm

; --------------------------------------------------------------------
                
                ; read the contents of RAM

                mov     edx,msxram
                mov     ecx,32768
                call    custom_read

                mov     edx,msxram
                add     edx,32768
                mov     ecx,32768
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_read

; --------------------------------------------------------------------

                ; adjust the slot selection

                mov     bl,prim_slotreg
                call    outemulA8

; --------------------------------------------------------------------
                
                call    close_file
                ret

; --------------------------------------------------------------------

file_not_found:
                mov     eax,offset msgfnf
                jmp     writemessage

code32          ends
                end


