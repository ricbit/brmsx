; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: VESA.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc
include io.inc
include bit.inc

extrn vesaheader: dword
extrn vesamodeinfo: dword

public init_vesa
public search_vesa_mode
public set_vesa_mode
public vesalinearbuffer
public set_vesa_bank

; DATA ---------------------------------------------------------------

align 4

vesalinearbuffer        dd      0
vesamodenumber          dd      0
vesaselector            dw      0

; --------------------------------------------------------------------

; init_vesa ----------------------------------------------------------
; looks for VESA driver and return NC if found

init_vesa:
                ; init the header with VESA2 identifier
                mov     ebx,'2EBV'
                mov     eax,vesaheader
                mov     [eax],ebx

                ; convert vesaheader to real mode pointer
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call int 10h
                mov     v86r_ax,04F00h
                mov     al,10h
                int     33h

                cmp     v86r_al,04Fh
                jne     error_no_vesa

                mov     eax,vesaheader
                cmp     [eax],'ASEV'
                jne     error_no_vesa

                or      eax,eax                

                ret

error_no_vesa:
                stc
                ret

; search_vesa_mode ---------------------------------------------------
; looks for mode 512x384x8 linear

search_vesa_mode:
                ; evaluate linear address of mode list
                mov     eax,vesaheader
                movzx   ebx,word ptr [eax+14]
                movzx   ecx,word ptr [eax+16]
                shl     ecx,4
                add     ecx,ebx
                sub     ecx,_code32a

search_vesa_mode_loop:
                movzx   eax,word ptr [ecx]
                cmp     eax,0FFFFh
                je      search_vesa_mode_ret
                
                ; set the mode number
                mov     v86r_cx,ax

                ; convert vesamodeinfo to real mode pointer
                mov     eax,vesamodeinfo
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call VESA driver
                mov     v86r_ax,04F01h
                mov     al,10h
                int     33h

                mov     eax,vesamodeinfo

                ; test for color mode
                test    word ptr [eax],BIT_3
                jz      search_vesa_mode_next
                
                ; test for graphics mode
                test    word ptr [eax],BIT_4
                jz      search_vesa_mode_next
                
                ; test for linear frame buffer
                test    word ptr [eax],BIT_7
                jz      search_vesa_mode_next

                ; X resolution of 512
                movzx   ebx,word ptr [eax+18]
                cmp     ebx,512
                jne     search_vesa_mode_next

                ; Y resolution of 384
                movzx   ebx,word ptr [eax+20]
                cmp     ebx,384
                jne     search_vesa_mode_next

                ; number of planes: 1
                movzx   ebx,byte ptr [eax+24]
                cmp     ebx,1
                jne     search_vesa_mode_next

                ; bits per pixel: 8
                movzx   ebx,byte ptr [eax+25]
                cmp     ebx,8
                jne     search_vesa_mode_next

                ; memory model: packed
                movzx   ebx,byte ptr [eax+27]
                cmp     ebx,4
                jne     search_vesa_mode_next

                ; found!!
                mov     ebx,dword ptr [eax+40]
                sub     ebx,_code32a
                mov     vesalinearbuffer,ebx

                movzx   ebx,word ptr [ecx]
                mov     vesamodenumber,ebx
               
                or      eax,eax
                ret
                
search_vesa_mode_next:
                add     ecx,2
                jmp     search_vesa_mode_loop

search_vesa_mode_ret:
                stc
                ret

; set_vesa_mode ------------------------------------------------------
; set the chosen vesa mode

set_vesa_mode:
                ; set the mode
                mov     v86r_ax,04F02h
                mov     ebx,vesamodenumber
                ;or      ebx,(1 SHL 14)
                mov     v86r_bx,bx
                mov     al,10h
                int     33h

                ; clear the buffer with "1s"
                irp     i,<0,1,2>

                mov     eax,i
                call    set_vesa_bank
                mov     eax,01010101h
                mov     edi,0a0000h
                sub     edi,_code32a
                mov     ecx,65536/4
                rep     stosd

                endm

                ret

; set_vesa_bank ------------------------------------------------------
; set the vesa bank register
; enter eax=bank number

set_vesa_bank:
                push    eax
                mov     v86r_ax,04F05h
                mov     v86r_bx,0
                mov     v86r_dx,ax
                mov     al,10h
                int     33h
                pop     eax
                ret

code32          ends
                end




;; VESA HEADER

VbeSignature    db      'VESA' ; VBE Signature
VbeVersion      dw      0200h   ; VBE Version
OemStringPtr    dd      ?       ; Pointer to OEM String
Capabilities    db      4 dup (?)       ; Capabilities of graphics controller
VideoModePtr    dd      ?       ; Pointer to VideoModeList
TotalMemory     dw      ?       ; Number of 64kb memory blocks
; Added for VBE 2.0
OemSoftwareRev  dw      ?       ; VBE implementation Software revision
OemVendorNamePtr        dd      ?       ; Pointer to Vendor Name String
OemProductNamePtr       dd      ?       ; Pointer to Product Name String
OemProductRevPtr        dd      ?       ; Pointer to Product Revision String
Reserved        db      222 dup (?); Reserved for VBE implementation scratch
;   area
OemData db      256 dup (?); Data Area for OEM Strings
