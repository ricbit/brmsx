; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include io.inc
include z80.inc
include debug.inc

public _main
public msxram
public blitbuffer

; DATA ---------------------------------------------------------------

msg00           db      'BrMSX 1.0',13,10
                db      'by Ricardo Bittencourt',13,10,10,'$'
msg01           db      'Not enough memory',13,10,'$'
msg02           db      'Cartridge not supported',13,10,'$'
rom_name        db      'MSX.ROM',0
cart1_name      db      'CART1.ROM',0

msxram          dd      ?
blitbuffer      dd      ?
msxrom          dd      ?
cart1           dd      ?

; --------------------------------------------------------------------

_main:          sti
                
                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                ; allocate 32kb to msx rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxrom,eax
                mov     ecx,16
                mov     ebx,offset slot0
_main0:
                mov     [ebx],eax
                add     ebx,8
                loop    _main0
                mov     dword ptr [offset mem],eax
                mov     dword ptr [offset mem+16],eax
                add     eax,2000h
                mov     dword ptr [offset mem+4],eax
                mov     dword ptr [offset mem+16+4],eax
                add     eax,2000h
                mov     dword ptr [offset slot0+8],eax
                mov     dword ptr [offset mem+8],eax
                mov     dword ptr [offset mem+16+8],eax
                add     eax,2000h
                mov     dword ptr [offset mem+12],eax
                mov     dword ptr [offset mem+16+12],eax

                ; read msx rom 1 from disk
                mov     edx,offset rom_name
                call    open_file
                mov     edx,msxrom
                mov     ecx,32768
                call    read_file
                
                ; allocate 64kb to msx ram
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     msxram,eax
                mov     dword ptr [offset slot2],eax
                add     eax,4000h
                mov     dword ptr [offset slot2+8],eax
                add     eax,4000h
                mov     dword ptr [offset slot2+16],eax
                add     eax,4000h
                mov     dword ptr [offset slot2+24],eax

                ; allocate 32kb to cartridge 1
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     cart1,eax
                mov     dword ptr [offset slot1+8],eax

                ; read cartridge 1 from disk
                mov     edx,offset cart1_name
                call    open_file
                call    read_size_file
                cmp     eax,04000h
                je     _main1
                cmp     eax,08000h
                jne     cartridge_not_supported
_main1:
                mov     edx,cart1
                mov     ecx,eax
                call    read_file

                ; allocate 64kb to blit buffer
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     blitbuffer,eax

                ; enter debug mode
                call    debug

                ; exit to dos
                jmp     _exit

no_memory:      
                mov     eax,offset msg01
                call    printmsg
                jmp     _exit

cartridge_not_supported:
                mov     eax,offset msg01
                call    printmsg
                jmp     _exit

code32          ends
                end


