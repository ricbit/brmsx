; BrMSX 1.0       
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom:near
extrn msxvram:near
extrn cart1:near
extrn pset:near

include io.inc
include debug.inc
include bit.inc
include opcode.inc

public fetch
public fetchw
public trace
public print
public emulate
public emulate_break
public emulate_echo

public breakpoint
public iff1
public interrupt
public vdpstatus
public keymatrix

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
public vdpregs

; DATA ---------------------------------------------------------------

align 4

include iset.inc
include isetCB.inc
include isetDD.inc
include isetDDCB.inc
include isetED.inc
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

breakpoint      dd      0
iff1            dd      0
interrupt       dd      0
error           dd      0
rcounter        dd      0        
rmask           db      0

align 4

vdpcond         dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      8 dup (0)
vdptemp         db      0
vdpstatus       db      0

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
                mov     ebx,[offset mem+esi*4]          ; clock 4 U
                inc     esi                             ; clock 4 V
                mov     al,byte ptr [ebx+0ffffh]        ; clock 6 U [AGI]
                mov     ebx,[offset mem+esi*4]          ; clock 6 V
                mov     ah,byte ptr [ebx]               ; clock 8 U [AGI]
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
                ; coloque aqui o lock
                mov     ebx,[offset memlock+esi*4]
                or      ebx,ebx
                jnz     writemem0
                ;
                mov     ebx,ecx
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
writemem0:      
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

emsg:           db      'starting emulation...$'
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
                mov     eax,offset emsg
                call    printmsg
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
emul05:         inc     edi
                dec     regb
                setflag_dec
                ret

; 06 - LD B,dd
emul06:         inc     edi
                call    fetch
                inc     edi
                mov     regb,al
                ret

; 07 - RLCA
emul07:         inc     edi
                rol     dh,1
                setflag_rlca
                ret

; 08 - EX AF,AF'
emul08:         inc     edi
                mov     ebx,edx
                mov     ecx,regeafl
                mov     edx,ecx
                mov     regeafl,ebx
                ret

; 09 - ADD HL,BC
emul09:         inc     edi
                mov     ebx,regebc
                add     reghl,bx
                setflag_add2
                ret

; 0A - LD A,(BC)
emul0A:         inc     edi
                mov     ecx,regebc
                call    readmem
                mov     dh,al
                ret

; 0B - DEC BC
emul0B:         inc     edi
                dec     regbc
                ret

; 0C - INC C
INCREG          0C,regc

; 0D - DEC C
emul0D:         inc     edi
                dec     regc
                setflag_dec
                ret

; 0E - LD C,dd
emul0E:         inc     edi
                call    fetch
                inc     edi
                mov     regc,al
                ret

; 0F - RRCA
emul0F:         inc     edi
                ror     dh,1
                setflag_rrca
                ret

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
emul15:         inc     edi
                dec     regd
                setflag_dec
                ret

; 16 - LD D,dd
emul16:         inc     edi
                call    fetch
                inc     edi
                mov     regd,al
                ret

; 17 - RLA
emul17:         inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     dh,1
                setflag_rla
                ret

; 18 - JR dd
emul18:         inc     edi
                call    fetch
                inc     edi
                movsx   ebx,al
                add     edi,ebx
                ret

; 19 - ADD HL,DE
emul19:         inc     edi
                mov     ebx,regede
                add     reghl,bx
                setflag_add2
                ret

; 1A - LD A,(DE)
emul1A:         inc     edi
                mov     ecx,regede
                call    readmem
                mov     dh,al
                ret

; 1B - DEC DE
emul1B:         inc     edi
                dec     regde
                ret

; 1C - INC E
INCREG          1C,rege

; 1D - DEC E
emul1D:         inc     edi
                dec     rege
                setflag_dec
                ret

; 1E - LD E,dd
emul1E:         inc     edi
                call    fetch
                inc     edi
                mov     rege,al
                ret

; 1F - RRA
emul1F:         inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     dh,1
                setflag_rra
                ret

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
emul25:         inc     edi
                dec     regh
                setflag_dec
                ret

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
emul29:         inc     edi
                mov     ebx,regehl
                add     reghl,bx
                setflag_add2
                ret

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
emul2B:         inc     edi
                dec     reghl
                ret

; 2C - INC L
INCREG          2C,regl

; 2D - DEC L
emul2D:         inc     edi
                dec     regl
                setflag_dec
                ret

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
emul35:         inc     edi
                mov     ecx,regehl
                call    readmem
                dec     al
                setflag_dec
                mov     ecx,regehl
                call    writemem
                ret

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
emul39:         inc     edi
                mov     ebx,regehl
                add     bx,regsp
                mov     reghl,bx
                setflag_add2
                ret

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
emul3B:         inc     edi
                dec     regsp
                ret

; 3C - INC A
INCREG          3C,dh

; 3D - DEC A
emul3D:         inc     edi
                dec     dh
                setflag_dec
                ret

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

; 41 - LD B,C
emul41:         inc     edi
                mov     bl,regc
                mov     regb,bl
                ret

; 42 - LD B,D
emul42:         inc     edi
                mov     al,regd
                mov     regb,al
                ret

; 43 - LD B,E
emul43:         inc     edi
                mov     bl,rege
                mov     regb,bl
                ret

; 44 - LD B,H
emul44:         inc     edi
                mov     al,regh
                mov     regb,al
                ret

; 45 - LD B,L
emul45:         inc     edi
                mov     bl,regl
                mov     regb,bl
                ret

; 46 - LD B,(HL)
emul46:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     regb,al
                ret

; 47 - LD B,A
emul47:         inc     edi
                mov     regb,dh
                ret

; 48 - LD C,B
emul48:         inc     edi
                mov     bl,regb
                mov     regc,bl
                ret

; 49 - LD C,C
emul49:         inc     edi
                ret

; 4A - LD C,D
emul4A:         inc     edi
                mov     bl,regd
                mov     regc,bl
                ret

; 4B - LD C,E   
emul4B:         inc     edi
                mov     bl,rege
                mov     regc,bl
                ret

; 4C - LD C,H
emul4C:         inc     edi
                mov     bl,regh
                mov     regc,bl
                ret

; 4D - LD C,L
emul4D:         inc     edi
                mov     al,regl
                mov     regc,al
                ret

; 4E - LD C,(HL)
emul4E:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     regc,al
                ret

; 4F - LD C,A
emul4F:         inc     edi
                mov     regc,dh
                ret

; 50 - LD D,B
emul50:         inc     edi
                mov     bl,regb
                mov     regd,bl
                ret

; 51 - LD D,C
emul51:         inc     edi
                mov     bl,regc
                mov     regd,bl
                ret

; 53 - LD D,E
emul53:         inc     edi
                mov     bl,rege
                mov     regd,bl
                ret

; 54 - LD D,H
emul54:         inc     edi
                mov     bl,regh
                mov     regd,bl
                ret

; 55 - LD D,L
emul55:         inc     edi
                mov     bl,regl
                mov     regd,bl
                ret

; 56 - LD D,(HL)
emul56:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     regd,al
                ret

; 57 - LD D,A
emul57:         inc     edi
                mov     regd,dh
                ret

; 59 - LD E,C
emul59:         inc     edi
                mov     bl,regc
                mov     rege,bl
                ret

; 5A - LD E,D
emul5A:         inc     edi
                mov     bl,regd
                mov     rege,bl
                ret

; 5C - LD E,H
emul5C:         inc     edi
                mov     bl,regh
                mov     rege,bl
                ret

; 5D - LD E,L
emul5D:         inc     edi
                mov     bl,regl
                mov     rege,bl
                ret

; 5E - LD E,(HL)
emul5E:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     rege,al
                ret

; 5F - LD E,A
emul5F:         inc     edi
                mov     rege,dh
                ret

; 60 - LD H,B
emul60:         inc     edi
                mov     bl,regb
                mov     regh,bl
                ret

; 61 - LD H,C
emul61:         inc     edi
                mov     bl,regc
                mov     regh,bl
                ret

; 62 - LD H,D  
emul62:         inc     edi
                mov     al,regd
                mov     regh,al
                ret

; 63 - LD H,E
emul63:         inc     edi
                mov     al,rege
                mov     regh,al
                ret

; 64 - LD H,H
emul64:         inc     edi
                ret

; 65 - LD H,L
emul65:         inc     edi
                mov     bl,regl
                mov     regh,bl
                ret

; 66 - LD H,(HL)
emul66:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     regh,al
                ret

; 67 - LD H,A
emul67:         inc     edi
                mov     regh,dh
                ret

; 68 - LD L,B
emul68:         inc     edi
                mov     bl,regb
                mov     regl,bl
                ret

; 69 - LD L,C   
emul69:         inc     edi
                mov     bl,regc
                mov     regl,bl
                ret

; 6A - LD L,D
emul6A:         inc     edi
                mov     bl,regd
                mov     regl,bl
                ret

; 6B - LD L,E
emul6B:         inc     edi
                mov     al,rege
                mov     regl,al
                ret

; 6C - LD L,H
emul6C:         inc     edi
                mov     al,regh
                mov     regl,al
                ret

; 6E - LD L,(HL)
emul6E:         inc     edi
                mov     ecx,regehl
                call    readmem
                mov     regl,al
                ret

; 6F - LD L,A
emul6F:         inc     edi
                mov     regl,dh
                ret

; 70 - LD (HL),B
emul70:         inc     edi
                mov     al,regb
                mov     ecx,regehl
                call    writemem
                ret

; 71 - LD (HL),C
emul71:         inc     edi
                mov     al,regc
                mov     ecx,regehl
                call    writemem
                ret

; 72 - LD (HL),D
emul72:         inc     edi
                mov     al,regd
                mov     ecx,regehl
                call    writemem
                ret

; 73 - LD (HL),E
emul73:         inc     edi
                mov     al,rege
                mov     ecx,regehl
                call    writemem
                ret

; 74 - LD (HL),H
emul74:         inc     edi
                mov     al,regh
                mov     ecx,regehl
                call    writemem
                ret

; 75 - LD (HL),L
emul75:         inc     edi
                mov     al,regl
                mov     ecx,regehl
                call    writemem
                ret

; 76 - HALT
emul76:         inc     edi
emul76a:        cmp     interrupt,1
                jne     emul76a
                ret

; 77 - LD (HL),A
emul77:         inc     edi
                mov     al,dh
                mov     ecx,regehl
                call    writemem
                ret

; 78 - LD A,B
emul78:         inc     edi
                mov     dh,regb
                ret

; 79 - LD A,C
emul79:         inc     edi
                mov     dh,regc
                ret

; 7A - LD A,D
emul7A:         inc     edi
                mov     dh,regd
                ret

; 7B - LD A,E
emul7B:         inc     edi
                mov     dh,rege
                ret

; 7C - LD A,H
emul7C:         inc     edi
                mov     dh,regh
                ret

; 7D - LD A,L
emul7D:         inc     edi
                mov     dh,regl
                ret

; 7E - LD A,(HL)
emul7E:         mov     ecx,regehl
                call    readmem
                inc     edi
                mov     dh,al
                ret

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
emulA0:         inc     edi
                and     dh,regb
                setflag_and
                ret

; A1 - AND C
emulA1:         inc     edi
                and     dh,regc
                setflag_and
                ret

; A2 - AND D
emulA2:         inc     edi
                and     dh,regd
                setflag_and
                ret

; A3 - AND E
emulA3:         inc     edi
                and     dh,rege
                setflag_and
                ret

; A4 - AND H
emulA4:         inc     edi
                and     dh,regh
                setflag_and
                ret

; A5 - AND L
emulA5:         inc     edi
                and     dh,regl
                setflag_and
                ret

; A6 - AND (HL)
emulA6:         inc     edi
                mov     ecx,regehl
                call    readmem
                and     dh,al
                setflag_and
                ret

; A7 - AND A
emulA7:         inc     edi
                and     dh,dh
                setflag_and
                ret

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
emulAE:         inc     edi
                mov     ecx,regehl
                call    readmem
                xor     dh,al
                setflag_xor
                ret

; AF - XOR A
XORREG          AF,dh
                
; B0 - OR B
emulB0:         inc     edi
                or      dh,regb
                setflag_or
                ret

; B1 - OR C
emulB1:         inc     edi
                or      dh,regc
                setflag_or
                ret

; B2 - OR D
emulB2:         inc     edi
                or      dh,regd
                setflag_or
                ret

; B3 - OR E
emulB3:         inc     edi
                or      dh,rege
                setflag_or
                ret

; B4 - OR H
emulB4:         inc     edi
                or      dh,regh
                setflag_or
                ret

; B5 - OR L
emulB5:         inc     edi
                or      dh,regl
                setflag_or
                ret

; B6 - OR (HL)
emulB6:         inc     edi
                mov     ecx,regehl
                call    readmem
                or      dh,al
                setflag_or
                ret

; B7 - OR A
emulB7:         inc     edi
                or      dh,dh
                setflag_or
                ret

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

; CB 01 - RLC C
emulCB01:       inc     edi
                rol     regc,1
                setflag_rlc
                ret

; CB 10 - RL B
emulCB10:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regb,1
                setflag_rl
                ret

; CB 11 - RL C
emulCB11:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regc,1
                setflag_rl
                ret

; CB 12 - RL D
emulCB12:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regd,1
                setflag_rl
                ret

; CB 14 - RL H
emulCB14:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regh,1
                setflag_rl
                ret

; CB 15 - RL L
emulCB15:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regl,1
                setflag_rl
                ret

; CB 18 - RR B
emulCB18:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regb,1
                setflag_rr
                ret

; CB 19 - RR C
emulCB19:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regc,1
                setflag_rr
                ret

; CB 1B - RR E
emulCB1B:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     rege,1
                setflag_rr
                ret

; CB 1C - RR H
emulCB1C:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regh,1
                setflag_rr
                ret

; CB 1D - RR L
emulCB1D:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regl,1
                setflag_rr
                ret

; CB 21 - SLA C
emulCB21:       inc     edi
                shl     regc,1
                setflag_shift
                ret

; CB 23 - SLA E
emulCB23:       inc     edi
                shl     rege,1
                setflag_shift
                ret

; CB 38 - SRL B
SRLREG          CB38,regb

; CB 39 - SRL C
SRLREG          CB39,regc

; CB 3A - SRL D
SRLREG          CB3A,regd

; CB 3B - SRL E
SRLREG          CB3B,rege

; CB 3C - SRL H
SRLREG          CB3C,regh

; CB 3D - SRL L
SRLREG          CB3D,regl

; CB 3F - SRL A
SRLREG          CB3F,dh

; CB 40 - BIT 0,B
BITREG          CB40,regb,0

; CB 41 - BIT 0,C
BITREG          CB41,regc,0

; CB 42 - BIT 0,D
BITREG          CB42,regd,0

; CB 43 - BIT 0,E
BITREG          CB43,rege,0

; CB 44 - BIT 0,H
BITREG          CB44,regh,0

; CB 45 - BIT 0,L
BITREG          CB45,regl,0

; CB 46 - BIT 0,(HL)
BITHL           CB46,0

; CB 47 - BIT 0,A
BITREG          CB47,dh,0

; CB 48 - BIT 1,B
BITREG          CB48,regb,1

; CB 49 - BIT 1,C
BITREG          CB49,regc,1

; CB 4A - BIT 1,D
BITREG          CB4A,regd,1

; CB 4B - BIT 1,E
BITREG          CB4B,rege,1

; CB 4C - BIT 1,H
BITREG          CB4C,regh,1

; CB 4D - BIT 1,L
BITREG          CB4D,regl,1

; CB 4E - BIT 1,(HL)
BITHL           CB4E,1

; CB 4F - BIT 1,A
BITREG          CB4F,dh,1

; CB 50 - BIT 2,B
BITREG          CB50,regb,2

; CB 51 - BIT 2,C
BITREG          CB51,regc,2

; CB 52 - BIT 2,D
BITREG          CB52,regd,2

; CB 53 - BIT 2,E
BITREG          CB53,rege,2

; CB 54 - BIT 2,H
BITREG          CB54,regh,2

; CB 55 - BIT 2,L
BITREG          CB55,regl,2

; CB 56 - BIT 2,(HL)
BITHL           CB56,2

; CB 57 - BIT 3,A
BITREG          CB57,dh,3

; CB 58 - BIT 3,B
BITREG          CB58,regb,3

; CB 59 - BIT 3,C
BITREG          CB59,regc,3

; CB 5A - BIT 3,D
BITREG          CB5A,regd,3

; CB 5B - BIT 3,E
BITREG          CB5B,rege,3

; CB 5C - BIT 3,H
BITREG          CB5C,regh,3

; CB 5D - BIT 3,L
BITREG          CB5D,regl,3

; CB 5E - BIT 3,(HL)
BITHL           CB5E,3

; CB 5F - BIT 3,A
BITREG          CB5F,dh,3

; CB 60 - BIT 4,B
BITREG          CB60,regb,4

; CB 61 - BIT 4,C
BITREG          CB61,regc,4

; CB 62 - BIT 4,D
BITREG          CB62,regd,4

; CB 63 - BIT 4,E
BITREG          CB63,rege,4

; CB 64 - BIT 4,H
BITREG          CB64,regh,4

; CB 65 - BIT 4,L
BITREG          CB65,regl,4

; CB 66 - BIT 4,(HL)
BITHL           CB66,4

; CB 67 - BIT 4,A
BITREG          CB67,dh,4

; CB 68 - BIT 5,B
BITREG          CB68,regb,5

; CB 69 - BIT 5,C
BITREG          CB69,regc,5

; CB 6A - BIT 5,D
BITREG          CB6A,regd,5

; CB 6B - BIT 5,E
BITREG          CB6B,rege,5

; CB 6C - BIT 5,H
BITREG          CB6C,regh,5

; CB 6D - BIT 5,L
BITREG          CB6D,regl,5

; CB 6E - BIT 5,(HL)
BITHL           CB6E,5

; CB 6F - BIT 5,A
BITREG          CB6F,dh,5

; CB 70 - BIT 6,B
BITREG          CB70,regb,6

; CB 71 - BIT 6,C
BITREG          CB71,regc,6

; CB 72 - BIT 6,D
BITREG          CB72,regd,6

; CB 73 - BIT 6,E
BITREG          CB73,rege,6

; CB 74 - BIT 6,H
BITREG          CB74,regh,6

; CB 75 - BIT 6,L
BITREG          CB75,regl,6

; CB 76 - BIT 6,(HL)
BITHL           CB76,6

; CB 77 - BIT 6,A
BITREG          CB77,dh,6

; CB 78 - BIT 7,B
BITREG          CB78,regb,7

; CB 79 - BIT 7,C
BITREG          CB79,regc,7

; CB 7A - BIT 7,D
BITREG          CB7A,regd,7

; CB 7B - BIT 7,E
BITREG          CB7B,rege,7

; CB 7C - BIT 7,H
BITREG          CB7C,regh,7

; CB 7D - BIT 7,L
BITREG          CB7D,regl,7

; CB 7E - BIT 7,(HL)
BITHL           CB7E,7

; CB 7F - BIT 7,A
BITREG          CB7F,dh,7

; CB 86 - RES 0,(HL)
RESHL           CB86,0

; CB 8E - RES 1,(HL)
RESHL           CB8E,1

; CB 8F - RES 1,A
emulCB8F:       inc     edi
                and     dh,NBIT_1
                ret

; CB 96 - RES 2,(HL)
RESHL           CB96,2

; CB 9E - RES 3,(HL)
RESHL           CB9E,3

; CB A6 - RES 4,(HL)
RESHL           CBA6,4

; CB A8 - RES 5,B
RESREG          CBA8,regb,5

; CB A9 - RES 5,C
RESREG          CBA9,regc,5

; CB AA - RES 5,D
RESREG          CBAA,regd,5

; CB AB - RES 5,E
RESREG          CBAB,rege,5

; CB AC - RES 5,H
RESREG          CBAC,regh,5

; CB AD - RES 5,L
RESREG          CBAD,regl,5

; CB AE - RES 5,(HL)
RESHL           CBAE,5

; CB AF - RES 5,A
RESREG          CBAF,dh,5

; CB B2 - RES 6,D
emulCBB2:       inc     edi
                and     regd,NBIT_6
                ret

; CB B6 - RES 6,(HL)
RESHL           CBB6,6

; CB B8 - RES 7,B
emulCBB8:       inc     edi
                and     regb,NBIT_7
                ret

; CB BE - RES 7,(HL)
RESHL           CBBE,7

; CB BF - RES 7,A
emulCBBF:       inc     edi
                and     dh,NBIT_7
                ret

; CB C1 - SET 0,C
emulCBC1:       inc     edi
                or      regc,BIT_0
                ret

; CB C6 - SET 0,(HL)
emulCBC6:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_0
                call    writemem
                ret

; CB CE - SET 1,(HL)
emulCBCE:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_1
                call    writemem
                ret

; CB CF - SET 1,A
emulCBCF:       inc     edi
                or      dh,BIT_1
                ret

; CB D7 - SET 2,A
emulCBD7:       inc     edi
                or      dh,BIT_2
                ret

; CB DE - SET 3,(HL)
emulCBDE:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_3
                call    writemem
                ret

; CB E6 - SET 4,(HL)
emulCBE6:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_4
                call    writemem
                ret

; CB E8 - SET 5,B
SETREG          CBE8,regb,5

; CB E9 - SET 5,C
SETREG          CBE9,regc,5

; CB EA - SET 5,D
SETREG          CBEA,regd,5

; CB EB - SET 5,E
SETREG          CBEB,rege,5

; CB EC - SET 5,H
SETREG          CBEC,regh,5

; CB ED - SET 5,L
SETREG          CBED,regl,5

; CB EE - SET 5,(HL)
emulCBEE:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_5
                call    writemem
                ret

; CB EF - SET 5,A
SETREG          CBEF,dh,5

; CB F2 - SET 6,D
emulCBF2:       inc     edi
                or      regd,BIT_6
                ret

; CB F6 - SET 6,(HL)
emulCBF6:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_6
                call    writemem
                ret

; CB FE - SET 7,(HL)
emulCBFE:       inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_7
                call    writemem
                ret

; DD 09 - ADD IX,BC
emulDD09:       inc     edi
                mov     ebx,regebc
                add     regix,bx
                setflag_add2
                ret

; DD 19 - ADD IX,DE
emulDD19:       inc     edi
                mov     ebx,regede
                add     regix,bx
                setflag_add2
                ret

; DD 21 - LD IX,dddd
emulDD21:       inc     edi               
                call    fetchw
                add     edi,2
                mov     regeix,eax
                xor     eax,eax
                ret

; DD 22 - LD (dddd),IX
emulDD22:       inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,regixl
                call    writemem
                inc     cx
                mov     al,regixh
                call    writemem
                xor     eax,eax
                ret

; DD 23 - INC IX
INCWREG         DD23,regix,10

; DD 2A - LD IX,(dddd)
emulDD2A:       inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     regixl,al
                inc     cx
                call    readmem
                mov     regixh,al
                xor     eax,eax
                add     edi,2
                ret

; DD 2B - DEC IX
emulDD2B:       inc     edi
                dec     regix
                ret

; DD 35 - DEC (IX+dd)
emulDD35:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                push    ecx
                call    readmem
                dec     al
                setflag_dec
                pop     ecx
                call    writemem
                ret

; DD 36 - LD (IX+dd),dd
emulDD36:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                call    fetch
                inc     edi
                call    writemem
                ret

; DD 46 - LD B,(IX+dd)
emulDD46:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     regb,al
                ret

; DD 4E - LD C,(IX+dd)
emulDD4E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     regc,al
                ret

; DD 56 - LD D,(IX+dd)
emulDD56:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     regd,al
                ret

; DD 5E - LD E,(IX+dd)
emulDD5E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     rege,al
                ret

; DD 66 - LD H,(IX+dd)
emulDD66:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     regh,al
                ret

; DD 6E - LD L,(IX+dd)
emulDD6E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     regl,al
                ret

; DD 70 - LD (IX+dd),B
LDIXDDREG       DD70,regb

; DD 71 - LD (IX+dd),C
LDIXDDREG       DD71,regc

; DD 72 - LD (IX+dd),D
LDIXDDREG       DD72,regd

; DD 73 - LD (IX+dd),E
LDIXDDREG       DD73,rege

; DD 74 - LD (IX+dd),H
LDIXDDREG       DD74,regh

; DD 75 - LD (IX+dd),L
LDIXDDREG       DD75,regl

; DD 77 - LD (IX+dd),A
LDIXDDREG       DD77,dh

; DD 7E - LD A,(IX+dd)
emulDD7E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                mov     dh,al
                ret

; DD 86 - ADD A,(IX+dd)
emulDD86:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                add     dh,al
                setflag_add
                ret

; DD A6 - AND (IX+dd)
emulDDA6:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                and     dh,al
                setflag_and
                ret

; DD BE - CP (IX+dd)
emulDDBE:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeix
                add     cx,ax
                call    readmem
                cmp     dh,al
                setflag_cp
                ret

; DD CB - group DD CB
emulDDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetDDCBxx+eax*4]

; DD E1 - POP IX
emulDDE1:       inc     edi
                mov     ecx,regesp
                call    readmem
                mov     regixl,al
                inc     cx
                call    readmem
                mov     regixh,al
                inc     cx
                mov     regesp,ecx
                ret

; DD E5 - PUSH IX
emulDDE5:       inc     edi
                mov     ecx,regesp
                dec     cx
                mov     al,regixh
                call    writemem
                dec     cx
                mov     al,regixl
                call    writemem
                mov     regesp,ecx
                ret

; DD E9 - JP (IX)
emulDDE9:       mov     edi,regeix
                ret

; DD CB 1E - RR (IX+dd)
emulDDCB1E:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     bl,dl
                shr     bl,1
                rcr     al,1
                push    ecx
                setflag_rr
                pop     ecx
                call    writemem
                ret

; DD CB 46 - BIT 0,(IX+dd)
emulDDCB46:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_0
                setflag_bit
                ret

; DD CB 4E - BIT 1,(IX+dd)
emulDDCB4E:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_1
                setflag_bit
                ret

; DD CB 5E - BIT 3,(IX+dd)
emulDDCB5E:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_3
                setflag_bit
                ret

; DD CB 6E - BIT 5,(IX+dd)
emulDDCB6E:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_5
                setflag_bit
                ret

; DD CB 76 - BIT 6,(IX+dd)
emulDDCB76:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_6
                setflag_bit
                ret

; DD CB 7E - BIT 7,(IX+dd)
emulDDCB7E:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                test    al,BIT_7
                setflag_bit
                ret

; DD CB AE - RES 5,(IX+dd)
emulDDCBAE:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                and     al,NBIT_7
                call    writemem
                ret

; DD CB FE - SET 7,(IX+dd)
emulDDCBFE:     inc     edi
                mov     bl,cl
                xor     bh,bh
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                or      al,BIT_7
                call    writemem
                ret

; ED 41 - OUT (C),B
emulED41:       inc     edi
                mov     bl,regb
                mov     al,regc
                call    [offset outportxx+eax*4]
                ret

; ED 42 - SBC HL,DE
emulED42:       inc     edi        
                mov     bl,dl
                shr     bl,1
                mov     ecx,regede
                sbb     reghl,cx
                setflag_adc
                ret

; ED 43 - LD (dddd),BC
emulED43:       inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,regc
                call    writemem
                inc     cx
                mov     al,regb
                call    writemem
                xor     eax,eax
                ret

; ED 44 - NEG
OPNEG           ED44

; ED 4B - LD BC,(dddd)
emulED4B:       inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     regc,al
                inc     cx
                call    readmem
                mov     regb,al
                xor     eax,eax
                add     edi,2
                ret

; ED 4D - RETI
emulED4D:       jmp     emulC9

; ED 52 - SBC HL,DE
emulED52:       inc     edi
                mov     bl,dl
                shr     bl,1
                mov     ebx,regede
                sbb     reghl,bx
                setflag_sbc
                ret

; ED 53 - LD (dddd),DE
emulED53:       inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,rege
                call    writemem
                inc     cx
                mov     al,regd
                call    writemem
                xor     eax,eax
                ret

; ED 56 - IM 1
emulED56:       inc     edi
                ret

; ED 57 - LD A,I
emulED57:       inc     edi
                mov     dh,0
                ret

; ED 5B - LD DE,(dddd)
emulED5B:       inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     rege,al
                inc     cx
                call    readmem
                mov     regd,al
                xor     eax,eax
                add     edi,2
                ret

; ED 5F - LD A,R
emulED5F:       inc     edi
                mov     dh,byte ptr [offset rcounter]
                and     dh,07fh
                or      dh,rmask
                ret

; ED 62 - SBC HL,HL
emulED62:       inc     edi
                mov     bl,dl
                shr     bl,1
                mov     ecx,regehl
                sbb     reghl,cx
                setflag_adc
                ret

; ED 67 - RRD
OPRRD           ED67

; ED 6F - RLD
emulED6F:       inc     edi
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     ah,dh
                shl     eax,4
                mov     bh,dh
                and     bh,0fh
                or      al,bh
                and     ah,0fh
                and     dh,0f0h
                or      dh,ah
                setflag_rld
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                xor     eax,eax
                ret

; ED 73 - LD (dddd),SP
emulED73:       inc     edi
                call    fetchw
                add     edi,2
                mov     ecx,eax
                mov     al,regspl
                call    writemem
                inc     cx
                mov     al,regsph
                call    writemem
                xor     eax,eax
                ret

; ED 78 - IN A,(C)
emulED78:       inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     dh,bl
                or      dh,dh
                setflag_in_c
                ret

; ED 79 - OUT (C),A
emulED79:       inc     edi
                mov     bl,dh
                mov     al,regc
                call    [offset outportxx+eax*4]
                ret

; ED 7B - LD SP,(dddd)
emulED7B:       inc     edi
                call    fetchw
                mov     ecx,eax
                call    readmem
                mov     regspl,al
                inc     cx
                call    readmem
                mov     regsph,al
                xor     eax,eax
                add     edi,2
                ret

; ED A0 - LDI
emulEDA0:       inc     edi
                mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                inc     reghl
                inc     regde
                dec     regbc
                setflag_ldi
                ret

; ED A3 - OUTI
emulEDA3:       inc     edi
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     al,regc
                call    [offset outportxx+eax*4]
                inc     reghl
                dec     regb
                setflag_outi
                ret

; ED A8 - LDD
OPLDD             EDA8

; ED B0 - LDIR
emulEDB0:       inc     edi
emulEDB0a:      mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                inc     reghl
                inc     regde
                dec     regbc
                jnz     emulEDB0a
                ret

; ED B8 - LDDR
emulEDB8:       inc     edi
emulEDB8a:      mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                dec     reghl
                dec     regde
                dec     regbc
                jnz     emulEDB8a
                ret

; ED B9 - CPDR
emulEDB9:       inc     edi
emulEDB9b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB9a
                dec     reghl
                dec     regbc
                jnz     emulEDB9b
                and     dl,10111011b
                ret
emulEDB9a:      or      dl,01000100b
                ret

; FD 09 - ADD IY,BC
emulFD09:       inc     edi
                mov     ebx,regebc
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
emulFD2B:       inc     edi
                dec     regiy
                ret

; FD 34 - INC (IY+dd)
INCIY           FD34

; FD 46 - LD B,(IY+dd)
emulFD46:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                mov     regb,al
                ret

; FD 4E - LD C,(IY+dd)
emulFD4E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                mov     regc,al
                ret

; FD 56 - LD D,(IY+dd)
emulFD56:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                mov     regd,al
                ret

; FD 5E - LD E,(IY+dd)
emulFD5E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                mov     rege,al
                ret

; FD 77 - LD (IY+dd),A
emulFD77:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                mov     al,dh
                call    writemem
                ret

; FD 7E - LD A,(IY+dd)
emulFD7E:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                mov     dh,al
                ret

; FD AE - XOR (IY+dd)
emulFDAE:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
                call    readmem
                xor     dh,al
                setflag_xor
                ret

; FD BE - CP (IY+dd)
emulFDBE:       inc     edi
                call    fetch
                inc     edi
                mov     ecx,regeiy
                add     cx,ax
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
                ret

outemulA8:      mov     prim_slotreg,bl
                ; frame 0
                and     ebx,03h
                shl     ebx,5
                mov     ecx,[offset slot+ebx]
                mov     mem00,ecx
                add     ecx,2000h
                mov     mem20,ecx
                mov     ecx,[offset slot+ebx]
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

inemulA8:       mov     bl,prim_slotreg
                ret

inemulA9:       movzx   ecx,keyboard_line
                mov     bl,byte ptr [offset keymatrix+ecx]
                ret

; --------------------------------------------------------------------

code32          ends
                end




