; BrMSX 1.0       
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom: near
extrn msxvram: near
extrn cart1: dword
extrn pset: near
extrn isetCBxx: near
extrn isetDDxx: near
extrn isetEDxx: near
extrn emulEDFF: near

include io.inc
include debug.inc
include bit.inc
include opcode.inc
include z80supp.inc
include pmode.inc

public fetch
public fetchw
public readmem
public writemem
public trace
public print
public emulate
public emulate_break
public emulate_echo
public emulXX
public emulC9
public outemulXX
public inemulXX
public outportxx
public inportxx
public opsubreg

public breakpoint
public iff1
public interrupt
public vdpstatus
public keymatrix
public rcounter
public rmask
public regi

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
public regeaf
public regebc
public regede
public regehl
public regesp
public regeix
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

; DATA ---------------------------------------------------------------

align 4

include iset.inc
include isetFD.inc

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
slot1:
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
slot3:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1

; Z80 registers
align 4

breakpoint      dd      0
iff1            dd      0
interrupt       dd      0
error           dd      0
rcounter        dd      0        
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

; setflag_outi -------------------------------------------------------
; sets the z80 flags after outi operations

setflag_outi    macro

                pushfd
                pop     ecx
                and     dl,10111111b
                and     cl,01000010b ;check
                or      dl,cl

                endm

; setflag_ldi --------------------------------------------------------
; sets the z80 flags after ldi operations

setflag_ldi     macro

                pushfd
                pop     ecx
                and     dl,11101001b
                and     cl,01000000b 
                shr     cl,4
                or      dl,cl

                endm

; setflag_in_c -------------------------------------------------------
; sets the z80 flags after in r,(C) operations

setflag_in_c    macro

                pushfd
                pop     ecx
                and     dl,00000001b
                and     cl,11111100b
                or      dl,cl

                endm

; setflag_xor --------------------------------------------------------
; sets the z80 flags after xor operations

setflag_xor     macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000100b

                endm

; setflag_or ---------------------------------------------------------
; sets the z80 flags after or operations

setflag_or      macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000100b

                endm

; setflag_and --------------------------------------------------------
; sets the z80 flags after and operations

setflag_and     macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000100b
                or      dl,00010000b

                endm

; setflag_bit --------------------------------------------------------
; sets the z80 flags after bit operations

setflag_bit     macro

                pushfd
                pop     ecx
                and     dl,10111101b
                and     cl,01000000b
                or      dl,cl
                or      dl,00010000b

                endm

; setflag_shift ------------------------------------------------------
; sets the z80 flags after shift operations

setflag_shift   macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000101b

                endm

; setflag_rlc --------------------------------------------------------
; sets the z80 flags after rlc operations

setflag_rlc     macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000101b

                endm

; setflag_rr ---------------------------------------------------------
; sets the z80 flags after rr operations

setflag_rr      macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000101b

                endm

; setflag_rrd --------------------------------------------------------
; sets the z80 flags after rrd operations

setflag_rrd      macro

                pushfd
                pop     ecx
                and     cl,01111111b
                and     dl,10000000b
                or      dl,cl

                endm

; setflag_rld --------------------------------------------------------
; sets the z80 flags after rld operations

setflag_rld      macro

                pushfd
                pop     ecx
                and     cl,01111111b
                and     dl,10000000b
                or      dl,cl

                endm

; setflag_rl ---------------------------------------------------------
; sets the z80 flags after rl operations

setflag_rl      macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000101b

                endm

; setflag_sub --------------------------------------------------------
; sets the z80 flags after sub operations

setflag_sub     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                
                endm

; setflag_add --------------------------------------------------------
; sets the z80 flags after add operations

setflag_add     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                
                endm

; setflag_adc --------------------------------------------------------
; sets the z80 flags after adc operations

setflag_adc     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                
                endm

; setflag_add2 -------------------------------------------------------
; sets the z80 flags after add2 operations

setflag_add2    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11111100b
                or      dl,cl
                
                endm

; setflag_rlca -------------------------------------------------------
; sets the z80 flags after rlca operations

setflag_rlca    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11101100b
                or      dl,cl
                
                endm

; setflag_rla --------------------------------------------------------
; sets the z80 flags after rla operations

setflag_rla    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11101100b
                or      dl,cl
                
                endm

; setflag_rrca -------------------------------------------------------
; sets the z80 flags after rrca operations

setflag_rrca    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11101100b
                or      dl,cl
                
                endm

; setflag_rra --------------------------------------------------------
; sets the z80 flags after rra operations

setflag_rra     macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11101100b
                or      dl,cl
                
                endm

; setflag_inc --------------------------------------------------------
; sets the z80 flags after inc operations

setflag_inc     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000000b
                and     dl,1
                shr     ch,1
                or      dl,cl
                or      dl,ch
                
                endm

; setflag_cpl --------------------------------------------------------
; sets the z80 flags after cpl operations

setflag_cpl     macro

                or      dl,00010010b
                
                endm

; setflag_cp ---------------------------------------------------------
; sets the z80 flags after cp operations

setflag_cp      macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                or      dl,00000010b
                
                endm

; setflag_dec --------------------------------------------------------
; sets the z80 flags after dec operations

setflag_dec     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000000b
                and     dl,1
                shr     ch,1
                or      dl,cl
                or      dl,ch
                or      dl,00000010b
                
                endm

; setflag_sbc --------------------------------------------------------
; sets the z80 flags after sbc operations

setflag_sbc     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                or      dl,00000010b                

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
                mov     ebx,eax
                and     ebx,0ffh
                shl     ebx,13
                add     ebx,cart1
                mov     dword ptr [offset mem+esi*4],ebx
                ret


; trace --------------------------------------------------------------
; executes only the next instruction
; in: edi = regpc , eax = 0

trace:
                call    fetch
                call    [offset iset + eax*4]
                mov     regpc,di
                mov     regaf,dx
                ret

; emulate ------------------------------------------------------------
; starts emulation, stop with any error

emulate:
                mov     eax,0
                mov     ecx,0
                mov     error,0
                mov     exit_now,0
                mov     interrupt,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_loop:
                and     edi,0ffffh
                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]
                cmp     interrupt,1
                je      emulate_interrupt
                cmp     error,1
                jne     emulate_loop
emulate_exit:
                mov     regpc,di
                mov     regaf,dx
                ret
emulate_interrupt:
                cmp     exit_now,1
                je      emulate_exit
                cmp     iff1,1
                jne     emulate_loop
                mov     iff1,0 
                and     edi,0ffffh
                dec     edi
                mov     interrupt,0
                call    emulFF
                jmp     emulate_loop

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:
                mov     eax,0
                mov     ecx,0
                mov     error,0
                mov     exit_now,0
                mov     interrupt,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_break_loop:
                and     edi,0ffffh
                cmp     edi,breakpoint
                je      emulate_break_exit
                call    fetch
                call    [offset iset + eax*4]
                cmp     interrupt,1
                je      emulate_break_interrupt
                cmp     error,1
                jne     emulate_break_loop
emulate_break_exit:
                mov     regpc,di
                mov     regaf,dx
                ret
emulate_break_interrupt:
                cmp     exit_now,1
                je      emulate_break_exit
                cmp     iff1,1
                jne     emulate_break_loop
                and     edi,0ffffh
                dec     edi
                mov     interrupt,0
                call    emulFF
                jmp     emulate_break_loop

; emulate_echo -------------------------------------------------------
; starts emulation with echo, stop with any error

emulate_echo:
                call    crlf
                mov     eax,0
                mov     error,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_echo_loop:
                pushad
                mov     regpc,di
                mov     regaf,dx
                call    showreg
                popad
                and     edi,0ffffh
                cmp     edi,breakpoint
                je      emulate_echo_end
                call    fetch
                call    [offset iset + eax*4]
                cmp     error,1
                jne     emulate_echo_loop
emulate_echo_end:
                mov     regpc,di
                mov     regaf,dx
                ret

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
                ret

; 01 - LD BC,dddd
emul01:         inc     edi
                call    fetchw
                mov     regebc,eax
                add     edi,2
                xor     eax,eax
                ret

; 02 - LD (BC),A
emul02:         inc     edi
                mov     ecx,regebc
                mov     al,dh
                call    writemem
                ret


; 03 - INC BC
INCWREG         03,regbc,6

; 04 - INC B
INCREG          04,regb

; 05 - DEC B
DECREG          05,regb

; 06 - LD B,dd
emul06:         inc     edi
                call    fetch
                inc     edi
                mov     regb,al
                ret

; 07 - RLCA
OPRLCA          07

; 08 - EX AF,AF'
emul08:         inc     edi
                mov     ebx,edx
                mov     ecx,regeafl
                mov     edx,ecx
                mov     regeafl,ebx
                ret

; 09 - ADD HL,BC
ADDHLWREG       09,regc,regb

; 0A - LD A,(BC)
emul0A:         inc     edi
                mov     ecx,regebc
                call    readmem
                mov     dh,al
                ret

; 0B - DEC BC
DECWREG         0B,regbc,6

; 0C - INC C
INCREG          0C,regc

; 0D - DEC C
DECREG          0D,regc

; 0E - LD C,dd
emul0E:         inc     edi
                call    fetch
                inc     edi
                mov     regc,al
                ret

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
emul10a:        ret

; 11 - LD DE,dddd
emul11:         inc     edi
                call    fetchw
                add     edi,2
                mov     regede,eax
                xor     eax,eax
                ret

; 12 - LD (DE),A
emul12:         inc     edi
                mov     ecx,regede
                mov     al,dh
                call    writemem
                ret

; 13 - INC DE
INCWREG         13,regde,6

; 14 - INC D
INCREG          14,regd

; 15 - DEC D
DECREG          15,regd

; 16 - LD D,dd
emul16:         inc     edi
                call    fetch
                inc     edi
                mov     regd,al
                ret

; 17 - RLA
OPRLA           17

; 18 - JR dd
emul18:         inc     edi
                call    fetch
                inc     edi
                movsx   ebx,al
                add     edi,ebx
                ret

; 19 - ADD HL,DE
ADDHLWREG       19,rege,regd

; 1A - LD A,(DE)
emul1A:         inc     edi
                mov     ecx,regede
                call    readmem
                mov     dh,al
                ret

; 1B - DEC DE
DECWREG         1B,regde,6

; 1C - INC E
INCREG          1C,rege

; 1D - DEC E
DECREG          1D,rege

; 1E - LD E,dd
emul1E:         inc     edi
                call    fetch
                inc     edi
                mov     rege,al
                ret

; 1F - RRA
OPRRA           1F

; 20 - JR NZ,dd
emul20:         inc     edi
                call    fetch
                inc     edi
                test    dl,ZERO_FLAG
                jnz     emul20a         ; remember ZERO_FLAG=1 => result is 0
                movsx   ebx,al
                add     edi,ebx
emul20a:        ret

; 21 - LD HL,dddd
emul21:         inc     edi
                call    fetchw
                add     edi,2
                mov     regehl,eax
                xor     eax,eax
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
                ret

; 23 - INC HL
INCWREG         23,reghl,6

; 24 - INC H
INCREG          24,regh

; 25 - DEC H
DECREG          25,regh

; 26 - LD H,dd
emul26:         inc     edi
                call    fetch
                inc     edi
                mov     regh,al
                ret

; 27 - DAA
OPDAA           27

; 28 - JR Z,dd
emul28:         inc     edi
                call    fetch
                inc     edi
                test    dl,ZERO_FLAG    
                jz      emul28a
                movsx   ebx,al
                add     edi,ebx
emul28a:        ret

; 29 - ADD HL,HL
ADDHLWREG       29,regl,regh

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
                ret

; 2B - DEC HL
DECWREG         2B,reghl,6

; 2C - INC L
INCREG          2C,regl

; 2D - DEC L
DECREG          2D,regl

; 2E - LD L,dd
emul2E:         inc     edi
                call    fetch
                inc     edi
                mov     regl,al
                ret

; 2F - CPL
emul2F:         inc     edi
                xor     dh,255
                setflag_cpl
                ret

; 30 - JR NC,dd
emul30:         inc     edi
                call    fetch
                inc     edi
                test    dl,CARRY_FLAG
                jnz     emul30a
                movsx   ebx,al
                add     edi,ebx
emul30a:        ret

; 31 - LD SP,dddd
emul31:         inc     edi
                call    fetchw
                add     edi,2
                mov     regesp,eax
                xor     eax,eax
                ret

; 32 - LD (dddd),A
emul32:         inc     edi
                call    fetchw
                mov     ecx,eax
                mov     al,dh
                call    writemem
                add     edi,2
                xor     eax,eax
                ret

; 33 - INC SP
INCWREG         33,regsp,6

; 34 - INC (HL)
INCHL           34

; 35 - DEC (HL)
DECHL           35

; 36 - LD (HL),dd
emul36:         inc     edi
                call    fetch
                mov     ecx,regehl        
                call    writemem
                inc     edi
                ret

; 37 - SCF
emul37:         inc     edi
                or      dl,1
                and     dl,11101101b
                ret

; 38 - JR C,dd
emul38:         inc     edi
                call    fetch
                inc     edi
                test    dl,CARRY_FLAG
                jz      emul38a
                movsx   ebx,al
                add     edi,ebx
emul38a:        ret



; 39 - ADD HL,SP
ADDHLWREG       39,regspl,regsph

; 3A - LD A,(dddd)
emul3A:         inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     dh,al
                xor     eax,eax
                add     edi,2
                ret

; 3B - DEC SP
DECWREG         3B,regsp,6

; 3C - INC A
INCREG          3C,dh

; 3D - DEC A
DECREG          3D,dh

; 3E - LD A,dd
emul3E:         inc     edi
                call    fetch
                inc     edi
                mov     dh,al
                ret

; 3F - CCF
emul3F:         inc     edi
                xor     dl,1
                and     dl,11101101b
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
emulB8:         inc     edi
                cmp     dh,regb
                setflag_cp
                ret

; B9 - CP C
emulB9:         inc     edi
                cmp     dh,regc
                setflag_cp
                ret

; BA - CP D
emulBA:         inc     edi
                cmp     dh,regd
                setflag_cp
                ret

; BB - CP E
emulBB:         inc     edi
                cmp     dh,rege
                setflag_cp
                ret

; BC - CP H
emulBC:         inc     edi
                cmp     dh,regh
                setflag_cp
                ret

; BD - CP L
emulBD:         inc     edi
                cmp     dh,regl
                setflag_cp
                ret

; BE - CP (HL)
emulBE:         inc     edi
                mov     ecx,regehl
                call    readmem
                cmp     dh,al
                setflag_cp
                ret

; BF - CP A
emulBF:         inc     edi
                cmp     dh,dh
                setflag_cp
                ret

; C0 - RET NZ
emulC0:         inc     edi
                test    dl,ZERO_FLAG
                jz      emulC9
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
                ret

; C2 - JP NZ,dddd
emulC2:         test    dl,ZERO_FLAG
                jnz     emulC2a
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulC2a:        add     edi,3
                ret

; C3 - JP
emulC3:         inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret

; C4 - CALL NZ,dddd
emulC4:         test    dl,ZERO_FLAG    
                jz      emulCD
                add     edi,3
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
                ret

; C6 - ADD A,dd
ADDIMM         C6

; C8 - RET Z
emulC8:         inc     edi
                test    dl,ZERO_FLAG
                jnz     emulC9
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
                ret

; CA - JP Z,dddd
emulCA:         test    dl,ZERO_FLAG
                jz      emulCAa
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulCAa:        add     edi,3
                ret

; CB - group CB
emulCB:         inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetCBxx+eax*4]

; CC - CALL Z,dddd
emulCC:         test    dl,ZERO_FLAG    
                jnz     emulCD
                add     edi,3
                ret

; CD - CALL dddd
emulCD:         add     edi,3
                mov     eax,edi
                mov     ecx,regesp
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
                ret

; D0 - RET NC
emulD0:         inc     edi
                test    dl,CARRY_FLAG
                jz      emulC9
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
                ret

; D2 - JP NC,dddd
emulD2:         test    dl,CARRY_FLAG
                jnz     emulD2a
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulD2a:        add     edi,3
                ret


; D3 - OUT (dd),A
emulD3:         inc     edi
                call    fetch
                inc     edi
                mov     bl,dh
                jmp     [offset outportxx+eax*4]

; D4 - CALL NC,dddd
emulD4:         test    dl,CARRY_FLAG
                jz      emulCD
                add     edi,3
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
                ret

; D8 - RET C
emulD8:         inc     edi
                test    dl,CARRY_FLAG   
                jnz     emulC9
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
                ret

; DA - JP C,dddd
emulDA:         test    dl,CARRY_FLAG
                jz      emulDAa
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulDAa:        add     edi,3
                ret

; DB - IN A,(dd)
emulDB:         inc     edi
                call    fetch
                inc     edi
                call    [offset inportxx+eax*4]
                mov     dh,bl
                ret

; DC - CALL C,dddd 
emulDC:         test    dl,CARRY_FLAG
                jnz     emulCD
                add     edi,3
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
                ret

; E0 - RET PO
emulE0:         test    dl,PARITY_FLAG
                jz      emulC9
                inc     edi
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
                ret

; E2 - JP PO,dddd
emulE2:         test    dl,PARITY_FLAG
                jnz     emulE2a
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulE2a:        add     edi,3
                ret

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
                ret

; E4 - CALL PO,dddd
emulE4:         test    dl,PARITY_FLAG
                jz      emulCD
                add     edi,3
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
                ret

; E6 - AND dd
emulE6:         inc     edi
                call    fetch
                inc     edi
                and     dh,al
                setflag_and
                ret

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
                ret

; E8 - RET PE
emulE8:         test    dl,PARITY_FLAG
                jnz     emulC9
                inc     edi
                ret

; E9 - JP (HL)
emulE9:         mov     edi,regehl
                ret

; EA - JP PE,dddd
emulEA:         test    dl,PARITY_FLAG
                jz      emulEAa
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulEAa:        add     edi,3
                ret

; EB - EX DE,HL
emulEB:         mov     ebx,regede
                mov     ecx,regehl
                mov     regehl,ebx
                mov     regede,ecx
                inc     edi
                ret

; EC - CALL PE,dddd
emulEC:         test    dl,PARITY_FLAG
                jnz     emulCD
                add     edi,3
                ret

; ED - group ED
emulED:         inc     edi
                inc     rcounter
                call    fetch
                and     eax,0ffh
                jmp     [offset isetEDxx+eax*4]

; EE - XOR dd
emulEE:         inc     edi
                call    fetch
                xor     dh,al
                setflag_xor
                inc     edi
                ret

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
                ret

; F0 - RET P
emulF0:         inc     edi
                test    dl,SIGN_FLAG
                jz      emulC9  
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
                ret

; F2 - JP P,dddd
emulF2:         test    dl,SIGN_FLAG
                jnz     emulF2a 
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulF2a:        add     edi,3
                ret

; F3 - DI
emulF3:         inc     edi
                mov     iff1,0
                ret

; F4 - CALL P,dddd
emulF4:         test    dl,SIGN_FLAG
                jz      emulCD
                add     edi,3
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
                ret

; F6 - OR dd
emulF6:         inc     edi
                call    fetch
                inc     edi
                or      dh,al
                setflag_or
                ret

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
                ret
; F8 - RET M
emulF8:         inc     edi
                test    dl,SIGN_FLAG
                jnz     emulC9
                ret

; F9 - LD SP,HL
emulF9:         inc     edi
                mov     ebx,regehl
                mov     regesp,ebx
                ret

; FA - JP M,dddd
emulFA:         test    dl,SIGN_FLAG
                jz      emulFAa 
                inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret
emulFAa:        add     edi,3
                ret

; FB - EI
emulFB:         inc     edi
                mov     iff1,1
                ret

; FC - CALL M,dddd
emulFC:         test    dl,SIGN_FLAG
                jnz     emulCD
                add     edi,3
                ret

; FD - group FD
emulFD:         inc     edi
                inc     rcounter
                call    fetch
                and     eax,0ffh
                jmp     [offset isetFDxx+eax*4]

; FE - CP dd
emulFE:         inc     edi
                call    fetch
                inc     edi
                cmp     dh,al
                setflag_cp
                ret

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
                ret

; FD 09 - ADD IY,BC
emulFD09:       inc     edi
                mov     ebx,regebc
                add     regiy,bx
                setflag_add2
                ret

; FD 19 - ADD IY,DE
emulFD19:       inc     edi
                mov     ebx,regede
                add     regiy,bx
                setflag_add2
                ret

; FD 21 - LD IY,dddd
emulFD21:       inc     edi
                call    fetchw
                add     edi,2
                mov     regeiy,eax
                xor     eax,eax
                ret

; FD 22 - LD (dddd),IY
emulFD22:       inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,regiyl
                call    writemem
                inc     cx
                mov     al,regiyh
                call    writemem
                xor     eax,eax
                ret

; FD 23 - INC IY
INCWREG         FD23,regiy,10

; FD 29 - ADD IY,IY
emulFD29:       inc     edi
                mov     ecx,regeiy
                add     regiy,cx
                setflag_add2
                ret

; FD 2A - LD IY,(dddd)
emulFD2A:       inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     regiyl,al
                inc     cx
                call    readmem
                mov     regiyh,al
                xor     eax,eax
                add     edi,2
                ret

; FD 2B - DEC IY
DECWREG         FD2B,regiy,10

; FD 34 - INC (IY+dd)
INCII           FD34,regeiy

; FD 35 - DEC (IY+dd)
DECII           FD35,regeiy

; FD 36 - LD (IY+dd),dd
LDIIDDNN        FD36,regeiy

; FD 46 - LD B,(IY+dd)
emulFD46:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     regb,al
                ret

; FD 4E - LD C,(IY+dd)
emulFD4E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     regc,al
                ret

; FD 56 - LD D,(IY+dd)
emulFD56:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     regd,al
                ret

; FD 5E - LD E,(IY+dd)
emulFD5E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     rege,al
                ret

; FD 66 - LD H,(IY+dd)
emulFD66:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     regh,al
                ret

; FD 6E - LD L,(IY+dd)
emulFD6E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     regl,al
                ret

; FD 70 - LD (IY+dd),B
LDIIDDREG       FD70,regb,regeiy

; FD 71 - LD (IY+dd),C
LDIIDDREG       FD71,regc,regeiy

; FD 72 - LD (IY+dd),D
LDIIDDREG       FD72,regd,regeiy

; FD 73 - LD (IY+dd),E
LDIIDDREG       FD73,rege,regeiy

; FD 74 - LD (IY+dd),H
LDIIDDREG       FD74,regh,regeiy

; FD 75 - LD (IY+dd),L
LDIIDDREG       FD75,regl,regeiy

; FD 77 - LD (IY+dd),A
LDIIDDREG       FD77,dh,regeiy

; FD 7E - LD A,(IY+dd)
emulFD7E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                mov     dh,al
                ret

; FD 96 - SUB (IY+dd)
SUBII           FD96,regeiy

; FD AE - XOR (IY+dd)
emulFDAE:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                xor     dh,al
                setflag_xor
                ret

; FD B6 - OR (IY+dd)
ORII            FDB6,regeiy

; FD BE - CP (IY+dd)
emulFDBE:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeiy
                add     cx,bx
                call    readmem
                cmp     dh,al
                setflag_cp
                ret

; FD E1 - POP IY
emulFDE1:       inc     edi
                mov     ecx,regesp
                call    readmem
                mov     regiyl,al
                inc     cx
                call    readmem
                mov     regiyh,al
                inc     cx
                mov     regesp,ecx
                ret

; FD E5 - PUSH IY
emulFDE5:       inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,regiyh
                call    writemem
                dec     cx
                mov     al,regiyl
                call    writemem
                mov     regesp,ecx
                ret

; FD E9 - JP (IY)
emulFDE9:       mov     edi,regeiy
                ret

; XX - not found
emulXX:         mov     error,1
                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

outemul98:      mov     ecx,vdpaddresse
                mov     [offset msxvram+ecx],bl
                inc     vdpaddress
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
                shl     ebx,5
                mov     ecx,[offset slot+ebx]
                mov     mem00,ecx
                add     ecx,2000h
                mov     mem20,ecx
                mov     ecx,[offset slot+ebx+4]
                mov     memlock00,ecx
                mov     memlock20,ecx
                ; frame 1
                mov     bl,prim_slotreg
                shr     bl,2
                and     ebx,03h
                shl     ebx,5
                mov     ecx,[offset slot+ebx+8]
                mov     mem40,ecx
                add     ecx,2000h
                mov     mem60,ecx
                mov     ecx,[offset slot+ebx+8+4]
                mov     memlock40,ecx
                mov     memlock60,ecx
                ; frame 2
                mov     bl,prim_slotreg
                shr     bl,4
                and     ebx,03h
                shl     ebx,5
                mov     ecx,[offset slot+ebx+16]
                mov     mem80,ecx
                add     ecx,2000h
                mov     memA0,ecx
                mov     ecx,[offset slot+ebx+16+4]
                mov     memlock80,ecx
                mov     memlockA0,ecx
                ; frame 3
                mov     bl,prim_slotreg
                shr     bl,6
                and     ebx,03h
                shl     ebx,5
                mov     ecx,[offset slot+ebx+24]
                mov     memC0,ecx
                add     ecx,2000h
                mov     memE0,ecx
                mov     ecx,[offset slot+ebx+24+4]
                mov     memlockC0,ecx
                mov     memlockE0,ecx
                ret

outemulAA:      and     bl,0fh
                mov     keyboard_line,bl
                ret

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       ret

inemul98:       mov     ecx,vdpaddresse
                mov     bl,[offset msxvram+ecx]
                inc     vdpaddress
                ret

inemul99:       mov     bl,vdpstatus
                and     vdpstatus,01111111b
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




