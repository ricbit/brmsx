; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: BRMSX.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include pentium.inc
include io.inc
include z80.inc
include debug.inc

public _main
public msxram
public msxvram
public blitbuffer
public diskimage
public cart1

extrn detect_cpu: near
extrn pentiumfound: dword

; DATA ---------------------------------------------------------------

msg00           db      'BrMSX 1.39',13,10
                db      'by Ricardo Bittencourt',13,10,10,'$'
msg01           db      'Not enough memory',13,10,'$'
msg02           db      'Cartridge not supported',13,10,'$'
msg03           db      'Disk size not supported',13,10,'$'
msg04           db      'Low memory free: $'
msg05           db      'High memory free: $'
msg06           db      'Processor type: $'
msg07           db      'Clock: $'
msg08           db      ' Mhz',13,10,'$'
msg09           db      ' kb',13,10,'$'
msg10           db      'Press any key to start... $'
msgnocpuid      db      '486 or lower',13,10,'$'
msg386          db      '386',13,10,'$'
msg486          db      '486',13,10,'$'
msg586          db      'Pentium',13,10,'$'
msg686          db      'Pentium Pro or better',13,10,'$'
rom_name        db      'MSX.ROM',0
cart1_name      db      'CART1.ROM',0
drivea_name     db      'DRIVEA.DSK',0

align 4

msxram          dd      ?
msxvram         dd      ?
blitbuffer      dd      ?
msxrom          dd      ?
cart1           dd      ?
transf_buffer   dd      ?
diskimage       dd      ?

; --------------------------------------------------------------------

_main:          sti
                
                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                ; print info on free low memory
                mov     eax,offset msg04
                call    printmsg
                call    _lomemsize
                shr     eax,10
                call    printdecimal
                mov     eax,offset msg09
                call    printmsg

                ; print info on free high memory
                mov     eax,offset msg05
                call    printmsg
                call    _himemsize
                shr     eax,10
                call    printdecimal
                mov     eax,offset msg09
                call    printmsg

                ; print processor type
                mov     eax,offset msg06
                call    printmsg
                call    detect_cpu
                or      eax,eax
                jnz     _main_386
                mov     eax,offset msgnocpuid
                call    printmsg
                jmp     _main_cpuexit
_main_386:
                cmp     eax,3
                jnz     _main_486
                mov     eax,offset msg386
                call    printmsg
                jmp     _main_cpuexit
_main_486:
                cmp     eax,4
                jnz     _main_586
                mov     eax,offset msg486
                call    printmsg
                jmp     _main_cpuexit
_main_586:
                cmp     eax,5
                jnz     _main_686
                mov     eax,offset msg586
                call    printmsg
                jmp     _main_cpuexit
_main_686:
                mov     eax,offset msg686
                call    printmsg

_main_cpuexit:
                ; allocate 32kb to msx rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxrom,eax
                mov     ecx,32
                mov     ebx,offset slot0
_main0:
                mov     [ebx],eax
                add     ebx,8
                loop    _main0
                mov     dword ptr [offset mem],eax
                add     eax,2000h
                mov     dword ptr [offset slot0+8],eax
                mov     dword ptr [offset mem+4],eax
                add     eax,2000h
                mov     dword ptr [offset slot0+16],eax
                mov     dword ptr [offset mem+8],eax
                add     eax,2000h
                mov     dword ptr [offset slot0+24],eax
                mov     dword ptr [offset mem+12],eax

                ; read msx rom 1 from disk
                mov     edx,offset rom_name
                call    open_file
                mov     edx,msxrom
                mov     ecx,32768
                call    read_file
                
                ; allocate 16kb to msx vram
                mov     eax,16384
                call    _getmem
                jc      no_memory
                mov     msxvram,eax

                ; allocate 64kb to msx ram
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     msxram,eax
                mov     dword ptr [offset slot2],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+8],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+16],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+24],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+32],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+40],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+48],eax
                add     eax,2000h
                mov     dword ptr [offset slot2+56],eax

                ; allocate 32kb to transfer buffer
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     transf_buffer,eax
                
                ; read cartridge 1 from disk
                mov     edx,offset cart1_name
                call    open_file
                jc      _main2
                call    read_size_file
                push    eax
                call    _gethimem
                jc      no_memory
                mov     cart1,eax
                mov     dword ptr [offset slot1+16],eax
                add     eax,2000h
                mov     dword ptr [offset slot1+16+8],eax
                pop     eax
                cmp     eax,04000h
                je     _main1
                cmp     eax,08000h
                jne     read_megarom
                mov     ecx,cart1
                add     ecx,4000h
                mov     dword ptr [offset slot1+32],ecx
                add     ecx,2000h
                mov     dword ptr [offset slot1+32+8],ecx
_main1:
                mov     edx,transf_buffer
                mov     ecx,eax
                call    read_file
                mov     ecx,eax
                mov     esi,transf_buffer
                mov     edi,cart1
                rep     movsb
                jmp     _main2

read_megarom:
                shr     eax,15
                mov     edi,cart1
read_megarom1:
                mov     edx,transf_buffer
                mov     ecx,32768
                call    read_file
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd
                dec     eax
                or      eax,eax
                jnz     read_megarom1
                mov     ecx,cart1
                add     ecx,4000h
                mov     dword ptr [offset slot1+32],ecx
                add     ecx,2000h
                mov     dword ptr [offset slot1+32+8],ecx
                mov     eax,2
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax

_main2:
                ; allocate 64kb to blit buffer
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     blitbuffer,eax

                ; allocate 720kb to disk image
                mov     eax,720*1024
                call    _gethimem
                jc      no_memory
                mov     diskimage,eax
                
                ; read disk image from file
                mov     edx,offset drivea_name
                call    open_file
                jc      _main3
                call    read_size_file
                cmp     eax,720*1024
                jne     disk_size_not_supported

                mov     ebx,720/32
                mov     edi,diskimage
_main4:               
                mov     ecx,32768
                mov     edx,transf_buffer
                call    read_file
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd
                add     edi,32768
                dec     ebx
                jnz     _main4

                ; patch for PHYDIO
                mov     eax,dword ptr [offset slot1+8]
                mov     byte ptr [eax+010h],0edh
                mov     byte ptr [eax+011h],0ffh

                ; patch for DSKCHG
                mov     byte ptr [eax+013h],0edh
                mov     byte ptr [eax+014h],0ffh

                ; patch for GETDPB
                mov     byte ptr [eax+016h],0edh
                mov     byte ptr [eax+017h],0ffh

_main3:
                ; if the computer is a pentium
                ; then measure its speed
                cmp     pentiumfound,1
                jne     _main_dontmeasure
                mov     eax,offset msg07
                call    printmsg
                call    measurespeed                
                xor     edx,edx
                mov     eax,dword ptr [offset clockrate]
                mov     ebx,16666
                div     ebx
                call    printdecimal
                mov     eax,offset msg08
                call    printmsg

_main_dontmeasure:

                ; enter debug mode
                
                ; don't ask
                db 5*3*5 dup (090h)

                call    crlf
                mov     eax,offset msg10
                call    printmsg
                call    getchar
                call    debug
  
                ; exit to dos
                jmp     _exit

no_memory:      
                mov     eax,offset msg01
                call    printmsg
                jmp     _exit

cartridge_not_supported:
                mov     eax,offset msg02
                call    printmsg
                jmp     _exit

disk_size_not_supported:
                mov     eax,offset msg03
                call    printmsg
                jmp     _exit

code32          ends
                end


