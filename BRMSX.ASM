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
include psg.inc
include mouse.inc
include vesa.inc

public _main
public msxram
public msxvram
public blitbuffer
public transf_buffer
public diskimage
public cart1
public dirtycode
public compbuffer
public dmabuffer
public dmatemp
public filenamelist
public read_rom
public vesaheader
public vesamodeinfo

extrn detect_cpu: near
extrn pentiumfound: dword
extrn mmxfound: dword

; DATA ---------------------------------------------------------------

DMABUFFERSIZE   equ     800*20

msg00           db      'BrMSX 1.84',13,10
                db      'Copyright (C) 1997,98 by Ricardo Bittencourt'
                db      13,10,10,'$'
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
msg11           db      'Cannot reset Sound Blaster',13,10,'$'
msg12           db      'Sound Blaster reseted succesfully',13,10,'$'
msg13           db      'Mouse driver detected',13,10,'$'
msg14           db      'BLASTER environment string not found',13,10,'$'
msg15           db      'Error in BLASTER environment string',13,10,'$'
msg16           db      'Sound Blaster at base address $'
msg17           db      'h, IRQ $'
msg18           db      ', DMA $'
msg19           db      'VESA not found',13,10,'$'
msg20           db      'VESA version: $'
msg21           db      'VESA2 512x384 not found',13,10,'$'
msgnocpuid      db      '486 or below $'
msg386          db      '386 $'
msg486          db      '486 $'
msg586          db      'Pentium $'
msg686          db      'Pentium Pro or better $'
msgMMX          db      '(MMX)$'
msgpoint        db      '.$'
rom_name        db      'MSX.ROM',0
cart1_name      db      'CART1.ROM',0
drivea_name     db      'DRIVEA.DSK',0
blasterenv      db      'BLASTER',0
addrstr         db      3 dup (0)
emptyspace      db      128 dup (0)

align 4

msxram          dd      ?
msxvram         dd      ?
blitbuffer      dd      ?
msxrom          dd      ?
cart1           dd      ?
transf_buffer   dd      ?
diskimage       dd      ?
compbuffer      dd      ?
dirtycode       dd      ?
dmabuffer       dd      ?
dmatemp         dd      ?
filenamelist    dd      ?
vesaheader      dd      ?
vesamodeinfo    dd      ?

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
                cmp     mmxfound,1
                jne     _main_cpu_nommx
                mov     eax,offset msgMMX
                call    printmsg

_main_cpu_nommx:
                call    crlf

                ; allocate 757+ bytes of low memory to sound DMA transfer
                ; these bytes must not cross a 64kb boundary

                mov     eax,DMABUFFERSIZE
                call    _getlomem
                jc      no_memory
                mov     dmabuffer,eax
                mov     edx,eax
                add     edx,_code32a
                mov     ebx,edx
                add     ebx,DMABUFFERSIZE
                and     ebx,0F0000h
                and     edx,0F0000h
                xor     ebx,edx
                test    ebx,(1 shl 16)
                jz      main_getdma2

                mov     eax,DMABUFFERSIZE
                call    _getlomem
                jc      no_memory
                mov     dmabuffer,eax

main_getdma2:
                ; second dma buffer can be on any memory
                mov     eax,DMABUFFERSIZE
                call    _getmem
                jc      no_memory
                mov     dmatemp,eax

                ; allocate 32kb to transfer buffer
                mov     eax,32768
                call    _getlomem
                jc      no_memory
                mov     transf_buffer,eax

                ; alloc 512 bytes to vesa header
                mov     eax,512
                call    _getlomem
                jc      no_memory
                mov     vesaheader,eax
                
                ; alloc 256 bytes to vesa mode info block
                mov     eax,256
                call    _getlomem
                jc      no_memory
                mov     vesamodeinfo,eax
                
                call    parse_command_line

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

                ; alloc always 256kb to cart1                
                mov     eax,256*1024
                call     _getmem
                jc      no_memory
                mov     cart1,eax

                ; read cartridge 1 from disk
                mov     edx,offset emptyspace
                call    read_rom
                
                ; allocate 64kb to blit buffer
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     blitbuffer,eax

                ; allocate 8kb to file name list
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     filenamelist,eax

                ; allocate 1Mb to compile buffer
                ;mov     eax,1048576
                ;call    _getmem
                ;jc      no_memory
                ;mov     compbuffer,eax

                ; allocate 8*64kb to dirty code buffer
                ;mov     eax,8*65536
                ;call    _getmem
                ;jc      no_memory
                ;mov     dirtycode,eax

                ; allocate 720kb to disk image
                ;mov     eax,720*1024
                ;call    _gethimem
                ;jc      no_memory
                ;mov     diskimage,eax
                
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
                mov     eax,dword ptr [offset slot1+16]
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

                ; init the mouse
                call    init_mouse
                cmp     mousedriver,0
                je      _main_nomouse
                mov     eax,offset msg13
                call    printmsg
_main_nomouse:

                call    search_blaster
                jc      blaster_not_found
                call    parse_blaster_string
                jc      error_in_blaster
                mov     sounddetected,1
                mov     soundenabled,1

                mov     eax,offset msg16
                call    printmsg
                mov     eax,sbbaseaddr
                call    printhex4
                mov     eax,offset msg17
                call    printmsg
                mov     eax,sbirq
                call    printhex2
                mov     eax,offset msg18
                call    printmsg
                mov     eax,sbdma
                call    printhex2
                call    crlf

                ; init the sound blaster
                call    init_sound_blaster
                jc      soundblaster_failed
                mov     eax,offset msg12
                call    printmsg
                mov     sounddetected,1

_main_nosound:

                ; init the VESA driver
                call    init_vesa
                jc      no_vesa
                mov     eax,offset msg20
                call    printmsg
                mov     eax,vesaheader
                mov     eax,[eax+4]
                push    eax
                movzx   eax,ah
                call    printdecimal
                mov     eax,offset msgpoint
                call    printmsg
                pop     eax
                and     eax,0FFh
                call    printdecimal
                call    crlf
                mov     eax,vesaheader
                mov     eax,[eax+4]
                cmp     ax,0200h
                jb      vesa2_512x384_not_found

                ; search for mode 512x384x8 linear
                call    search_vesa_mode
                jc      vesa2_512x384_not_found

                mov     vesa2found,1

_main_novesa:

                ; enter debug mode
                
                ; don't ask 
                db 365 dup (090h)
                
                call    crlf
                mov     eax,offset msg10
                call    printmsg
                call    getchar
                call    debug

                cmp     mmxfound,1
                jne     main_exit
                emms

main_exit:
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

soundblaster_failed:
                mov     eax,offset msg11
                call    printmsg
                jmp     _main_nosound

blaster_not_found:
                mov     eax,offset msg14
                call    printmsg
                jmp     _main_nosound

error_in_blaster:
                mov     eax,offset msg15
                call    printmsg
                jmp     _main_nosound

no_vesa:
                mov     eax,offset msg19
                call    printmsg
                jmp     _main_novesa

vesa2_512x384_not_found:
                mov     eax,offset msg21
                call    printmsg
                jmp     _main_novesa


; search_blaster -----------------------------------------------------
; search the environment vars for BLASTER settings
; return: carry flag if BLASTER not found
;         edi = address of first byte after "=" if BLASTER found

search_blaster:

                ; find the start address of environment strings
                mov     esi,02Ch
                add     esi,_pspa
                sub     esi,_code32a
                movzx   eax,word ptr [esi]
                shl     eax,4
                sub     eax,_code32a
                mov     edi,eax

search_blaster_loop:
                mov     ebx,edi
                mov     al,[edi]
                or      al,al
                jz      search_blaster_failed

                mov     esi,offset blasterenv
                mov     ecx,7
                repz    cmpsb
                or      ecx,ecx
                jz      search_blaster_success

                mov     edi,ebx
search_blaster_skip0:
                inc     edi
                cmp     byte ptr [edi],0
                jne     search_blaster_skip0
                inc     edi
                jmp     search_blaster_loop

search_blaster_success:
                inc     edi
                or      eax,eax
                ret

search_blaster_failed:
                stc
                ret

; parse_blaster_string -----------------------------------------------
; parse the blaster string to get the parameters "A", "I" and "D"
; enter edi = start of string
; exit = c flag if error in blaster settings

parse_blaster_string:
                mov     esi,edi
                mov     al,'A'

parse_blaster_loop_A:
                cmp     al,[esi]
                je      parse_blaster_found_A
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_A

parse_blaster_found_A:
                mov     eax,0
                movzx   edx,byte ptr [esi+1]
                sub     edx,'0'
                add     eax,edx
                shl     eax,4
                
                movzx   edx,byte ptr [esi+2]
                sub     edx,'0'
                add     eax,edx
                shl     eax,4
                
                movzx   edx,byte ptr [esi+3]
                sub     edx,'0'
                add     eax,edx
                mov     sbbaseaddr,eax

                mov     esi,edi
                mov     al,'I'
parse_blaster_loop_I:
                cmp     al,[esi]
                je      parse_blaster_found_I
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_I

parse_blaster_found_I:
                movzx   eax,byte ptr [esi+1]
                sub     eax,'0'
                movzx   ebx,byte ptr [esi+2]
                cmp     ebx,'0'
                jb      parse_blaster_write_I
                cmp     ebx,'9'
                ja      parse_blaster_write_I
                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
parse_blaster_write_I:
                mov     sbirq,eax
                
                mov     esi,edi
                mov     al,'D'
parse_blaster_loop_D:
                cmp     al,[esi]
                je      parse_blaster_found_D
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_D

parse_blaster_found_D:
                movzx   eax,byte ptr [esi+1]
                sub     eax,'0'
                mov     sbdma,eax
                
                or      eax,eax
                ret

parse_blaster_string_error:
                stc
                ret
                
; parse_command_line -------------------------------------------------
; parse the command line and retrieve the correct ROM name
                
                
parse_command_line:                
                mov     esi,81h
                add     esi,_pspa
                sub     esi,_code32a
                movzx   ecx,byte ptr [esi-1]
                
parse_command_line_find:
                or      ecx,ecx
                jz      parse_command_line_none
                cmp     byte ptr [esi],32
                ja      parse_command_line_arg
                dec     ecx
                inc     esi
                jmp     parse_command_line_find

parse_command_line_arg:
                mov     edi,offset emptyspace

parse_command_line_arg_loop:
                movsb   
                cmp     byte ptr [esi],32
                ja      parse_command_line_arg_loop

parse_command_line_none:
                ret

; read_rom -----------------------------------------------------------
; read a ROM file from the disk and place it on slot 1
; enter: edx = offset of rom name
                
read_rom:
                call    open_file
                jc      _ret
                call    read_size_file
                push    eax
                mov     eax,cart1
                mov     ebx,0
                mov     dword ptr [offset slot1+16],eax
                mov     dword ptr [offset slot1+16+4],ebx
                add     eax,2000h
                mov     dword ptr [offset slot1+16+8],eax
                mov     dword ptr [offset slot1+16+8+4],ebx
                pop     eax
                cmp     eax,04000h
                je      read_rom1
                cmp     eax,08000h
                jne     read_megarom
                mov     ecx,cart1
                add     ecx,4000h
                mov     dword ptr [offset slot1+32],ecx
                mov     dword ptr [offset slot1+32+4],ebx
                add     ecx,2000h
                mov     dword ptr [offset slot1+32+8],ecx
                mov     dword ptr [offset slot1+32+8+4],ebx
read_rom1:
                mov     edx,transf_buffer
                mov     ecx,eax
                call    read_file
                mov     ecx,eax
                mov     esi,transf_buffer
                mov     edi,cart1
                rep     movsb
                ret

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

                ret
                
code32          ends
                end


