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
include vdp.inc
include joystick.inc
include gui.inc
include drive.inc
include serial.inc

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
public soundbuffer
public timebuffer
public sccram
public tapeimage

extrn detect_cpu: near
extrn pentiumfound: dword
extrn mmxfound: dword

; DATA ---------------------------------------------------------------

DMABUFFERSIZE   equ     800*20

msg00           db      'BrMSX 1.126',13,10
                db      'Copyright (C) 1997,98 by Ricardo Bittencourt'
                db      13,10,10,'$'
msg01           db      'Not enough memory',13,10,'$'
msg02           db      'Error in ROM file',13,10,'$'
msg03           db      'Disk size not supported',13,10,'$'
msg04           db      'Low memory free: $'
msg05           db      'High memory free: $'
msg06           db      'Processor type: $'
msg07           db      'Clock: $'
msg08           db      ' Mhz',13,10,'$'
msg09           db      ' kb',13,10,'$'
msg10           db      'Press ENTER to start or ESC to debugger. $'
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
msg22           db      'BrMSX 1.126',13,10
                db      'Copyright (C) 1997,1998 by Ricardo Bittencourt'
                db      13,10
                db      'Official site: http://www.lsi.usp.br/'
                db      '~ricardo/brmsx.htm',13,10
                db      'Send bugs, comments and suggestions to '
                db      'ricardo@lsi.usp.br',13,10,'$'
msg23           db      'Cartridge 1: $'
msg24           db      'Cartridge 2: $'
msg25           db      'Drive A: $'
msg26           db      'MSX.ROM invalid or not found',13,10,'$'
msg27           db      'DISK.ROM invalid or not found',13,10,'$'
msg28           db      'Tape: $'
msg29           db      'Tape image not found',13,10,'$'
msg30           db      'Tape image greater than 64kb',13,10,'$'
help_message    db      'Usage: BRMSX [-options] '
                db      '[cart1.rom]' 
                db      13,10,10,'Options:',13,10
                db      '-normal        normal emulation speed '
                db      '(default)',13,10
                db      '-fast          fast emulation speed',13,10
                db      '-turbo         turbo emulation speed',13,10
                db      '-ramslot <n>   select slot of RAM, can be 2 '
                db      '(default) or 3',13,10
                db      '-win           windows video engine '
                db      '(slower, default)',13,10
                db      '-dos           dos video engine (fast but does not '
                db      'work under windows)',13,10
                db      '-mmx           MMX video engine (fastest but '
                db      'requires MMX processor)',13,10
                db      '-res <mode>    resolution (0=320x200 1=256x200 '
                db      '2=512x384 3=256x192)',13,10
                db      '-vsync         enable vertical retrace '
                db      'synchronization',13,10
                db      '-frame <n>     frame skipping (1 means all '
                db      'frames rendered, default)',13,10
                db      '-nocache       disable video cache',13,10
                db      '-cpugraph      enable CPU performance graph',13,10
                db      '-psggraph      enable PSG graph',13,10
                db      '-nosound       disable the sound engine',13,10
                db      '-scc           enable SCC sound',13,10
                db      '-diska <file>  use <file> as drive A',13,10
                db      '-disklow       low-level, port-based disk '
                db      'emulation (default)',13,10
                db      '-diskhigh      high-level, patch-based disk '
                db      'emulation',13,10
                db      'Press enter to continue.$'
help_message2   db      13
                db      '-tape <file>   use <file> as cassete image',13,10
                db      '-joy           enable joystick emulation',13,10
                db      '-nomouse       disable mouse driver detection',13,10
                db      '-com <port>    select COM serial port [1-4]',13,10
                db      '-client        computer is client',13,10
                db      '-server        computer is server',13,10
                db      '-novesa        disable VESA detection',13,10
                db      '-noled         disable LED emulation',13,10
                db      '-nopentium     disable pentium extensions and '
                db      'cpu autodetect',13,10
                db      '-noenter       disable enter pressing at '
                db      'start',13,10
                db      '-help          show this help page',13,10
                db      '$'
msgnocpuid      db      '486 or below $'
msg386          db      '386 $'
msg486          db      '486 $'
msg586          db      'Pentium $'
msg686          db      'Pentium Pro or better $'
msgMMX          db      '(MMX)$'
msgpoint        db      '.$'
rom_name        db      'MSX.ROM',0
disk_rom_name   db      'DISK.ROM',0
blasterenv      db      'BLASTER',0
addrstr         db      3 dup (0)

emptyspace      db      128 dup (0)
argnumber       dd      0
argpos          dd      081h
argcount        dd      0

secondarg       dd      0
second_callback dd      0

cartridge1      db      128 dup (0)
cartridge2      db      128 dup (0)
drivea_name     db      128 dup (0)
tape_name       db      128 dup (0)

switch_mmx      db      '-mmx',0
switch_dos      db      '-dos',0
switch_win      db      '-win',0
switch_scc      db      '-scc',0
switch_psgg     db      '-psggraph',0
switch_cpug     db      '-cpugraph',0
switch_help     db      '-help',0
switch_diska    db      '-diska',0
switch_nosound  db      '-nosound',0
switch_vsync    db      '-vsync',0
switch_nocache  db      '-nocache',0
switch_nomouse  db      '-nomouse',0
switch_novesa   db      '-novesa',0
switch_noenter  db      '-noenter',0
switch_normal   db      '-normal',0
switch_fast     db      '-fast',0
switch_turbo    db      '-turbo',0
switch_noled    db      '-noled',0
switch_res      db      '-res',0
switch_disklow  db      '-disklow',0
switch_diskhigh db      '-diskhigh',0
switch_joy      db      '-joy',0
switch_com      db      '-com',0
switch_server   db      '-server',0
switch_client   db      '-client',0
switch_frame    db      '-frame',0
switch_tape     db      '-tape',0
switch_nopent   db      '-nopentium',0
switch_ramslot  db      '-ramslot',0

switch_table:
                dd      offset switch_mmx
                dd      offset switch_dos
                dd      offset switch_win
                dd      offset switch_scc
                dd      offset switch_psgg
                dd      offset switch_cpug
                dd      offset switch_help
                dd      offset switch_diska
                dd      offset switch_nosound
                dd      offset switch_vsync
                dd      offset switch_nocache
                dd      offset switch_nomouse
                dd      offset switch_novesa
                dd      offset switch_noenter
                dd      offset switch_normal
                dd      offset switch_fast
                dd      offset switch_turbo
                dd      offset switch_noled
                dd      offset switch_res
                dd      offset switch_disklow
                dd      offset switch_diskhigh
                dd      offset switch_joy
                dd      offset switch_com
                dd      offset switch_server
                dd      offset switch_client
                dd      offset switch_frame
                dd      offset switch_tape
                dd      offset switch_nopent
                dd      offset switch_ramslot

switch_total    dd      29

switch_callback: 
                dd      offset callback_mmx
                dd      offset callback_dos
                dd      offset callback_win
                dd      offset callback_scc
                dd      offset callback_psgg
                dd      offset callback_cpug
                dd      offset callback_help
                dd      offset callback_diska
                dd      offset callback_nosound
                dd      offset callback_vsync
                dd      offset callback_nocache
                dd      offset callback_nomouse
                dd      offset callback_novesa
                dd      offset callback_noenter
                dd      offset callback_normal
                dd      offset callback_fast
                dd      offset callback_turbo
                dd      offset callback_noled
                dd      offset callback_res
                dd      offset callback_disklow
                dd      offset callback_diskhigh
                dd      offset callback_joy
                dd      offset callback_com
                dd      offset callback_server
                dd      offset callback_client
                dd      offset callback_frame
                dd      offset callback_tape
                dd      offset callback_nopent
                dd      offset callback_ramslot

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
diskrom         dd      ?
soundbuffer     dd      ?
timebuffer      dd      ?
sccram          dd      ?
idlerom         dd      ?
tapeimage       dd      ?

diskenabled     dd      0
cpugraphok      dd      0
nosound         dd      0
nomouse         dd      0
novesa          dd      0
noenter         dd      0
filesize        dd      0
nopentium       dd      0

; --------------------------------------------------------------------

_main:          sti

                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                call    parse_command_line
                                               
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

                cmp     nopentium,1
                je      _main_nopentium
                
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

                cmp     cpugraphok,1
                jne     _main_nocpugraph
                call    changebargraph
_main_nocpugraph:
_main_nopentium:

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
                call    _getlomem
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
                
                ; allocate 8kb to idle rom
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     idlerom,eax

                ; fill idle rom with 0FFh
                mov     edi,idlerom
                mov     eax,0FFFFFFFFh
                mov     ecx,8192/4
                rep     stosd
                
                ; fill all slots with idle rom
                mov     eax,idlerom
                mov     ecx,32
                mov     ebx,offset slot0
_main_idlerom:
                mov     [ebx],eax
                add     ebx,8
                loop    _main_idlerom

                ; fill mem with idle rom
                irp     i,<0,1,2,3,4,5,6,7>
                mov     dword ptr [offset mem+i*4],eax
                endm

                ; allocate 32kb to msx rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxrom,eax
                irp     i,<0,1,2,3>
                mov     dword ptr [offset slot0+i*8],eax
                mov     dword ptr [offset mem+i*4],eax
                add     eax,2000h
                endm

                ; read msx rom 1 from disk
                mov     edx,offset rom_name
                call    open_file
                jc      msx_rom_error
                call    read_size_file
                cmp     eax,08000h
                jne     msx_rom_error
                mov     edx,transf_buffer
                mov     ecx,32768
                call    read_file
                call    close_file
                mov     edi,msxrom
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd
                
                ; allocate 16kb to msx vram
                mov     eax,16384
                call    _getmem
                jc      no_memory
                mov     msxvram,eax

                ; allocate 8kb to SCC ram
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     sccram,eax

                ; fill SCC ram with 0FFh
                mov     edi,sccram
                mov     eax,0FFFFFFFFh
                mov     ecx,8192/4
                rep     stosd

                ; allocate 128kb to msx ram
                mov     eax,128*1024
                call    _getmem
                jc      no_memory
                mov     msxram,eax
                mov     edi,ramslot
                irp     i,<3,2,1,0>
                mov     dword ptr [edi+i*16],eax
                add     eax,2000h
                mov     dword ptr [edi+i*16+8],eax
                add     eax,2000h
                endm

                ; select RAM slot as pure RAM
                ; and cartridge 2 as pure ROM
                mov     eax,0
                mov     ebx,1
                mov     esi,cart2slot
                irp     i,<0,1,2,3,4,5,6,7>
                mov     dword ptr [edi+i*8+4],eax
                mov     dword ptr [esi+i*8+4],ebx
                endm

                ; clear msx ram
                mov     ecx,128*1024/4
                mov     edi,msxram
                mov     eax,0
                rep     stosd

                ; alloc 64kb to sound buffer
                mov     eax,64*1024
                call     _getmem
                jc      no_memory
                mov     soundbuffer,eax

                ; alloc 128kb to time buffer
                mov     eax,128*1024
                call     _getmem
                jc      no_memory
                mov     timebuffer,eax

                ; alloc always 256kb to cart1                
                mov     eax,256*1024
                call     _getmem
                jc      no_memory
                mov     cart1,eax

                ; print cartridge name
                cmp     byte ptr [offset cartridge1],0
                jne     main_has_cart1

                call    enable_megaram
                jmp     main_nocart1

main_has_cart1:
                mov     eax,offset msg23
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset cartridge1
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf

                ; read cartridge 1 from disk
                mov     edx,offset cartridge1
                mov     eax,cart1
                mov     ebp,offset slot1
                call    read_rom
                jc      error_in_rom                

main_nocart1:

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

                ; print drive a name
                cmp     byte ptr [offset drivea_name],0
                je      main_nodrivea
                mov     eax,offset msg25
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset drivea_name
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf
main_nodrivea:

                ; read disk image from file
                mov     edx,offset drivea_name
                call    open_file
                jc      _main_nodrive

                mov     diskenabled,1
                call    read_size_file
                cmp     eax,720*1024
                jne     disk_size_not_supported

                ; allocate 720kb to disk image
                mov     eax,720*1024
                call    _getmem
                jc      no_memory
                mov     diskimage,eax
                
                mov     ebx,720/16
                mov     edi,diskimage
_main4:               
                mov     ecx,16384
                mov     edx,transf_buffer
                push    ebx
                call    read_file
                pop     ebx
                mov     esi,transf_buffer
                mov     ecx,16384/4
                rep     movsd
                dec     ebx
                jnz     _main4
                call    close_file

                ; allocate 16kb for disk.rom
                mov     eax,16*1024
                call    _getmem
                jc      no_memory
                mov     diskrom,eax

                ; read disk.rom from disk
                mov     edx,offset disk_rom_name
                call    open_file
                jc      disk_rom_error
                call    read_size_file
                cmp     eax,04000h
                jne     disk_rom_error
                mov     edx,transf_buffer
                mov     ecx,16*1024
                call    read_file
                call    close_file
                mov     esi,transf_buffer
                mov     edi,diskrom
                mov     ecx,16384/4
                rep     movsd

                mov     eax,diskrom
                mov     edi,cart2slot
                mov     dword ptr [edi+16],eax
                add     eax,2000h
                mov     dword ptr [edi+16+8],eax

                cmp     portenabled,1
                je      _main_noport

                ; patch for PHYDIO
                mov     edi,cart2slot
                mov     eax,dword ptr [edi+16]
                mov     byte ptr [eax+010h],0edh
                mov     byte ptr [eax+011h],0ffh

                ; patch for DSKCHG
                mov     byte ptr [eax+013h],0edh
                mov     byte ptr [eax+014h],0ffh

                ; patch for GETDPB
                mov     byte ptr [eax+016h],0edh
                mov     byte ptr [eax+017h],0ffh

_main_noport:
_main_nodrive:

                ; check for tape emulation
                cmp     byte ptr [offset tape_name],0
                je      _main_notape
                
                ; print tape name
                mov     eax,offset msg28
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset tape_name
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf

                ; alloc 64kb to tape image
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     tapeimage,eax

                ; fill tape image with zeros
                mov     edi,tapeimage
                mov     ecx,65536/4
                mov     eax,01A1A1A1Ah
                rep     stosd

                ; read tape image from disk
                call    read_tape

                ; patch for TAPION
                mov     eax,dword ptr [offset slot0]
                mov     byte ptr [eax+0E1h],0edh
                mov     byte ptr [eax+0E2h],0ffh

                ; patch for TAPIN
                mov     byte ptr [eax+0E4h],0edh
                mov     byte ptr [eax+0E5h],0ffh

                ; patch for TAPIOF
                mov     byte ptr [eax+0E7h],0edh
                mov     byte ptr [eax+0E8h],0ffh

                ; patch for TAPOON
                mov     byte ptr [eax+0EAh],0edh
                mov     byte ptr [eax+0EBh],0ffh

                ; patch for TAPOUT
                mov     byte ptr [eax+0EDh],0edh
                mov     byte ptr [eax+0EEh],0ffh

                ; patch for TAPOOF
                mov     byte ptr [eax+0F0h],0edh
                mov     byte ptr [eax+0F1h],0ffh

_main_notape:

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

                cmp     nomouse,1
                je      _main_nomouse

                ; init the mouse
                call    init_mouse
                cmp     mousedriver,0
                je      _main_nomouse
                mov     eax,offset msg13
                call    printmsg
_main_nomouse:

                cmp     nosound,1
                je      _main_nosound

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

                cmp     novesa,1
                je      _main_novesa

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

                cmp     videomode,2
                jne     _main_notrouble
                cmp     vesa2found,1
                je      _main_notrouble
                mov     videomode,0

_main_notrouble:

                ; enter debug mode
                
                ; don't ask 
                ;db 365 dup (090h)
                
                cmp     noenter,1
                je      _main_noenter

                call    crlf
                mov     eax,offset msg10
                call    printmsg
                call    getchar
                cmp     al,27
                jne     _main_noenter
                mov     startdebugger,1

_main_noenter:
                call    debug

main_getout:

                cmp     mmxfound,1
                jne     main_nommx
                emms
main_nommx:

                call    settextmode

                ; print end message
                mov     eax,offset msg22
                call    printmsg

                cmp     diskenabled,1
                jne     main_exit_nodisk
                call    flush_dsk
main_exit_nodisk:

                cmp     byte ptr [offset tape_name],0
                je      main_exit_notape
                call    flush_tape

main_exit_notape:
                ; exit to dos
                jmp     _exit

no_memory:      
                mov     eax,offset msg01
                call    printmsg
                jmp     _exit

error_in_rom:
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

msx_rom_error:
                mov     eax,offset msg26
                call    printmsg
                jmp     _exit

disk_rom_error:
                mov     eax,offset msg27
                call    printmsg
                jmp     _exit

tape_not_found:
                mov     eax,offset msg29
                call    printmsg
                ret

tape_too_large:
                mov     eax,offset msg30
                call    printmsg
                jmp     _exit

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
                mov     esi,argpos
                add     esi,_pspa
                sub     esi,_code32a
                movzx   ecx,byte ptr [esi-1]
                cmp     ecx,0
                je      _ret
                mov     argcount,ecx

parse_command_line_loop:
                mov     al,[esi]
                cmp     al,32
                ja      parse_command_line_found

parse_command_line_next:
                inc     esi
                dec     ecx
                jnz     parse_command_line_loop

                ret

parse_command_line_found:
                push    ecx eax
                mov     edi,offset emptyspace
                mov     eax,0
                mov     ecx,128/4
                rep     stosd
                pop     eax ecx

                mov     edi,offset emptyspace

parse_command_line_found_loop:
                cmp     al,32
                jbe     parse_command_line_out

                mov     [edi],al
                inc     edi

                inc     esi
                mov     al,[esi]

                dec     ecx
                jnz     parse_command_line_found_loop


parse_command_line_out:
                cmp     byte ptr [offset emptyspace],'-'
                je      parse_command_line_switch

                cmp     secondarg,1
                je      parse_command_line_second
                
                cmp     argnumber,0
                jne     parse_command_line_out_1
                push    edi esi ecx
                mov     esi,offset emptyspace
                mov     edi,offset cartridge1
                mov     ecx,128/4
                rep     movsd
                pop     ecx esi edi
                inc     argnumber
                
parse_command_line_out_1:
                cmp     argnumber,1
                jne     parse_command_line_out_2
                push    edi esi ecx
                mov     esi,offset emptyspace
                mov     edi,offset cartridge2
                mov     ecx,128/4
                rep     movsd
                pop     ecx esi edi
                inc     argnumber
                
parse_command_line_out_2: 
                cmp     ecx,0
                je      _ret
                jmp     parse_command_line_next

parse_command_line_second:
                pushad
                call    dword ptr [offset second_callback]
                mov     secondarg,0
                popad
                jmp     parse_command_line_out_2

parse_command_line_switch:
                pushad
                mov     ebp,offset switch_table
                mov     esi,[ebp]
                mov     edi,offset emptyspace
                mov     edx,0

parse_command_line_switch_outer:
                mov     al,[esi]
                cmp     al,[edi]
                jne     parse_command_line_next_switch
                or      al,al
                jz      parse_command_line_switch_found
                inc     esi
                inc     edi
                jmp     parse_command_line_switch_outer

parse_command_line_switch_end:
                popad
                jmp     parse_command_line_out_2

parse_command_line_next_switch:
                inc     edx
                cmp     edx,switch_total
                je      parse_command_line_switch_end
                add     ebp,4
                mov     esi,[ebp]
                mov     edi,offset emptyspace
                jmp     parse_command_line_switch_outer

parse_command_line_switch_found:
                sub     ebp,offset switch_table
                add     ebp,offset switch_callback
                call    dword ptr [ebp]
                jmp     parse_command_line_switch_end

; callbacks ----------------------------------------------------------

callback_mmx:
                mov     enginetype,2
                ret

callback_dos:
                mov     enginetype,0
                ret

callback_win:
                mov     enginetype,1
                ret

callback_scc:
                mov     sccenabled,1
                ret

callback_psgg:  
                mov     psggraph,1
                ret

callback_cpug:
                mov     cpugraphok,1
                ret

callback_help:
                mov     eax,offset help_message
                call    printmsg
                call    getchar
                mov     eax,offset help_message2
                call    printmsg
                jmp     _exit

callback_diska:
                mov     secondarg,1
                mov     eax,offset callback_diska_second
                mov     second_callback,eax
                ret

callback_diska_second:
                mov     edi,offset drivea_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                ret

callback_nosound:
                mov     nosound,1
                ret

callback_vsync:
                mov     vsyncflag,1
                ret

callback_nocache:
                mov     imagetype,0
                ret

callback_nomouse:
                mov     nomouse,1
                ret

callback_novesa:        
                mov     novesa,1
                ret

callback_noenter:
                mov     noenter,1
                ret

callback_normal:
                mov     emulatemode,0
                ret

callback_fast:
                mov     emulatemode,1
                ret

callback_turbo:
                mov     emulatemode,2
                ret

callback_noled:
                mov     noled,1
                ret

callback_res:
                mov     secondarg,1
                mov     eax,offset callback_res_second
                mov     second_callback,eax
                ret

callback_res_second:
                mov     bl,byte ptr [offset emptyspace]
                cmp     bl,'1'
                je      callback_res_256x200
                cmp     bl,'2'
                je      callback_res_512x384
                cmp     bl,'3'
                je      callback_res_256x192
                mov     videomode,0
                ret

callback_res_256x200:
                mov     videomode,1
                ret

callback_res_512x384:
                mov     videomode,2
                ret

callback_res_256x192:
                mov     videomode,3
                ret

callback_disklow:
                mov     portenabled,1
                ret

callback_diskhigh:
                mov     portenabled,0
                ret

callback_joy:
                call    calibrate_joystick
                mov     joyenable,1
                ret

callback_com:
                mov     secondarg,1
                mov     eax,offset callback_com_second
                mov     second_callback,eax
                ret

callback_com_second:
                movzx   ebx,byte ptr [offset emptyspace]
                cmp     bl,'1'
                jb      _ret
                cmp     bl,'4'
                ja      _ret
                sub     bl,'0'
                mov     comport,ebx
                ret

callback_server:
                mov     sessionmode,1
                ret

callback_client:
                mov     sessionmode,2
                ret

callback_frame:
                mov     secondarg,1
                mov     eax,offset callback_frame_second
                mov     second_callback,eax
                ret

callback_frame_second:
                mov     eax,0
                mov     ebx,eax
                mov     esi,offset emptyspace

callback_frame_loop:
                mov     bl,[esi]
                cmp     bl,0
                je      callback_frame_set

                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
                inc     esi
                jmp     callback_frame_loop

callback_frame_set:
                cmp     eax,0
                je      _ret
                mov     framerate,eax
                ret

callback_tape:
                mov     secondarg,1
                mov     eax,offset callback_tape_second
                mov     second_callback,eax
                ret

callback_tape_second:
                mov     edi,offset tape_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                ret

callback_nopent:
                mov     nopentium,1
                ret

callback_ramslot:
                mov     secondarg,1
                mov     eax,offset callback_ramslot_second
                mov     second_callback,eax
                ret

callback_ramslot_second:
                cmp     byte ptr [offset emptyspace],'2'
                je      callback_ramslot_second_2
                cmp     byte ptr [offset emptyspace],'3'
                je      callback_ramslot_second_3
                ret

callback_ramslot_second_2:
                mov     eax,offset slot2
                mov     ramslot,eax
                mov     eax,offset slot3
                mov     cart2slot,eax
                mov     allram,0AAh
                ret

callback_ramslot_second_3:
                mov     eax,offset slot3
                mov     ramslot,eax
                mov     eax,offset slot2
                mov     cart2slot,eax
                mov     allram,0FFh
                ret

; read_rom -----------------------------------------------------------
; read a ROM file from the disk
; enter: edx = offset of rom name 
;        eax = offset of read buffer
;        ebp = slot
; exit: carry flag on any error
                
read_rom:
                call    open_file
                jc      _ret

                ; read ROM size from disk
                push    eax
                call    read_size_file
                mov     filesize,eax
                pop     eax

                ; size must be multiple of 4000h
                mov     ecx,filesize
                and     ecx,03FFFh
                jnz     error_in_rom

                ; read first 16kb
                mov     edx,transf_buffer
                mov     ecx,04000h
                call    read_file

                ; copy first 16kb to correct position
                mov     esi,transf_buffer
                mov     edi,eax
                mov     ecx,04000h/4
                rep     movsd

                ; check ROM header
                cmp     word ptr [eax],04241h
                jne     error_in_rom

                ; check file size
                cmp     filesize,04000h
                jne     read_rom_not_16kb

                ; look into the header to discover correct page
                mov     dx,[eax+2]
                and     edx,0C000h
                shr     edx,13

                ; check for a BASIC cartridge
                or      edx,edx
                jz      read_rom_basic

read_rom_place_16kb:
                ; place rom in correct place
                mov     [ebp+edx*8],eax
                add     eax,2000h
                mov     [ebp+edx*8+8],eax

                call    enable_rom

                call    close_file
                or      eax,eax
                ret

read_rom_basic:
                ; check for BASIC header
                cmp     word ptr [eax+8],0    
                je      read_rom_0000

                ; BASIC header found
                mov     edx,4
                jmp     read_rom_place_16kb

read_rom_0000:
                ; mirror the ROM in all pages
                irp     i,<0,1,2,3>
                mov     [ebp+i*16],eax
                endm
                add     eax,2000h
                irp     i,<0,1,2,3>
                mov     [ebp+i*16+8],eax
                endm
                
                call    enable_rom    
                
                call    close_file
                or      eax,eax
                ret

read_rom_not_16kb:
                cmp     filesize,08000h
                jne     read_rom_not_32kb

                ; ROM has 32kb
                ; must read the other 16kb block
                mov     edx,transf_buffer
                mov     ecx,04000h
                call    read_file

                ; place second block in correct location
                mov     esi,transf_buffer
                lea     edi,[eax+04000h]
                mov     ecx,04000h/4
                rep     movsd

                ; place ROM in slot
                ; 32kb ROMs always start at 4000h
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8],eax
                add     eax,2000h
                endm
                
                call    enable_rom    
                
                call    close_file
                or      eax,eax
                ret

read_rom_not_32kb:

                ; ROM is a MegaROM
                ; start reading missing blocks
                lea     edi,[eax+4000h]
                mov     ebx,filesize
                shr     ebx,14
                dec     ebx

read_rom_megarom_loop:
                ; read a 16kb chunk
                mov     edx,transf_buffer
                mov     ecx,4000h
                call    read_file

                ; place 16kb chunk in buffer
                mov     esi,transf_buffer
                mov     ecx,04000h/4
                rep     movsd

                dec     ebx
                jnz     read_rom_megarom_loop

                ; place ROM in slot
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8],eax
                add     eax,2000h
                endm
                
                ; change ROM status to MegaROM
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8+4],2
                mov     dword ptr [offset megablock+2*4+i*4],i
                endm

                call    close_file
                or      eax,eax
                ret

; enable_megaram -----------------------------------------------------
; enable the megaram and the scc

enable_megaram:                
                mov     eax,2
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax
                ret


; enable_rom ---------------------------------------------------------
; enable the ROM

enable_rom:                
                mov     eax,1
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax
                ret

; flush_dsk ----------------------------------------------------------
; flush the DSK image to the disk
                
flush_dsk:

                mov     edx,offset drivea_name
                call    create_file

                mov     ebx,720/16
                mov     esi,diskimage
flush_dsk_loop:               
                mov     edi,transf_buffer
                mov     ecx,16384/4
                rep     movsd

                mov     ecx,16384
                mov     edx,transf_buffer
                push    ebx
                call    write_file
                pop     ebx

                dec     ebx
                jnz     flush_dsk_loop
                call    close_file
                ret

; read_tape ----------------------------------------------------------
; read tape image from disk

read_tape:
                ; open tape file
                mov     edx,offset tape_name
                call    open_file
                jc      tape_not_found

                ; check if it's greater than 64kb
                call    read_size_file
                cmp     eax,65536
                ja      tape_too_large

                ; read from disk
                mov     ebp,tapeimage
                mov     ecx,eax
                sub     ecx,32768
                js      read_tape_missing

                ; read first 32kb block of tape
                mov     ecx,32768
                mov     edx,transf_buffer
                call    read_file

                ; place this block in correct place
                mov     edi,tapeimage
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                ; prepare to read missing block
                sub     eax,32768
                add     ebp,32768

read_tape_missing:
                ; read missing block
                mov     edx,transf_buffer
                mov     ecx,eax
                call    read_file

                ; place missing block in right place
                mov     esi,transf_buffer
                mov     edi,ebp
                mov     ecx,eax
                rep     movsb

                call    close_file
                ret

; flush_tape ---------------------------------------------------------
; flush tape image to disk

flush_tape:
                mov     edx,offset tape_name
                call    create_file

                mov     esi,tapeimage
                mov     edi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                mov     edx,transf_buffer
                mov     ecx,32768
                call    write_file
                
                mov     esi,tapeimage
                add     esi,32768
                mov     edi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                mov     edx,transf_buffer
                mov     ecx,32768
                call    write_file

                call    close_file
                ret

code32          ends
                end

