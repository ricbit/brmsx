; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: 
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pmode.inc
include print.inc

extrn symbolic_debugger: dword
extrn prn_name: byte
extrn transf_buffer: dword
extrn printmsgp: near
extrn printhex2p: near
extrn printhex4p: near

public install_symdeb
public _printop322
public _printop321

; DATA ---------------------------------------------------------------

prn_size        dd      0
prn_image       dd      0

; --------------------------------------------------------------------

install_symdeb:
                cmp     symbolic_debugger,1
                jne     _ret

                ; read symbolic information from file
                mov     edx,offset prn_name
                call    open_file
                jc      _ret

                ; check file size
                call    read_size_file
                add     eax,16383
                and     eax,0FFFFC000h
                mov     prn_size,eax

                call    _getmem
                jc      _ret
                mov     prn_image,eax

                ; read the file from disk
                mov     ebx,prn_size
                shr     ebx,14
                mov     edi,prn_image
load_prn_image_loop:
                mov     ecx,16384
                mov     edx,transf_buffer
                push    ebx
                call    read_file
                pop     ebx
                mov     esi,transf_buffer
                mov     ecx,16384/4 
                rep     movsd
                dec     ebx
                jnz     load_prn_image_loop

                call    close_file

; --------------------------------------------------------------------

                ; search for the string "Symbols:"
                mov     ecx,prn_size
                mov     edi,prn_image

search_prn_loop:
                mov     al,'S' 
                repnz   scasb

                cmp     ecx,0
                je      _ret

                cmp     dword ptr [edi-1],'bmyS' 
                jne     search_prn_loop

                cmp     dword ptr [edi+3],':slo' 
                jne     search_prn_loop
                                          
; --------------------------------------------------------------------

                ; the string was found, now decode the labels
                mov     eax,edi
                sub     eax,prn_image
                push    edi
                call    printdecimal
                call    crlf
                pop     edi
                add     edi,7

decode_labels_outer:
                inc     edi
                mov     al,[edi]

                cmp     al,'N'
                jne     decode_labels_digit

                cmp     dword ptr [edi],'L oN'
                je      _ret

decode_labels_digit:                
                call    printasc
                call    isdigit
                cmp     al,16
                jz      decode_labels_outer

                movzx   ebx,al

                rept    3

                shl     ebx,8
                inc     edi
                mov     al,[edi]
                call    printasc
                call    isdigit
                or      bl,al

                endm
                
                mov     eax,ebx
                call    printhex4                
                call    crlf

                jmp     decode_labels_outer

; --------------------------------------------------------------------

isdigit:
                cmp     al,'0'
                jb      isdigit_exit

                cmp     al,'9'
                ja      isdigit_alpha

                sub     al,'0'
                ret

isdigit_alpha:
                cmp     al,'A'
                jb      isdigit_exit

                cmp     al,'F'
                ja      isdigit_exit

                sub     al,'A'-10
                ret

isdigit_exit:
                mov     al,16
                ret

; --------------------------------------------------------------------

_printop322:                
                call    printmsgp
                inc     edi
                call    fetchw
                call    printhex4p
                ret

_printop321:                
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                ret

code32          ends
                end


