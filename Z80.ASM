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
extrn dirtyname: dword

include io.inc
include vdp.inc
include debug.inc
include bit.inc
include opcode.inc
include z80supp.inc
include pmode.inc
include gui.inc

public fetch
public fetchw
public readmem
public writemem
public trace
public print
public emulate
public emulate_break
public emulate_trap
public emulXX
public emulC9
public outemulXX
public inemulXX
public outportxx
public inportxx
public outemulA8
public megarom0_switchbank

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

; DATA ---------------------------------------------------------------

align 4

include iset.inc
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
include daa1.inc
include daa2.inc
include daa3.inc
include daa4.inc
include daas.inc
include inc.inc
include dec.inc
include int.inc
include cp.inc

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
rmask           db      0
regi            db      0

; VDP registers
align 4

vdpcond         dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      8 dup (0)
vdptemp         db      0
vdpstatus       db      0

; PSG registers
align 4

psgselect       db      0
psgreg          db      16 dup (0)

; PPI registers
align 4

prim_slotreg    db      0
keyboard_line   db      0
ppic            db      0

align 4

keymatrix       db      16 dup (0ffh)

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

SIGN_FLAG       equ     10000000b
ZERO_FLAG       equ     01000000b
HALF_FLAG       equ     00010000b
PARITY_FLAG     equ     00000100b
OVERFLOW_FLAG   equ     00000100b
SUBTRACT_FLAG   equ     00000010b
CARRY_FLAG      equ     00000001b

; setflag_cpl --------------------------------------------------------
; sets the z80 flags after cpl operations

setflag_cpl     macro

                or      dl,00010010b
                
                endm

; fetch --------------------------------------------------------------
; fetch a byte from Z80 memory
; in, edi: address
; out, al: byte
; affect: esi,ebx

fetch:          mov     esi,edi                         ; clock 1 U
                mov     ebx,edi                         ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     al,byte ptr [esi+ebx]           ; clock 6 U [AGI]
                ret

fetchw:         mov     esi,edi                         ; clock 1 U
                mov     ebx,edi                         ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                cmp     ebx,01fffh                      ; clock 3 U
                je      fetchw_slow                     ; clock 3 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U 
                mov     ax,word ptr [esi+ebx]           ; clock 6 U [AGI]
                ret
fetchw_slow:  
                call    fetch
                inc     di
                mov     ah,al
                call    fetch
                dec     di
                ret


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
                jz      _ret
                cmp     ebx,2
                jne     writemem1

                ; megarom mode 0 - konami 8kb
                jmp     megarom0_switchbank

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
                mov     clockcounter,eax
                movzx   edi,regpc
                movzx   edx,regaf

EMULABEL        loop,emtype,brtype

                and     edi,0ffffh
                
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                JUMP    je,exit,emtype,brtype
                endif

                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]
                
                if      (emtype EQ FAST)
                  cmp   interrupt,1
                  JUMP  je,interrupt,emtype,brtype
                  JUMP  jmp,loop,emtype,brtype
                else
                  add   clockcounter,ebp
                  cmp   clockcounter,59659
                  JUMP  jb,loop,emtype,brtype
                endif

                if      (brtype EQ TRAP)
                mov     interrupt,1
                mov     exit_now,1
                endif

                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                xor     eax,eax

EMULABEL        synch,emtype,brtype
                
                if      emtype EQ NORMAL
                cmp     interrupt,1
                JUMP    jne,synch,emtype,brtype
                endif

EMULABEL        interrupt,emtype,brtype

                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax
                mov     clockcounter,0
                mov     interrupt,0
                cmp     error,1
                JUMP    je,exit,emtype,brtype
                cmp     exit_now,1
                JUMP    je,exit,emtype,brtype
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

; print --------------------------------------------------------------
; prints only the next instruction
; in: edi = regpc , eax = 0

print:
                call    fetch
                call    [offset pset + eax*4]
                ret

; --------------------------------------------------------------------

; 00 - NOP
emul00:         inc     edi
                mov     ebp,4+1
                ret

; 01 - LD BC,dddd
emul01:         inc     edi
                call    fetchw
                mov     regebc,eax
                add     edi,2
                xor     eax,eax
                mov     ebp,10+3
                ret

; 02 - LD (BC),A
emul02:         inc     edi
                mov     ecx,regebc
                mov     al,dh
                call    writemem
                mov     ebp,7+2
                ret


; 03 - INC BC
INCWREG         03,regbc,6

; 04 - INC B
INCREG          04,regb

; 05 - DEC B
DECREG          05,regb

; 06 - LD B,dd
LDREGIMM        06,regb

; 07 - RLCA
OPRLCA          07

; 08 - EX AF,AF'
emul08:         inc     edi
                mov     ebx,edx
                mov     ecx,regeafl
                mov     edx,ecx
                mov     regeafl,ebx
                mov     ebp,4+1
                ret

; 09 - ADD HL,BC
ADDREGWREGW     09,regl,regh,regc,regb,11

; 0A - LD A,(BC)
emul0A:         inc     edi
                mov     ecx,regebc
                call    readmem
                mov     dh,al
                mov     ebp,7+2
                ret

; 0B - DEC BC
DECWREG         0B,regbc,6

; 0C - INC C
INCREG          0C,regc

; 0D - DEC C
DECREG          0D,regc

; 0E - LD C,dd
LDREGIMM        0E,regc

; 0F - RRCA
OPRRCA          0F      

; 10 - DJNZ dd
emul10:         inc     edi
                call    fetch
                inc     edi
                dec     regb
                jz      emul10a
                movsx   ebx,al
                add     edi,ebx
                mov     ebp,13+2
                ret
emul10a:        mov     ebp,8+2
                ret

; 11 - LD DE,dddd
emul11:         inc     edi
                call    fetchw
                add     edi,2
                mov     regede,eax
                xor     eax,eax
                mov     ebp,10+3
                ret

; 12 - LD (DE),A
emul12:         inc     edi
                mov     ecx,regede
                mov     al,dh
                call    writemem
                mov     ebp,7+2
                ret

; 13 - INC DE
INCWREG         13,regde,6

; 14 - INC D
INCREG          14,regd

; 15 - DEC D
DECREG          15,regd

; 16 - LD D,dd
LDREGIMM        16,regd

; 17 - RLA
OPRLA           17

; 18 - JR dd
emul18:         inc     edi
                call    fetch
                movsx   ebx,al
                mov     ebp,12+2
                lea     edi,[edi+ebx+1]
                ret

; 19 - ADD HL,DE
ADDREGWREGW     19,regl,regh,rege,regd,11

; 1A - LD A,(DE)
emul1A:         inc     edi
                mov     ecx,regede
                call    readmem
                mov     dh,al
                mov     ebp,7+2
                ret

; 1B - DEC DE
DECWREG         1B,regde,6

; 1C - INC E
INCREG          1C,rege

; 1D - DEC E
DECREG          1D,rege

; 1E - LD E,dd
LDREGIMM        1E,rege

; 1F - RRA
OPRRA           1F

; 20 - JR NZ,dd
JRCC            20,jnz,ZERO_FLAG

; 21 - LD HL,dddd
emul21:         inc     edi
                call    fetchw
                add     edi,2
                mov     regehl,eax
                xor     eax,eax
                mov     ebp,10+3
                ret

; 22 - LD (dddd),HL
emul22:         inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,regl
                call    writemem
                inc     cx
                mov     al,regh
                call    writemem
                xor     eax,eax
                mov     ebp,16+5
                ret

; 23 - INC HL
INCWREG         23,reghl,6

; 24 - INC H
INCREG          24,regh

; 25 - DEC H
DECREG          25,regh

; 26 - LD H,dd
LDREGIMM        26,regh

; 27 - DAA
OPDAA           27

; 28 - JR Z,dd
JRCC            28,jz,ZERO_FLAG

; 29 - ADD HL,HL
ADDREGWREGW     29,regl,regh,regl,regh,11

; 2A - LD HL,(dddd)
emul2A:         inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     regl,al
                inc     cx
                call    readmem
                mov     regh,al
                xor     eax,eax
                add     edi,2
                mov     ebp,16+5
                ret

; 2B - DEC HL
DECWREG         2B,reghl,6

; 2C - INC L
INCREG          2C,regl

; 2D - DEC L
DECREG          2D,regl

; 2E - LD L,dd
LDREGIMM        2E,regl

; 2F - CPL
emul2F:         inc     edi
                xor     dh,255
                setflag_cpl
                mov     ebp,4+1
                ret

; 30 - JR NC,dd
JRCC            30,jnz,CARRY_FLAG

; 31 - LD SP,dddd
emul31:         inc     edi
                call    fetchw
                add     edi,2
                mov     regesp,eax
                xor     eax,eax
                mov     ebp,10+3
                ret

; 32 - LD (dddd),A
emul32:         inc     edi
                call    fetchw
                mov     ecx,eax
                mov     al,dh
                call    writemem
                add     edi,2
                xor     eax,eax
                mov     ebp,13+4
                ret

; 33 - INC SP
INCWREG         33,regsp,6

; 34 - INC (HL)
INCHL           34

; 35 - DEC (HL)
DECHL           35

; 36 - LD (HL),dd
LDHLIMM         36

; 37 - SCF
emul37:         inc     edi
                or      dl,1
                and     dl,11101101b
                mov     ebp,4+1
                ret

; 38 - JR C,dd
JRCC            38,jz,CARRY_FLAG

; 39 - ADD HL,SP
ADDREGWREGW     39,regl,regh,regspl,regsph,11

; 3A - LD A,(dddd)
emul3A:         inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     dh,al
                xor     eax,eax
                add     edi,2
                mov     ebp,13+4
                ret

; 3B - DEC SP
DECWREG         3B,regsp,6

; 3C - INC A
INCREG          3C,dh

; 3D - DEC A
DECREG          3D,dh

; 3E - LD A,dd
LDREGIMM        3E,dh

; 3F - CCF
emul3F:         inc     edi
                xor     dl,1
                and     dl,11101101b
                mov     ebp,4+1
                ret

; 40 - LD B,B
LDREGREG        40,regb,regb

; 41 - LD B,C
LDREGREG        41,regb,regc

; 42 - LD B,D
LDREGREG        42,regb,regd

; 43 - LD B,E
LDREGREG        43,regb,rege

; 44 - LD B,H
LDREGREG        44,regb,regh

; 45 - LD B,L
LDREGREG        45,regb,regl

; 46 - LD B,(HL)
LDREGHL         46,regb

; 47 - LD B,A
LDREGA          47,regb

; 48 - LD C,B
LDREGREG        48,regc,regb

; 49 - LD C,C
LDREGREG        49,regc,regc

; 4A - LD C,D
LDREGREG        4A,regc,regd

; 4B - LD C,E
LDREGREG        4B,regc,rege

; 4C - LD C,H
LDREGREG        4C,regc,regh

; 4D - LD C,L
LDREGREG        4D,regc,regl

; 4E - LD C,(HL)
LDREGHL         4E,regc

; 4F - LD C,A
LDREGA          4F,regc

; 50 - LD D,B
LDREGREG        50,regd,regb

; 51 - LD D,C
LDREGREG        51,regd,regc

; 52 - LD D,D
LDREGREG        52,regd,regd

; 53 - LD D,E
LDREGREG        53,regd,rege

; 54 - LD D,H
LDREGREG        54,regd,regh

; 55 - LD D,L
LDREGREG        55,regd,regl

; 56 - LD D,(HL)
LDREGHL         56,regd

; 57 - LD D,A
LDREGA          57,regd

; 58 - LD E,B
LDREGREG        58,rege,regb

; 59 - LD E,C
LDREGREG        59,rege,regc

; 5A - LD E,D
LDREGREG        5A,rege,regd

; 5B - LD E,E
LDREGREG        5B,rege,rege

; 5C - LD E,H
LDREGREG        5C,rege,regh

; 5D - LD E,L
LDREGREG        5D,rege,regl

; 5E - LD E,(HL)
LDREGHL         5E,rege

; 5F - LD E,A
LDREGA          5F,rege

; 60 - LD H,B
LDREGREG        60,regh,regb

; 61 - LD H,C
LDREGREG        61,regh,regc

; 62 - LD H,D
LDREGREG        62,regh,regd

; 63 - LD H,E
LDREGREG        63,regh,rege

; 64 - LD H,H
LDREGREG        64,regh,regh

; 65 - LD H,L
LDREGREG        65,regh,regl

; 66 - LD H,(HL)
LDREGHL         66,regh

; 67 - LD H,A
LDREGA          67,regh

; 68 - LD L,B
LDREGREG        68,regl,regb

; 69 - LD L,C
LDREGREG        69,regl,regc

; 6A - LD L,D
LDREGREG        6A,regl,regd

; 6B - LD L,E
LDREGREG        6B,regl,rege

; 6C - LD L,H
LDREGREG        6C,regl,regh

; 6D - LD L,L
LDREGREG        6D,regl,regl

; 6E - LD L,(HL)
LDREGHL         6E,regl

; 6F - LD L,A
LDREGA          6F,regl

; 70 - LD (HL),B
LDHLREG         70,regb

; 71 - LD (HL),C
LDHLREG         71,regc

; 72 - LD (HL),D
LDHLREG         72,regd

; 73 - LD (HL),E
LDHLREG         73,rege

; 74 - LD (HL),H
LDHLREG         74,regh

; 75 - LD (HL),L
LDHLREG         75,regl

; 76 - HALT
emul76:         inc     edi
emul76a:        cmp     interrupt,1
                jne     emul76a
                mov     ebp,5
                ret

; 77 - LD (HL),A
LDHLREG         77,dh

; 78 - LD A,B
LDAREG          78,regb

; 79 - LD A,C
LDAREG          79,regc

; 7A - LD A,D
LDAREG          7A,regd

; 7B - LD A,E
LDAREG          7B,rege

; 7C - LD A,H
LDAREG          7C,regh

; 7D - LD A,L
LDAREG          7D,regl

; 7E - LD A,(HL)
LDREGHL         7E,dh

; 7F - LD A,A
LDAREG          7F,dh

; 80 - ADD A,B  
ADDREG          80,regb

; 81 - ADD A,C
ADDREG          81,regc

; 82 - ADD A,D
ADDREG          82,regd

; 83 - ADD A,E
ADDREG          83,rege

; 84 - ADD A,H
ADDREG          84,regh

; 85 - ADD A,L
ADDREG          85,regl

; 86 - ADD A,(HL)
ADDAHL          86

; 87 - ADD A,A
ADDREG          87,dh

; 88 - ADC A,B
ADCREG          88,regb

; 89 - ADC A,C
ADCREG          89,regc

; 8A - ADC A,D
ADCREG          8A,regd

; 8B - ADC A,E
ADCREG          8B,rege

; 8C - ADC A,H
ADCREG          8C,regh

; 8D - ADC A,L
ADCREG          8D,regl

; 8E - ADC A,(HL)
ADCAHL          8E

; 8F - ADC A,A
ADCREG          8F,dh

; 90 - SUB B
SUBREG          90,regb

; 91 - SUB C
SUBREG          91,regc

; 92 - SUB D
SUBREG          92,regd

; 93 - SUB E
SUBREG          93,rege

; 94 - SUB H
SUBREG          94,regh

; 95 - SUB L
SUBREG          95,regl

; 96 - SUB (HL)
SUBAHL          96

; 97 - SUB A
SUBREG          97,dh

; 98 - SBC A,B
SBCREG          98,regb

; 99 - SBC A,C
SBCREG          99,regc

; 9A - SBC A,D
SBCREG          9A,regd

; 9B - SBC A,E
SBCREG          9B,rege

; 9C - SBC A,H
SBCREG          9C,regh

; 9D - SBC A,L
SBCREG          9D,regl

; 9E - SBC A,(HL)
SBCAHL          9E

; 9F - SBC A,A
SBCREG          9F,dh

; A0 - AND B
ANDREG          A0,regb

; A1 - AND C
ANDREG          A1,regc

; A2 - AND D
ANDREG          A2,regd

; A3 - AND E
ANDREG          A3,rege

; A4 - AND H
ANDREG          A4,regh

; A5 - AND L
ANDREG          A5,regl

; A6 - AND (HL)
ANDHL           A6

; A7 - AND A
ANDREG          A7,dh

; A8 - XOR B
XORREG          A8,regb

; A9 - XOR C
XORREG          A9,regc

; AA - XOR D
XORREG          AA,regd

; AB - XOR E
XORREG          AB,rege

; AC - XOR H
XORREG          AC,regh

; AD - XOR L
XORREG          AD,regl

; AE - XOR (HL)
XORHL           AE

; AF - XOR A
XORREG          AF,dh
                
; B0 - OR B
ORREG           B0,regb

; B1 - OR C
ORREG           B1,regc

; B2 - OR D
ORREG           B2,regd

; B3 - OR E
ORREG           B3,rege

; B4 - OR H
ORREG           B4,regh

; B5 - OR L
ORREG           B5,regl

; B6 - OR (HL)
ORHL            B6

; B7 - OR A
ORREG           B7,dh

; B8 - CP B
CPREG           B8,regb

; B9 - CP C
CPREG           B9,regc

; BA - CP D
CPREG           BA,regd

; BB - CP E
CPREG           BB,rege

; BC - CP H
CPREG           BC,regh

; BD - CP L
CPREG           BD,regl

; BE - CP (HL)
CPAHL           BE

; BF - CP A
CPREG           BF,dh

; C0 - RET NZ
emulC0:         inc     edi
                test    dl,ZERO_FLAG
                jz      emulC9
                mov     ebp,5+1
                ret

; C1 - POP BC
emulC1:         inc     edi
                mov     ecx,regesp
                call    readmem
                mov     regc,al
                inc     cx
                call    readmem
                mov     regb,al
                inc     cx
                mov     regesp,ecx
                mov     ebp,10+3
                ret

; C2 - JP NZ,dddd
JPCC            C2,jnz,ZERO_FLAG

; C3 - JP dddd
emulC3:         inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                mov     ebp,10+3
                ret

; C4 - CALL NZ,dddd
emulC4:         test    dl,ZERO_FLAG    
                jz      emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; C5 - PUSH BC
emulC5:         inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,regb
                call    writemem
                dec     cx
                mov     al,regc
                call    writemem
                mov     regesp,ecx
                mov     ebp,11+3
                ret

; C6 - ADD A,dd
ADDIMM         C6

; C8 - RET Z
emulC8:         inc     edi
                test    dl,ZERO_FLAG
                jnz     emulC9
                mov     ebp,5+1
                ret

; C9 - RET
emulC9:         mov     ecx,regesp
                call    readmem
                mov     edi,eax
                and     edi,0ffh
                inc     cx
                call    readmem
                inc     cx
                mov     regesp,ecx
                mov     ah,al
                and     eax,0ff00h
                or      edi,eax
                xor     eax,eax
                mov     ebp,10+3
                ret

; CA - JP Z,dddd
JPCC            CA,jz,ZERO_FLAG

; CB - group CB
emulCB:         inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetCBxx+eax*4]

; CC - CALL Z,dddd
emulCC:         test    dl,ZERO_FLAG    
                jnz     emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; CD - CALL dddd
emulCD:         add     edi,3
                mov     ecx,regesp
                mov     eax,edi
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                sub     edi,2
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                mov     ebp,17+5
                ret

; CE - ADC A,dd
ADCIMM          CE

; CF - RST 08
emulCF:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,008h
                xor     eax,eax
                mov     ebp,11+3
                ret

; D0 - RET NC
emulD0:         inc     edi
                test    dl,CARRY_FLAG
                jz      emulC9
                mov     ebp,5+1
                ret

; D1 - POP DE
emulD1:         inc     edi
                mov     ecx,regesp
                call    readmem
                mov     rege,al
                inc     cx
                call    readmem
                mov     regd,al
                inc     cx
                mov     regesp,ecx
                mov     ebp,10+3
                ret

; D2 - JP NC,dddd
JPCC            D2,jnz,CARRY_FLAG

; D3 - OUT (dd),A
OUTIMM          D3

; D4 - CALL NC,dddd
emulD4:         test    dl,CARRY_FLAG
                jz      emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; D5 - PUSH DE
emulD5:         inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,regd
                call    writemem
                dec     cx
                mov     al,rege
                call    writemem
                mov     regesp,ecx
                mov     ebp,11+3
                ret

; D6 - SUB dd
SUBIMM          D6

; D7 - RST 10
emulD7:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,010h
                xor     eax,eax
                mov     ebp,7+3
                ret

; D8 - RET C
emulD8:         inc     edi
                test    dl,CARRY_FLAG   
                jnz     emulC9
                mov     ebp,5+1
                ret

; D9 - EXX
emulD9:         inc     edi
                mov     ebx,regebc
                mov     ecx,regebcl
                mov     regebc,ecx
                mov     regebcl,ebx
                mov     ebx,regede
                mov     ecx,regedel
                mov     regede,ecx
                mov     regedel,ebx
                mov     ebx,regehl
                mov     ecx,regehll
                mov     regehl,ecx
                mov     regehll,ebx
                mov     ebp,4+1
                ret

; DA - JP C,dddd
JPCC            DA,jz,CARRY_FLAG

; DB - IN A,(dd)
INADD           DB

; DC - CALL C,dddd 
emulDC:         test    dl,CARRY_FLAG
                jnz     emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; DD - group DD
emulDD:         inc     edi
                inc     rcounter
                call    fetch
                and     eax,0ffh
                jmp     [offset isetDDxx+eax*4]

; DE - SBC A,dd
SBCIMM          DE

; DF - RST 18
emulDF:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,018h
                xor     eax,eax
                mov     ebp,7+3
                ret

; E0 - RET PO
emulE0:         test    dl,PARITY_FLAG
                jz      emulC9
                inc     edi
                mov     ebp,5+1
                ret

; E1 - POP HL
emulE1:         inc     edi
                mov     ecx,regesp
                call    readmem
                mov     regl,al
                inc     cx
                call    readmem
                mov     regh,al
                inc     cx
                mov     regesp,ecx
                mov     ebp,10+3
                ret

; E2 - JP PO,dddd
JPCC            E2,jnz,PARITY_FLAG

; E3 - EX (SP),HL
emulE3:         inc     edi
                mov     ecx,regesp
                call    readmem
                mov     bl,regl
                mov     regl,al
                mov     al,bl
                call    writemem
                inc     cx
                call    readmem
                mov     bl,regh
                mov     regh,al
                mov     al,bl
                call    writemem
                mov     ebp,19+3
                ret

; E4 - CALL PO,dddd
emulE4:         test    dl,PARITY_FLAG
                jz      emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; E5 - PUSH HL
emulE5:         inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,regh
                call    writemem
                dec     cx
                mov     al,regl
                call    writemem
                mov     regesp,ecx
                mov     ebp,11+3
                ret

; E6 - AND dd
ANDIMM          E6

; E7 - RST 20
emulE7:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,020h
                xor     eax,eax
                mov     ebp,7+3
                ret

; E8 - RET PE
emulE8:         test    dl,PARITY_FLAG
                jnz     emulC9
                inc     edi
                mov     ebp,5+1
                ret

; E9 - JP (HL)
emulE9:         mov     edi,regehl
                mov     ebp,4+1
                ret

; EA - JP PE,dddd
JPCC            EA,jz,PARITY_FLAG

; EB - EX DE,HL
emulEB:         mov     ebx,regede
                mov     ecx,regehl
                mov     regehl,ebx
                mov     regede,ecx
                inc     edi
                mov     ebp,4+1
                ret

; EC - CALL PE,dddd
emulEC:         test    dl,PARITY_FLAG
                jnz     emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; ED - group ED
emulED:         inc     edi
                inc     rcounter
                call    fetch
                and     eax,0ffh
                jmp     [offset isetEDxx+eax*4]

; EE - XOR dd
XORIMM          EE

; EF - RST 28
emulEF:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,028h
                xor     eax,eax
                mov     ebp,7+3
                ret

; F0 - RET P
emulF0:         inc     edi
                test    dl,SIGN_FLAG
                jz      emulC9  
                mov     ebp,5+1
                ret

; F1 - POP AF
emulF1:         inc     edi
                mov     ecx,regesp
                call    readmem
                mov     dl,al
                inc     cx
                call    readmem
                mov     dh,al
                inc     cx
                mov     regesp,ecx
                mov     ebp,10+3
                ret

; F2 - JP P,dddd
JPCC            F2,jnz,SIGN_FLAG

; F3 - DI
emulF3:         inc     edi
                mov     iff1,0
                mov     ebp,4+1
                ret

; F4 - CALL P,dddd
emulF4:         test    dl,SIGN_FLAG
                jz      emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; F5 - PUSH AF
emulF5:         inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,dh
                call    writemem
                dec     cx
                mov     al,dl
                call    writemem
                mov     regesp,ecx
                mov     ebp,11+3
                ret

; F6 - OR dd
ORIMM           F6

; F7 - RST 30
emulF7:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,030h
                xor     eax,eax
                mov     ebp,7+3
                ret
; F8 - RET M
emulF8:         inc     edi
                test    dl,SIGN_FLAG
                jnz     emulC9
                mov     ebp,5+1
                ret

; F9 - LD SP,HL
emulF9:         inc     edi
                mov     ebx,regehl
                mov     regesp,ebx
                mov     ebp,6+1
                ret

; FA - JP M,dddd
JPCC            FA,jz,SIGN_FLAG

; FB - EI
emulFB:         inc     edi
                mov     iff1,1
                mov     ebp,4+1
                ret

; FC - CALL M,dddd
emulFC:         test    dl,SIGN_FLAG
                jnz     emulCD
                add     edi,3
                mov     ebp,10+3
                ret

; FD - group FD
emulFD:         inc     edi
                inc     rcounter
                call    fetch
                and     eax,0ffh
                jmp     [offset isetFDxx+eax*4]

; FE - CP dd
CPIMM           FE

; FF - RST 38
emulFF:         inc     edi
                mov     eax,edi
                mov     ecx,regesp
                dec     cx
                mov     al,ah
                call    writemem
                mov     eax,edi
                dec     cx
                call    writemem
                mov     regesp,ecx
                mov     edi,038h
                xor     eax,eax
                mov     ebp,7+3
                ret

; XX - not found
emulXX:         mov     error,1
                mov     interrupt,1
                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

outemul98:      mov     ecx,msxvram
                mov     esi,vdpaddresse
                mov     [ecx+esi],bl
                inc     vdpaddress
                cmp     imagetype,0
                je      _ret
                cmp     lastscreen,0
                jne     _ret
                ; screen 1
                sub     esi,nametable
                js      _ret
                cmp     esi,32*24
                jge     _ret
                add     esi,dirtyname
                mov     byte ptr [esi],1
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
                mov     byte ptr [offset vdpregs+ebx],al
                cmp     ebx,7
                je      set_border_color
                ret

outemulA0:      mov     psgselect,bl
                ret

outemulA1:      mov     al,psgselect        
                mov     [offset psgreg+eax],bl
                ret

outemulA8:      mov     prim_slotreg,bl
                ; frame 0
                and     ebx,03h
                shl     ebx,6
                mov     ecx,[offset slot+ebx]
                mov     mem00,ecx
                mov     ecx,[offset slot+ebx+8]
                mov     mem20,ecx
                mov     ecx,[offset slot+ebx+4]
                mov     memlock00,ecx
                mov     ecx,[offset slot+ebx+4+8]
                mov     memlock20,ecx
                ; frame 1
                mov     bl,prim_slotreg
                shr     bl,2
                and     ebx,03h
                shl     ebx,6
                mov     ecx,[offset slot+ebx+16]
                mov     mem40,ecx
                mov     ecx,[offset slot+ebx+16+8]
                mov     mem60,ecx
                mov     ecx,[offset slot+ebx+16+4]
                mov     memlock40,ecx
                mov     ecx,[offset slot+ebx+16+4+8]
                mov     memlock60,ecx
                ; frame 2
                mov     bl,prim_slotreg
                shr     bl,4
                and     ebx,03h
                shl     ebx,6
                mov     ecx,[offset slot+ebx+32]
                mov     mem80,ecx
                mov     ecx,[offset slot+ebx+32+8]
                mov     memA0,ecx
                mov     ecx,[offset slot+ebx+32+4]
                mov     memlock80,ecx
                mov     ecx,[offset slot+ebx+32+4+8]
                mov     memlockA0,ecx
                ; frame 3
                mov     bl,prim_slotreg
                shr     bl,6
                and     ebx,03h
                shl     ebx,6
                mov     ecx,[offset slot+ebx+48]
                mov     memC0,ecx
                mov     ecx,[offset slot+ebx+48+8]
                mov     memE0,ecx
                mov     ecx,[offset slot+ebx+48+4]
                mov     memlockC0,ecx
                mov     ecx,[offset slot+ebx+48+4+8]
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
inemulA2a:      mov     bl,00111111b
                ret

inemulA8:       mov     bl,prim_slotreg
                ret

inemulA9:       movzx   ecx,keyboard_line
                mov     bl,byte ptr [offset keymatrix+ecx]
                ret

; --------------------------------------------------------------------

code32          ends
                end




