; --------------------------------------------------------------------
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80.ASM                                                      
; -------------------------------------------------------------------- 
        
        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom: near
extrn msxvram: dword
extrn pset: near
extrn isetCBxx: near
extrn isetDDxx: near
extrn isetEDxx: near
extrn isetFDxx: near
extrn emulEDFF: near
extrn start_counter: near
extrn end_counter: near
extrn iset: dword
extrn emulCB: near
extrn emulDD: near
extrn emulED: near
extrn emulFD: near
extrn emulFF: near
extrn emulXX: near
extrn soundbuffer: dword
extrn timebuffer: dword
extrn sccram: dword
extrn msxram: dword
extrn codetable: dword

include io.inc
include vdp.inc
include psg.inc
include debug.inc
include serial.inc
include bit.inc
include blit.inc
include opcode.inc
include z80supp.inc
include pmode.inc
include gui.inc
include fetch.inc
include flags.inc
include z80sing.inc
include mouse.inc
include joystick.inc
include drive.inc
include saveload.inc
include z80core.inc

public compose_sound
public synch_emulation
public check_mouse
public process_frame
public z80paused
public checkpsg
public check_joystick
public check_client
public set_vdp_interrupt
public z80_interrupt
public set_keyboard_leds
public vdpaddress
public vdpaccess
public speaker

public fetch
public fetch1
public fetchw
public fetchw1
public readmem
public readmemw
public writemem
public writememw
public trace
public print
public outemulXX
public inemulXX
public outportxx
public inportxx
public outemulA8
public callback_megarom0
public histogr
public error
public imtype
public iline
public clocksleft
public psgpos
public psgclocks
public psgclear
public sccdetected
public sccenabled
public newleds
public megadump
public psgselect

public opsubreg
public opsbcreg
public opadcreg
public opaddreg
public opcpreg

public breakpoint
public iff1
public interrupt
public vdpstatus
public keymatrix
public rcounter
public rmask
public regi
public emulatemode
public megarommode
public psgreg
public prim_slotreg
public ppic
public megablock
public z80rate
public z80counter
public reset_flag
public sccregs
public clockcounter

public slot0
public slot1
public slot2
public slot3
public mem

public regaf
public regbc
public reghl
public regde
public regsp
public regpc
public regix
public regiy
public rega
public regf
public regb
public regc
public regd
public rege
public regh
public regl
public regsph
public regspl
public regixh
public regixl
public regiyh
public regiyl
public regeaf
public regebc
public regede
public regehl
public regeafl
public regebcl
public regedel
public regehll
public regesp
public regeix
public regeiy
public regepc
public vdpregs
public vsyncflag
public reset_cpu
public reset_cpu_hard
public ramslot
public cart2slot
public allram
public fakeirq
public vdpcond
public vdptemp
public vdplookahead

public BIT0_table
public BIT1_table
public BIT2_table
public BIT3_table
public BIT4_table
public BIT5_table
public BIT6_table
public BIT7_table
public LOGICAL_table
public ARITP_table
public ARITN_table
public OVERFLOW_table
public NEG_table
public INTERRUPT_table
public PVS53_table
public PVN53_table
public INC_table
public DEC_table
public CP_table
public CPL_table
public DAA_table
public DAA_select_table
public LDI_table

; DATA ---------------------------------------------------------------

align 4

include outport.inc
include inport.inc

include bit0.inc
include bit1.inc
include bit2.inc
include bit3.inc
include bit4.inc
include bit5.inc
include bit6.inc
include bit7.inc
include overflow.inc
include logical.inc
include aritp.inc
include aritn.inc
include pvs53.inc
include pvn53.inc
include neg.inc
include daa.inc
include daas.inc
include inc.inc
include dec.inc
include int.inc
include cp.inc
include cpl.inc
include ldi.inc

align 4

mem:
                dd      ?
                dd      ?
                dd      ?
                dd      ?
                dd      ?
                dd      ?
                dd      ?
                dd      ?

memlock:               
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1

slot:           
slot0:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot1:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot2:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot3:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1

megablock:
                dd      0
                dd      0
                dd      0
                dd      0
                dd      0
                dd      0
                dd      0
                dd      0

megadump:
                dd      0
                dd      0
                dd      0
                dd      0

megarom_callback:
                dd      _ret                    ; pure RAM
                dd      _ret                    ; pure ROM
                dd      callback_megarom0       ; generic
                dd      _ret
                dd      callback_megarom2       ; konami with SCC
                dd      callback_megarom3       ; konami without SCC
                dd      callback_megarom4       ; ascii 8kb
                dd      callback_megarom5       ; ascii 16kb

; Z80 registers
align 4

breakpoint      dd      0
iff1            dd      0
interrupt       dd      0
error           dd      0
rcounter        dd      0        
clockcounter    dd      TC
emulatemode     dd      0
megarommode     dd      0
z80counter      db      8 dup (0)
z80rate         dd      0
reset_flag      dd      0
imtype          dd      1
iline           dd      0
fakeirq         dd      0
clocksleft      dd      TC
ramslot         dd      offset slot2
cart2slot       dd      offset slot3
allram          db      0AAh
rmask           db      0
regi            db      0

; VDP registers
align 4

vdpcond         dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      8 dup (0)
vsyncflag       dd      0
vdpaccess       dd      0
vdptemp         db      0
vdpstatus       db      0
vdplookahead    db      0

; PSG registers
align 4

psgclocks       dd      0
psgpos          dd      0
psgclear        dd      1
speaker         dd      0
psgselect       db      0
psgreg          db      16 dup (0)
psgjoya         db      00111111b
psgjoyb         db      00111111b
psgkana         db      0

; SCC registers

sccregs         db      16 dup (0)
sccactive       dd      0
sccdetected     dd      0
sccenabled      dd      0
           
; PPI registers
align 4

prim_slotreg    db      0
keyboard_line   db      0
ppic            db      0
newleds         db      0
oldleds         db      7

align 4

keymatrix       db      16 dup (0ffh)

align 4

histogr         dd      256 dup (0)

align 4

regaf           dw      00h
                dw      00h
regbc           dw      11h
                dw      00h
regde           dw      22h
                dw      00h
reghl           dw      33h
                dw      00h
regix           dw      00h
                dw      00h
regiy           dw      00h
                dw      00h
regpc           dw      00h
                dw      00h
regsp           dw      0fff0h
                dw      00h
regafl          dw      00h
                dw      00h
regbcl          dw      00h
                dw      00h
regdel          dw      00h
                dw      00h
reghll          dw      00h
                dw      00h

rega            equ     byte ptr [offset regaf+1]
regf            equ     byte ptr [offset regaf+0]
regb            equ     byte ptr [offset regbc+1]
regc            equ     byte ptr [offset regbc+0]
regd            equ     byte ptr [offset regde+1]
rege            equ     byte ptr [offset regde+0]
regh            equ     byte ptr [offset reghl+1]
regl            equ     byte ptr [offset reghl+0]
regixh          equ     byte ptr [offset regix+1]
regixl          equ     byte ptr [offset regix+0]
regiyh          equ     byte ptr [offset regiy+1]
regiyl          equ     byte ptr [offset regiy+0]
regsph          equ     byte ptr [offset regsp+1]
regspl          equ     byte ptr [offset regsp+0]

regeaf          equ     dword ptr [offset regaf]
regebc          equ     dword ptr [offset regbc]
regede          equ     dword ptr [offset regde]
regehl          equ     dword ptr [offset reghl]
regeix          equ     dword ptr [offset regix]
regeiy          equ     dword ptr [offset regiy]
regepc          equ     dword ptr [offset regpc]
regesp          equ     dword ptr [offset regsp]
regeafl         equ     dword ptr [offset regafl]
regebcl         equ     dword ptr [offset regbcl]
regedel         equ     dword ptr [offset regdel]
regehll         equ     dword ptr [offset reghll]

vdpaddressh     equ     byte ptr [offset vdpaddress+1]
vdpaddressl     equ     byte ptr [offset vdpaddress+0]
vdpaddresse     equ     dword ptr [offset vdpaddress]

; fetch --------------------------------------------------------------
; fetch a byte from Z80 memory
; in, edi: address
; out, al: byte
; affect: esi,ebx

fetch:          
                FETCHMACRO 0
                ret

; fetch1 -------------------------------------------------------------
; fetch the next byte from Z80 memory
; in, edi: (address-1)
; out, al: byte
; affect: esi,ebx

fetch1:
                FETCHMACRO 1
                ret

; fetchw -------------------------------------------------------------
; fetch a word from Z80 memory
; in, edi: address
; out, ax: word
; affect: esi,ebx

fetchw:
                FETCHWMACRO     0

; fetchw1 ------------------------------------------------------------
; fetch the next word from Z80 memory
; in, edi: (address-1)
; out, ax: word
; affect: esi,ebx

fetchw1:
                FETCHWMACRO     1

; readmem ------------------------------------------------------------
; read a byte from Z80 memory
; in, ecx: address
; out, al: byte
; affect: esi,ebx

readmem:        mov     esi,ecx                         ; clock 1 U
                mov     ebx,ecx                         ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     al,byte ptr [esi+ebx]           ; clock 6 U [AGI]
                ret

; readmemw -----------------------------------------------------------
; read a word from Z80 memory
; in, ecx: address
; out, ax: word
; affect: esi,ebx

readmemw:        
                mov     ebx,ecx                         ; clock 1 U
                mov     esi,ecx                         ; clock 1 V
                and     ebx,01FFFh                      ; clock 2
                cmp     ebx,01FFFh                      ; clock 3 U
                je      readmemw_slow                   ; clock 3 V
                shr     esi,13                          ; clock 4
                mov     esi,[offset mem+esi*4]          ; clock 6 [AGI]
                mov     ax,word ptr [esi+ebx]           ; clock 8 [AGI]
                ret

readmemw_slow:
                inc     ecx
                call    readmem
                dec     ecx
                mov     ah,al
                call    readmem
                ret

; retrieve_slot_info -------------------------------------------------
; retrieve information about the slot of a particular address
; enter ecx = address
; exit  ecx = megarom dump for this slot
;       eax = offset of this slot table

retrieve_slot_info:
                push    ebx
                mov     ebx,ecx
                shr     ebx,14
                movzx   ecx,prim_slotreg
                xchg    ebx,ecx
                add     cl,cl
                shr     ebx,cl
                and     ebx,3
                mov     ecx,dword ptr [offset megadump+ebx*4]
                mov     eax,ebx
                shl     eax,6
                add     eax,offset slot0
                pop     ebx
                ret

; callback_megarom0 --------------------------------------------------
; Generic MegaROM with SCC
; addresses:  0000h-1FFFh block 0000h-1FFFh
;             2000h-3FFFh block 2000h-3FFFh  
;             4000h-5FFFh block 4000h-5FFFh  
;             6000h-7FFFh block 6000h-7FFFh  
;             8000h-9FFFh block 8000h-9FFFh  
;             A000h-BFFFh block A000h-BFFFh  
;             C000h-DFFFh block C000h-DFFFh  
;             E000h-FFFFh block E000h-FFFFh  
;             9800h-9FFFh SCC (if block number=3Fh)  

callback_megarom0:
                cmp     ecx,9000h
                jb      megarom0_switchbank_doit
                cmp     ecx,9FFFh
                ja      megarom0_switchbank_doit

                cmp     ecx,97FFh
                ja      megarom0_switchbank_SCC

                and     eax,03Fh
                cmp     al,03Fh
                jne     megarom0_switchbank_doit

                ; SCC selection
                mov     sccactive,1
                mov     sccdetected,1
                cmp     sccenabled,1
                jne     _ret
                call    retrieve_slot_info
                mov     ebx,sccram
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [eax+esi*8],ebx

                ret

megarom0_switchbank_doit:
                mov     ebx,eax
                and     ebx,01Fh ; only 256kb by now
                call    retrieve_slot_info
                mov     dword ptr [offset megablock+esi*4],ebx
                shl     ebx,13
                add     ebx,ecx
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [eax+esi*8],ebx
                mov     sccactive,0
                mov     eax,0
                ret

megarom0_switchbank_SCC:
                cmp     sccactive,1
                jne     megarom0_switchbank_doit

                cmp     sccenabled,1
                jne     megarom0_switchbank_doit

                ; SCC write

                cmp     cl,80h
                jb      megarom0_switchbank_SCC_write

                cmp     cl,90h
                jae     _ret

                sub     ecx,09880h
                mov     byte ptr [offset sccregs+ecx],al
                
                mov     ebx,ecx
                add     ebx,080h
                xchg    al,bl

                jmp     sound_buffer

megarom0_switchbank_SCC_write:
                mov     ch,0
                mov     esi,sccram
                irp     i,<8,9,10,11,12,13,14,15>
                mov     byte ptr [esi+ecx+1000h+i*100h],al
                endm
                ret

; callback_megarom2 --------------------------------------------------
; Konami MegaROM with SCC
; addresses:  5000h-57FFh block 4000h-5FFFh  
;             7000h-77FFh block 6000h-7FFFh  
;             9000h-97FFh block 8000h-9FFFh  
;             B000h-B7FFh block A000h-BFFFh  
;             9800h-97FFh SCC (if block number=3Fh)  

callback_megarom2:
                cmp     ecx,9000h
                jb      megarom2_switchbank_doit
                cmp     ecx,9FFFh
                ja      megarom2_switchbank_doit

                cmp     ecx,97FFh
                ja      megarom2_switchbank_SCC

                and     eax,03Fh
                cmp     al,03Fh
                jne     megarom2_switchbank_doit

                ; SCC selection
                mov     sccactive,1
                mov     sccdetected,1
                cmp     sccenabled,1
                jne     _ret
                call    retrieve_slot_info
                mov     ebx,sccram
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [eax+esi*8],ebx

                ret

megarom2_switchbank_doit:
                cmp     ecx,05000h
                jb      _ret
                cmp     ecx,0B800h
                jae     _ret

                mov     ebx,ecx
                and     ebx,0FFFh
                cmp     ebx,800h
                jae     _ret
                
                mov     ebx,eax
                and     ebx,01Fh ; only 256kb by now
                call    retrieve_slot_info
                mov     dword ptr [offset megablock+esi*4],ebx
                shl     ebx,13
                add     ebx,ecx
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [eax+esi*8],ebx
                mov     sccactive,0
                mov     eax,0
                ret

megarom2_switchbank_SCC:
                cmp     sccactive,1
                jne     megarom2_switchbank_doit

                cmp     sccenabled,1
                jne     megarom2_switchbank_doit

                ; SCC write

                cmp     cl,80h
                jb      megarom2_switchbank_SCC_write

                cmp     cl,90h
                jae     _ret

                sub     ecx,09880h
                mov     byte ptr [offset sccregs+ecx],al
                
                mov     ebx,ecx
                add     ebx,080h
                xchg    al,bl

                jmp     sound_buffer

megarom2_switchbank_SCC_write:
                mov     ch,0
                mov     esi,sccram
                irp     i,<8,9,10,11,12,13,14,15>
                mov     byte ptr [esi+ecx+1000h+i*100h],al
                endm
                ret

; callback_megarom3 --------------------------------------------------
; Konami MegaROM without SCC
; addresses:  <none>      block 4000h-5FFFh  
;             6000h       block 6000h-7FFFh  
;             8000h       block 8000h-9FFFh  
;             A000h       block A000h-BFFFh  

callback_megarom3:
                cmp     ecx,06000h
                je      callback_megarom3_ok
                cmp     ecx,08000h
                je      callback_megarom3_ok
                cmp     ecx,0A000h
                je      callback_megarom3_ok
                ret

callback_megarom3_ok:
                mov     ebx,eax
                and     ebx,01Fh ; only 256kb by now
                call    retrieve_slot_info
                mov     dword ptr [offset megablock+esi*4],ebx
                shl     ebx,13
                add     ebx,ecx
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [eax+esi*8],ebx
                mov     eax,0
                ret

; callback_megarom4 --------------------------------------------------
; ASCII 8kb
; addresses:  6000h-67FFh block 4000h-5FFFh
;             6800h-6FFFh block 6000h-7FFFh  
;             7000h-77FFh block 8000h-9FFFh  
;             7800h-7FFFh block A000h-BFFFh  

callback_megarom4:
                
                mov     esi,ecx
                cmp     esi,6000h
                jb      _ret
                cmp     esi,8000h
                jae     _ret
                sub     esi,6000h
                and     esi,1800h
                shr     esi,11
                add     esi,2

                ; at this point esi=logical page number                
                ; remember: the pair push ebx/pop ecx is correct

                mov     ebx,eax
                and     ebx,0ffh
                push    ebx
                shl     ebx,13
                call    retrieve_slot_info
                add     ebx,ecx
                pop     ecx
                
                mov     dword ptr [eax+esi*8],ebx
                mov     dword ptr [offset megablock+esi*4],ecx
                
                mov     ecx,esi
                and     ecx,0FEh
                push    ebx
                movzx   ebx,prim_slotreg
                shr     ebx,cl
                and     ebx,3
                ;
                movzx   ecx,prim_slotreg
                shr     ecx,2
                and     ecx,3
                ;
                mov     eax,0
                cmp     ebx,ecx
                pop     ebx
                jne     _ret
                mov     dword ptr [offset mem+esi*4],ebx
                ret

; callback_megarom5 --------------------------------------------------
; ASCII 16kb
; addresses:  6000h-6FFFh block 4000h-7FFFh
;             7000h-7FFFh block 8000h-BFFFh  

callback_megarom5:
                
                mov     esi,ecx
                cmp     esi,6000h
                jb      _ret
                cmp     esi,8000h
                jae     _ret
                sub     esi,6000h
                and     esi,1000h
                shr     esi,11
                add     esi,2

                ; at this point esi=logical page number                
                ; remember: the pair push ebx/pop ecx is correct

                mov     ebx,eax
                and     ebx,0ffh
                push    ebx
                shl     ebx,14
                call    retrieve_slot_info
                add     ebx,ecx
                pop     ecx
                
                mov     dword ptr [eax+esi*8],ebx
                mov     dword ptr [offset megablock+esi*4],ecx
                add     ebx,2000h
                inc     ecx
                mov     dword ptr [eax+esi*8+8],ebx
                mov     dword ptr [offset megablock+esi*4+4],ecx
                
                mov     ecx,esi
                push    ebx
                movzx   ebx,prim_slotreg
                shr     ebx,cl
                and     ebx,3
                ;
                movzx   ecx,prim_slotreg
                shr     ecx,2
                and     ecx,3
                ;
                mov     eax,0
                cmp     ebx,ecx
                pop     ebx
                jne     _ret
                sub     ebx,2000h
                mov     dword ptr [offset mem+esi*4],ebx
                add     ebx,2000h
                mov     dword ptr [offset mem+esi*4+4],ebx
                ret

; writemem -----------------------------------------------------------
; write a byte to Z80 memory
; in, ecx: address
; in, al: byte
; affect: esi,ebx

writemem:       
                ;mov     esi,codetable
                ;lea     esi,[esi+ecx*4]
                ;mov     dword ptr [esi],offset fetchcallback

                mov     esi,ecx                         ; clock 1 U
                shr     esi,13                          ; clock 2 U
                ; lock
                mov     ebx,[offset memlock+esi*4]
                or      ebx,ebx
                jnz     writemem0
                ;
                mov     ebx,ecx
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                ret
writemem0:      
                
                jmp     dword ptr [offset megarom_callback+ebx*4]

; writememw ----------------------------------------------------------
; write a word to Z80 memory
; in, ecx: address
; in, ax: word
; affect: esi,ebx

writememw:      
                ;mov     esi,codetable
                ;lea     esi,[esi+ecx*4]
                ;mov     dword ptr [esi+4],offset fetchcallback
                ;mov     dword ptr [esi],offset fetchcallback

                mov     esi,ecx                         
                mov     ebx,ecx
                shr     esi,13                          
                and     ebx,01FFFh
                cmp     ebx,01FFFh
                je      writememw_slow
                ; lock
                cmp     dword ptr [offset memlock+esi*4],0
                jne     writememw0
                ;
                mov     esi,[offset mem+esi*4]          
                mov     word ptr [esi+ebx],ax           
                ret

writememw0:
                mov     ah,0
                mov     ebx,[offset memlock+esi*4]
                jmp     writemem0

writememw_slow:
                push    eax ecx
                mov     ah,0
                call    writemem
                pop     ecx eax
                shr     eax,8
                inc     ecx
                call    writemem
                dec     ecx
                ret

; trace --------------------------------------------------------------
; executes only the next instruction
; in: edi = regpc , eax = 0

trace:
                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]
                mov     regpc,di
                mov     regaf,dx
                mov     clockcounter,ebp
                cmp     ebp,0
                jge     _ret
                add     ebp,TC
                mov     clockcounter,ebp
                ret

; set_vdp_interrupt --------------------------------------------------

set_vdp_interrupt:
                or      vdpstatus,10000000b
                ret

; compose_sound ------------------------------------------------------

compose_sound:
                mov     eax,offset psgcounter
                call    start_counter
                call    compose_soundstream
                mov     eax,offset psgcounter
                call    end_counter
                mov     eax,dword ptr [offset psgcounter]
                mov     psgrate,eax
                ret
                
; synch_emulation ----------------------------------------------------

synch_emulation:
                cmp     interrupt,1
                jne     synch_emulation
                ret

; checkpsg -----------------------------------------------------------

checkpsg:
                cmp     speaker,1
                jne     checkpsg_start

                call    compose_speaker

checkpsg_start:
                cmp     psgclear,1
                je      checkpsg_clear
                add     psgclocks,TC
                ret

checkpsg_clear:
                mov     psgclocks,0
                mov     psgclear,0
                ret

; process_frame ------------------------------------------------------
; process a frame and blit the result

process_frame:

                dec     on_off
                jnz     _ret
                
                push    eax edx edi ebp

                mov     eax,framerate
                mov     on_off,eax

                call    pre_dirty

                call    video_processing

                cmp     vsyncflag,1
                jne     process_frame_vsyncskip

                call    wait_vsync

process_frame_vsyncskip:
                
                mov     eax,offset blitcounter
                call    start_counter
                call    blit
                mov     eax,offset blitcounter
                call    end_counter
                mov     eax,dword ptr [offset blitcounter]
                mov     blitrate,eax

                pop     ebp edi edx eax

                ret

; video_processing ---------------------------------------------------
; perform all video processing including render, sprite and gui

video_processing:
                mov     eax,offset rendercounter
                call    start_counter
                cli
                call    render
                sti
                mov     eax,offset rendercounter
                call    end_counter
                mov     eax,dword ptr [offset rendercounter]
                mov     renderrate,eax

                mov     eax,offset spritecounter
                call    start_counter
                call    sprite_render
                mov     eax,offset spritecounter
                call    end_counter
                mov     eax,dword ptr [offset spritecounter]
                mov     spriterate,eax

                mov     eax,offset guicounter
                call    start_counter
                call    draw_gui
                mov     eax,offset guicounter
                call    end_counter
                mov     eax,dword ptr [offset guicounter]
                mov     guirate,eax

                ret

; z80_interrupt ------------------------------------------------------
; perform a Z80 interrupt
; this is sensitive to IM 1 and IM 2 differences

z80_interrupt:
                cmp     imtype,2
                je      z80_interrupt_im2

                ; IM 0 and IM 1
                call    emulIM
                mov     edi,038h
                ret

z80_interrupt_im2:
                ; IM 2
                call    emulIM
                mov     ch,regi
                mov     cl,0FFh
                call    readmemw
                mov     edi,eax
                mov     eax,0
                ret

PUSHREGW        IM,edi,0

; pre_dirty ----------------------------------------------------------
; this routine pre-dirty some parts of screen
; used for transparency effects, like in PSG GRAPH routine

pre_dirty:
                cmp     psggraph,1
                jne     _ret
                
                mov     word ptr [offset dirtyname+30+0*32],0101h
                mov     word ptr [offset dirtyname+30+1*32],0101h
                mov     word ptr [offset dirtyname+30+2*32],0101h
                mov     word ptr [offset dirtyname+30+3*32],0101h

                cmp     sccenabled,0
                je      _ret

                mov     dword ptr [offset dirtyname+27+0*32],01010101h
                mov     dword ptr [offset dirtyname+27+1*32],01010101h
                mov     dword ptr [offset dirtyname+27+2*32],01010101h
                mov     dword ptr [offset dirtyname+27+3*32],01010101h

                ret


; check_mouse --------------------------------------------------------
; if the mouse button is pressed, then start the GUI 
; and pause emulation

check_mouse:
                pushad
                call    read_mouse
                cmp     mouseleft,1
                jne     check_mouse_end

                mov     cpupaused,1

check_mouse_end:
                popad
                ret

; check_client -------------------------------------------------------
; if the emulator is in a SERVER session
; then this function call the client to get 
; joystick information

check_client:
                cmp     sessionmode,1
                jne     _ret

                pushad
                call    UART_send_idstring
                call    UART_receive
                mov     psgjoyb,al
                popad
                ret

; set_keyboard_leds --------------------------------------------------
; set the keyboard leds

set_keyboard_leds:
                push    eax
                mov     al,newleds
                cmp     al,oldleds
                je      set_keyboard_leds_exit
                pushad
                mov     bl,newleds
                mov     oldleds,bl
                call    setkb
                popad
                pop     eax
                ret

set_keyboard_leds_exit:
                pop     eax
                ret

; check_joystick -----------------------------------------------------
; check the joystick status

check_joystick:
                cmp     joyenable,0
                je      _ret

                push    eax
                call    read_joystick
                cmp     joyenable,2
                je      check_joystick_b

                mov     psgjoya,al
                jmp     check_joystick_exit
check_joystick_b:
                mov     psgjoyb,al

check_joystick_exit:
                pop     eax
                ret

; z80paused ----------------------------------------------------------
; pauses the Z80 and starts the gui
; must preserve ebp,eax,edx,edi,esp

z80paused:
                cmp     savesnap,1
                je      z80paused_savesnap
                
                cmp     cpupaused,1
                jne     _ret
                
                push    ebp eax edx edi

                mov     reset_flag,0
                mov     regeaf,edx
                mov     regepc,edi
                mov     clockcounter,ebp

                call    sound_off
                call    start_gui
                call    sound_on

                pop     edi edx eax ebp

                cmp     reset_flag,1
                jne     _ret

                mov     edx,regeaf
                mov     edi,regepc
                mov     ebp,clockcounter
                mov     reset_flag,0

                ret

z80paused_savesnap:
                pushad
                call    sound_off
                call    save_snapshot_pcx
                call    sound_on
                mov     savesnap,0
                popad
                ret

; reset_cpu ----------------------------------------------------------
; reset the MSX

reset_cpu:
                ; put the pc at address 0
                mov     regepc,0

                ; lots of clocks
                mov     clockcounter,TC

                ; enable all ROM
                mov     bl,0
                call    outemulA8

                ; disable interrupts
                mov     iff1,0
                mov     iline,0
                mov     fakeirq,0
                mov     vdpstatus,0

                ; clear keyboard matrix
                mov     edi,offset keymatrix
                mov     eax,0FFFFFFFFh
                mov     ecx,16/4
                rep     stosd

                ; clear vram
                ;mov     edi,msxvram
                ;mov     ecx,16384/4
                ;mov     eax,0
                ;rep     stosd

                ; clear psg registers
                mov     edi,offset psgreg
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; clear scc memory
                mov     edi,sccram
                mov     ecx,8192/4
                mov     eax,0
                rep     stosd

                ; clear scc registers
                mov     edi,offset sccregs
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; inform to main routine that MSX is reseted
                mov     reset_flag,1
                ret

; reset_cpu_hard -----------------------------------------------------
; reset the MSX and erase all memory

reset_cpu_hard:
                ; put the pc at address 0
                mov     regepc,0

                ; lots of clocks
                mov     clockcounter,TC

                ; enable all ROM
                mov     bl,0
                call    outemulA8

                ; disable interrupts
                mov     iff1,0
                mov     iline,0
                mov     fakeirq,0
                mov     vdpstatus,0

                ; clear keyboard matrix
                mov     edi,offset keymatrix
                mov     eax,0FFFFFFFFh
                mov     ecx,16/4
                rep     stosd

                ; clear vram
                mov     edi,msxvram
                mov     ecx,16384/4
                mov     eax,0
                rep     stosd

                ; clear ram
                mov     edi,msxram
                mov     ecx,128*1024/4
                mov     eax,0
                rep     stosd

                ; clear psg registers
                mov     edi,offset psgreg
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; clear scc memory
                mov     edi,sccram
                mov     ecx,8192/4
                mov     eax,0
                rep     stosd

                ; clear scc registers
                mov     edi,offset sccregs
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; inform to main routine that MSX is reseted
                mov     reset_flag,1
                ret

; print --------------------------------------------------------------
; prints only the next instruction
; in: edi = regpc , eax = 0

print:
                call    fetch
                call    [offset pset + eax*4]
                ret

; sound_buffer -------------------------------------------------------
; add a sound event to the sound buffer
; enter al=register, bl=value
; destroy ecx,ebx,esi
                
sound_buffer:
                mov     ecx,psgpos
                cmp     ecx,32768
                jae     _ret

                mov     esi,soundbuffer
                mov     [esi+ecx*2],al
                mov     [esi+ecx*2+1],bl

                mov     esi,timebuffer
                mov     ebx,TC 
                sub     ebx,ebp
                add     ebx,psgclocks
                mov     [esi+ecx*4],ebx

                inc     psgpos

                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

outemul8E:
                mov     eax,2
                irp     i,<2,3,4,5>
                mov     dword ptr [offset slot1+i*8+4],eax
                endm
                mov     bl,prim_slotreg
                shr     ebx,2
                and     ebx,3
                cmp     ebx,1
                jne     outemul8E_page2
                mov     dword ptr [offset memlock+2*4],eax
                mov     dword ptr [offset memlock+3*4],eax
outemul8E_page2:
                mov     bl,prim_slotreg
                shr     ebx,4
                and     ebx,3
                cmp     ebx,1
                jne     _ret
                mov     dword ptr [offset memlock+4*4],eax
                mov     dword ptr [offset memlock+5*4],eax
                ret

outemul98:      mov     esi,msxvram
                mov     eax,vdpaddresse
                mov     ecx,eax
                inc     eax
                and     eax,03FFFh
                mov     vdpaddresse,eax
                xor     eax,eax
                cmp     imagetype,0
                je      outemul98_ret
                
                mov     eax,ecx
                shr     eax,6
                and     eax,0FFh
                mov     al,[offset vrammapping+eax]
                jmp     [offset screenselect+eax*4]
                
outemul98_ret:
                mov     [ecx+esi],bl
                ret

outemul99:      cmp     vdpcond,0
                jne     outemul99a
                mov     vdpcond,1
                mov     vdptemp,bl
                ret
outemul99a:     mov     vdpcond,0
                test    bl,10000000b
                jnz     outemul99b
                cmp     bl,01000000b
                jb      outemul99_read
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     vdpaccess,1
                ret
outemul99_read:
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     ecx,vdpaddresse
                mov     esi,msxvram
                mov     bl,[esi+ecx]
                mov     vdplookahead,bl
                inc     ecx
                and     ecx,03FFFh
                mov     vdpaddresse,ecx
                mov     vdpaccess,0
                ret

outemul99b:     and     ebx,00000111b
                mov     al,vdptemp
                mov     cl,byte ptr [offset vdpregs+ebx]
                cmp     cl,al
                je      _ret
                mov     byte ptr [offset vdpregs+ebx],al
                cmp     bl,7
                je      set_border_color
                cmp     bl,1
                je      outemul99_checkirq
outemul99_update:
                mov     firstscreen,1
                jmp     eval_base_address

outemul99_checkirq:
                ;test    cl,BIT_5
                ;jnz     outemul99_update
                ;test    al,BIT_5
                ;jz      outemul99_update
                ;;and     vdpstatus,NBIT_7
                ;;;
                ;cmp     iline,0
                ;je      outemul99_update
                ;mov     clocksleft,ebp
                ;mov     fakeirq,1
                ;mov     ebp,0
                ;;;;
                ;jmp     outemul99_update
                ;
                cmp     iline,0
                je      outemul99_turnedoff

                ; at this point iline=1
                ; if bit 5 goes to zero, then iline must drop to zero also
                test    al,BIT_5
                jnz     outemul99_update
                
                mov     iline,0
                jmp     outemul99_update

outemul99_turnedoff:
                ; at this point iline=0
                ; if bit 5 goes to 1, and bit 7 is also 1
                ; this irq will happen NOW, unless iff1=0
                test    al,BIT_5
                jz      outemul99_update

                test    vdpstatus,BIT_7
                jz      outemul99_update

                mov     iline,1
                cmp     iff1,1
                jne     outemul99_update

                mov     clocksleft,ebp
                mov     fakeirq,1
                mov     ebp,0

                jmp     outemul99_update
                
outemulA0:      
                and     bl,0Fh
                mov     psgselect,bl
                ret

outemulA1:      mov     al,psgselect        
                mov     [offset psgreg+eax],bl
                cmp     al,15
                je      outemulA1_kana
                cmp     al,13
                ja      _ret

                jmp     sound_buffer

outemulA1_kana:
                and     bl,80h
                cmp     psgkana,bl
                je      _ret
                
                ; Kana LED
                mov     psgkana,bl
                xor     bl,255
                and     bl,BIT_7
                shr     bl,6
                and     newleds,NBIT_1
                or      newleds,bl
                
                ret

outemulA8:      
                movzx   esi,prim_slotreg
                mov     prim_slotreg,bl
                
                irp     i,<0,1,2,3>
                mov     bl,prim_slotreg
                shr     bl,i*2
                and     ebx,03h
                shl     ebx,6
                
                irp     j,<0,1>
                mov     ecx,dword ptr [offset slot+ebx+16*i+8*j]
                mov     dword ptr [offset mem+(i*2+j)*4],ecx
                mov     ecx,dword ptr [offset slot+ebx+16*i+8*j+4]
                mov     dword ptr [offset memlock+(i*2+j)*4],ecx
                endm
                
                endm

                ;call    slot_change

                ret

outemulAA:      
                mov     al,bl
                mov     ppic,bl
                and     bl,0fh
                mov     keyboard_line,bl

                ; Caps Lock LED
                mov     bl,al
                xor     bl,255
                and     bl,BIT_6
                shr     bl,4
                and     newleds,NBIT_2
                or      newleds,bl

                ; Keyboard click
                mov     bl,16
                and     al,080h
                shr     al,2
                xchg    al,bl
                call    sound_buffer

                ; Cassete output
                mov     bl,ppic
                and     bl,020h
                mov     al,17
                jmp     sound_buffer

outemulAB:
                test    bl,BIT_7
                jnz     _ret

                mov     cl,bl
                shr     cl,1
                and     cl,7
                mov     bh,1
                shl     bh,cl

                test    bl,BIT_0
                jz      outemulAB_reset

                mov     bl,ppic
                or      bl,bh
                jmp     outemulAA

outemulAB_reset:

                mov     bl,ppic
                xor     bh,255
                and     bl,bh
                jmp     outemulAA

MAPPER          macro   page

                mov     al,prim_slotreg
                shr     al,page*2
                and     al,3h
                cmp     al,2
                jne     _ret

                and     ebx,7h
                shl     ebx,14
                add     ebx,msxram
                mov     esi,ramslot
                mov     dword ptr [esi+page*16],ebx
                mov     dword ptr [offset mem+page*8],ebx
                add     ebx,2000h
                mov     dword ptr [esi+page*16+8],ebx
                mov     dword ptr [offset mem+page*8+4],ebx
                ret

                endm

outemulFC:
                MAPPER  0

outemulFD:
                MAPPER  1

outemulFE:
                MAPPER  2

outemulFF:
                MAPPER  3

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       mov     bl,0FFh
                ret

inemul8E:
                mov     eax,0
                irp     i,<2,3,4,5>
                mov     dword ptr [offset slot1+i*8+4],eax
                endm
                mov     bl,prim_slotreg
                shr     ebx,2
                and     ebx,3
                cmp     ebx,1
                jne     inemul8E_page2
                mov     dword ptr [offset memlock+2*4],eax
                mov     dword ptr [offset memlock+3*4],eax
inemul8E_page2:
                mov     bl,prim_slotreg
                shr     ebx,4
                and     ebx,3
                cmp     ebx,1
                jne     _ret
                mov     dword ptr [offset memlock+4*4],eax
                mov     dword ptr [offset memlock+5*4],eax
                ret

inemul98:       mov     ecx,msxvram
                mov     esi,vdpaddresse
                mov     bl,vdplookahead
                mov     bh,[ecx+esi]
                inc     esi
                and     esi,03FFFh
                mov     vdpaddresse,esi
                mov     vdplookahead,bh
                ret

inemul99:       mov     bl,vdpstatus
                and     vdpstatus,01111111b
                mov     vdpcond,0
                mov     iline,0
                ret

inemulAA:
                mov     bl,ppic
                ret

inemulA2:       mov     al,psgselect
                cmp     al,14
                je      inemulA2a
                mov     bl,[offset psgreg+eax]
                ret
inemulA2a:      
                mov     al,byte ptr [offset psgreg+15]
                test    al,BIT_6
                jnz     inemulA2b
                mov     bl,psgjoya
                ret
inemulA2b:
                mov     bl,psgjoyb
                ret

inemulA8:       mov     bl,prim_slotreg
                ret

inemulA9:       movzx   ecx,keyboard_line
                mov     bl,byte ptr [offset keymatrix+ecx]
                ret

; --------------------------------------------------------------------

code32          ends
                end





