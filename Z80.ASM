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
extrn cart1: dword
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
public emulate
public emulate_break
public emulate_trap
public emulate_histogr
public outemulXX
public inemulXX
public outportxx
public inportxx
public outemulA8
public megarom0_switchbank
public histogr
public error

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

;include daa.inc
;include daa1.inc
;include daa2.inc
;include daa3.inc
;include daa4.inc
;include daas.inc

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
mem00           dd      ?
mem20           dd      ?
mem40           dd      ?
mem60           dd      ?
mem80           dd      ?
memA0           dd      ?
memC0           dd      ?
memE0           dd      ?

memlock:               
memlock00       dd      1
memlock20       dd      1
memlock40       dd      1
memlock60       dd      1
memlock80       dd      1
memlockA0       dd      1
memlockC0       dd      1
memlockE0       dd      1

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
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
                dd      ?
                dd      0
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

; Z80 registers
align 4

breakpoint      dd      0
iff1            dd      0
interrupt       dd      0
error           dd      0
rcounter        dd      0        
clockcounter    dd      0
emulatemode     dd      0
megarommode     dd      0
z80counter      db      8 dup (0)
z80rate         dd      0
reset_flag      dd      0
rmask           db      0
regi            db      0

; VDP registers
align 4

vdpcond         dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      8 dup (0)
vsyncflag       dd      0
vdptemp         db      0
vdpstatus       db      0

; PSG registers
align 4

psgselect       db      0
psgreg          db      16 dup (0)
psgjoyb         db      00111111b

; PPI registers
align 4

prim_slotreg    db      0
keyboard_line   db      0
ppic            db      0

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

; FETCHMACRO ---------------------------------------------------------
; fetch a byte from Z80 memory (macro version)
; in, edi: address
; out, al: byte
; affect: esi,ebx

FETCHMACRO      macro   skip
                
                lea     esi,[edi+skip]                  ; clock 1 U
                lea     ebx,[edi+skip]                  ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     al,[esi+ebx]                    ; clock 6 U [AGI]

                endm

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

; FETCHWMACRO --------------------------------------------------------
; fetch a word from Z80 memory (MACRO VERSION)
; in, edi: address
; out, ax: word
; affect: esi,ebx

FETCHWMACRO     macro   skip

                lea     esi,[edi+skip]                  ; clock 1 U
                lea     ebx,[edi+skip]                  ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                cmp     ebx,01fffh                      ; clock 3 U
                je      fetchw_slow_&skip               ; clock 3 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U 
                mov     ax,word ptr [esi+ebx]           ; clock 6 U [AGI]
                ret
fetchw_slow_&skip:  
                FETCHMACRO skip
                mov     ah,al
                FETCHMACRO skip+1
                ret

                endm

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

; megarom0_switchbank ------------------------------------------------
; switch megarom bank with mode 0 megaroms (konami 8kb)
; esi = address shr 13
; eax = block number

megarom0_switchbank:
                mov     dword ptr [offset megablock+esi*4],eax
                mov     ebx,eax
                and     ebx,0ffh
                shl     ebx,13
                add     ebx,cart1
                mov     dword ptr [offset mem+esi*4],ebx
                mov     dword ptr [offset slot1+esi*8],ebx
                ret

; writemem -----------------------------------------------------------
; write a byte to Z80 memory
; in, ecx: address
; in, al: byte
; affect: esi,ebx

writemem:       mov     esi,ecx                         ; clock 1 U
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
                cmp     ebx,1
                je      _ret
                cmp     ebx,2
                je      megarom0_switchbank

writemem1:
                cmp     ebx,7
                jne     _ret

                ; megarom mode 5 - ascii 16kb
                mov     esi,ecx
                cmp     esi,6000h
                jb      _ret
                cmp     esi,8000h
                jae     _ret
                and     esi,1000h
                shr     esi,11
                add     esi,2
                mov     ebx,eax
                and     ebx,0ffh
                shl     ebx,14
                add     ebx,cart1
                mov     dword ptr [offset slot1+esi*8],ebx
                add     ebx,2000h
                mov     dword ptr [offset slot1+esi*8+8],ebx
                cmp     dword ptr [offset mem+esi*8+4],7
                jne     _ret
                sub     ebx,2000h
                mov     dword ptr [offset mem+esi*8],ebx
                add     ebx,2000h
                mov     dword ptr [offset mem+esi*8+8],ebx
                ret


; writememw ----------------------------------------------------------
; write a word to Z80 memory
; in, ecx: address
; in, ax: word
; affect: esi,ebx

writememw:      
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
                jmp     writemem0

writememw_slow:
                push    eax
                mov     ah,0
                call    writemem
                pop     eax
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
                ret

; emulate ------------------------------------------------------------

BREAK           EQU     0
NOBREAK         EQU     1
TRAP            EQU     2
HISTOGRAM       EQU     3

NORMAL          EQU     0
FAST            EQU     1       
TURBO           EQU     2       

JUMP            macro   jump,jpoint,emtype,brtype

                jump    emulate_&emtype&_&brtype&_&jpoint

                endm

EMULABEL        macro   point,emtype,brtype

                emulate_&emtype&_&brtype&_&point&:

                endm

EMULATE         macro   emtype,brtype

                xor     eax,eax
                xor     ecx,ecx
                mov     error,eax
                mov     exit_now,eax
                mov     interrupt,eax
                mov     firstscreen,1
                mov     ebp,59659
                movzx   edi,regpc
                movzx   edx,regaf

EMULABEL        loop,emtype,brtype

                ;and     edi,0ffffh
                
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                JUMP    je,exit,emtype,brtype
                endif

                FETCHMACRO 0

                if      brtype EQ HISTOGRAM
                inc     dword ptr [offset histogr+eax*4]
                endif

                inc     rcounter
                call    [offset iset + eax*4]
                
                if      (emtype EQ FAST)
                  cmp   interrupt,1
                  JUMP  je,interrupt,emtype,brtype
                  JUMP  jmp,loop,emtype,brtype
                else
                  cmp   ebp,0
                  JUMP  jg,loop,emtype,brtype
                endif

                if      (brtype EQ TRAP)
                mov     interrupt,1
                mov     exit_now,1
                endif

                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                
                mov     eax,offset psgcounter
                call    start_counter
                call    compose_soundstream
                mov     eax,offset psgcounter
                call    end_counter
                mov     eax,dword ptr [offset psgcounter]
                mov     psgrate,eax
                
                xor     eax,eax

EMULABEL        synch,emtype,brtype
                
                if      emtype EQ NORMAL
                cmp     interrupt,1
                JUMP    jne,synch,emtype,brtype
                endif

EMULABEL        interrupt,emtype,brtype

                call    check_mouse

                cmp     cpupaused,1
                JUMP    jne,continue,emtype,brtype

                call    z80paused
                
EMULABEL        continue,emtype,brtype

                
                dec     on_off
                JUMP    jnz,nextint,emtype,brtype

                push    eax edx edi

                mov     eax,framerate
                mov     on_off,eax

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

                cmp     vsyncflag,1
                JUMP    jne,vsyncskip,emtype,brtype

                call    wait_vsync

EMULABEL        vsyncskip,emtype,brtype
                
                mov     eax,offset blitcounter
                call    start_counter
                call    blit
                mov     eax,offset blitcounter
                call    end_counter
                mov     eax,dword ptr [offset blitcounter]
                mov     blitrate,eax

                or      vdpstatus,10000000b
                
                pop     edi edx eax

EMULABEL        nextint,emtype,brtype

                
                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax
                mov     ebp,59659
                mov     interrupt,0
                
                cmp     error,1
                JUMP    je,exit,emtype,brtype
                cmp     exit_now,1
                JUMP    je,exit,emtype,brtype
                
                call    check_client
                
                cmp     iff1,1
                JUMP    jne,loop,emtype,brtype
                
                mov     iff1,0 
                dec     edi
                and     edi,0ffffh
                inc     rcounter
                call    emulFF
                JUMP    jmp,loop,emtype,brtype

EMULABEL        exit,emtype,brtype
                
                mov     regpc,di
                mov     regaf,dx
                ret

                endm

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

; z80paused ----------------------------------------------------------
; pauses the Z80 and starts the gui
; must preserve ebp,eax,edx,edi,esp

z80paused:
                push    ebp eax edx edi

                mov     reset_flag,0
                mov     regeaf,edx
                mov     regepc,edi

                call    sound_off
                call    start_gui
                call    sound_on

                pop     edi edx eax ebp

                cmp     reset_flag,1
                jne     _ret

                mov     edx,regeaf
                mov     edi,regepc
                mov     reset_flag,0

                ret

; emulate ------------------------------------------------------------
; starts emulation, stop with any error

emulate:        
                cmp     emulatemode,NORMAL
                jne     emulate1
                EMULATE NORMAL,NOBREAK
emulate1:       cmp     emulatemode,FAST
                jne     emulate2
                EMULATE FAST,NOBREAK
emulate2:       EMULATE TURBO,NOBREAK

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:        
                cmp     emulatemode,NORMAL
                jne     emulate1_break
                EMULATE NORMAL,BREAK
emulate1_break: cmp     emulatemode,FAST
                jne     emulate2_break
                EMULATE FAST,BREAK
emulate2_break: EMULATE TURBO,BREAK

; emulate_trap -------------------------------------------------------
; starts emulation with trap, stop with any error

emulate_trap:        
                cmp     emulatemode,NORMAL
                jne     emulate1_trap
                EMULATE NORMAL,TRAP
emulate1_trap:  cmp     emulatemode,FAST
                jne     emulate2_trap
                EMULATE FAST,TRAP
emulate2_trap:  EMULATE TURBO,TRAP

; emulate_histogr ----------------------------------------------------
; starts emulation with histogram evaluation, stop with any error

emulate_histogr:        
                cmp     emulatemode,NORMAL
                jne     emulate1_histogr
                EMULATE NORMAL,HISTOGRAM
emulate1_histogr:  
                cmp     emulatemode,FAST
                jne     emulate2_histogr
                EMULATE FAST,HISTOGRAM
emulate2_histogr:  
                EMULATE TURBO,HISTOGRAM

; reset_cpu ----------------------------------------------------------
; reset the MSX

reset_cpu:
                ; put the pc at address 0
                mov     regepc,0

                ; enable all ROM
                mov     bl,0
                call    outemulA8

                ; disable interrupts
                mov     iff1,0

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

                ; clear psg registers
                mov     edi,offset psgreg
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; if a megarom is loaded, then init it
                cmp     dword ptr [offset slot1+16+4],2
                jne     reset_cpu_nomegarom

                mov     esi,(04000h SHR 13)
                mov     eax,0
                call    megarom0_switchbank
                
                mov     esi,(06000h SHR 13)
                mov     eax,1
                call    megarom0_switchbank

                mov     esi,(08000h SHR 13)
                mov     eax,2
                call    megarom0_switchbank

                mov     esi,(0A000h SHR 13)
                mov     eax,3
                call    megarom0_switchbank

reset_cpu_nomegarom:

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

; --------------------------------------------------------------------

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

outemul98:      mov     esi,msxvram
                mov     ecx,vdpaddresse
                inc     vdpaddress
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
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                ret
outemul99b:     and     ebx,00000111b
                mov     al,vdptemp
                cmp     byte ptr [offset vdpregs+ebx],al
                je      _ret
                mov     byte ptr [offset vdpregs+ebx],al
                cmp     bl,7
                je      set_border_color
                mov     firstscreen,1
                jmp     eval_base_address

outemulA0:      mov     psgselect,bl
                ret

outemulA1:      mov     al,psgselect        
                mov     [offset psgreg+eax],bl
                ret

outemulA8:      mov     prim_slotreg,bl
                ; frame 0
                and     ebx,03h
                shl     ebx,6
                mov     ecx,dword ptr [offset slot+ebx]
                mov     mem00,ecx
                mov     ecx,dword ptr [offset slot+ebx+8]
                mov     mem20,ecx
                mov     ecx,dword ptr [offset slot+ebx+4]
                mov     memlock00,ecx
                mov     ecx,dword ptr [offset slot+ebx+4+8]
                mov     memlock20,ecx
                ; frame 1
                mov     bl,prim_slotreg
                shr     bl,2
                and     ebx,03h
                shl     ebx,6
                mov     ecx,dword ptr [offset slot+ebx+16]
                mov     mem40,ecx
                mov     ecx,dword ptr [offset slot+ebx+16+8]
                mov     mem60,ecx
                mov     ecx,dword ptr [offset slot+ebx+16+4]
                mov     memlock40,ecx
                mov     ecx,dword ptr [offset slot+ebx+16+4+8]
                mov     memlock60,ecx
                ; frame 2
                mov     bl,prim_slotreg
                shr     bl,4
                and     ebx,03h
                shl     ebx,6
                mov     ecx,dword ptr [offset slot+ebx+32]
                mov     mem80,ecx
                mov     ecx,dword ptr [offset slot+ebx+32+8]
                mov     memA0,ecx
                mov     ecx,dword ptr [offset slot+ebx+32+4]
                mov     memlock80,ecx
                mov     ecx,dword ptr [offset slot+ebx+32+4+8]
                mov     memlockA0,ecx
                ; frame 3
                mov     bl,prim_slotreg
                shr     bl,6
                and     ebx,03h
                shl     ebx,6
                mov     ecx,dword ptr [offset slot+ebx+48]
                mov     memC0,ecx
                mov     ecx,dword ptr [offset slot+ebx+48+8]
                mov     memE0,ecx
                mov     ecx,dword ptr [offset slot+ebx+48+4]
                mov     memlockC0,ecx
                mov     ecx,dword ptr [offset slot+ebx+48+4+8]
                mov     memlockE0,ecx
                ret

outemulAA:      mov     ppic,bl
                and     bl,0fh
                mov     keyboard_line,bl
                ret

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       ret

inemul98:       mov     ecx,msxvram
                add     ecx,vdpaddresse
                mov     bl,[ecx]
                inc     vdpaddress
                ret

inemul99:       mov     bl,vdpstatus
                and     vdpstatus,01111111b
                mov     vdpcond,0
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
                mov     bl,00111111b
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




