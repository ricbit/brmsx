; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom:near
extrn msxvram:near

include io.inc
include debug.inc

public fetch
public trace
public print
public emulate
public emulate_break
public emulate_echo

public breakpoint

public regaf
public regbc
public reghl
public regde
public regsp
public regpc

; DATA ---------------------------------------------------------------

include iset.inc
include isetCB.inc
include isetED.inc
include pset.inc
include psetCB.inc
include psetED.inc
include outport.inc
include inport.inc

msxram          db      8000h dup (0)

mem:
mem00           dd      msxrom
mem20           dd      msxrom+2000h
mem40           dd      msxrom+4000h
mem60           dd      msxrom+6000h
mem80           dd      msxram
mema0           dd      msxram+2000h
memc0           dd      msxram+4000h
meme0           dd      msxram+6000h

memlock:               
memlock00       dd      0
memlock20       dd      0
memlock40       dd      0
memlock60       dd      0
memlock80       dd      0
memlocka0       dd      0
memlockc0       dd      0
memlocke0       dd      0

breakpoint      dd      0
interrupt       dd      0
error           dd      0
outvalueA8      db      0

align 4

regaf           dw      00h
                dw      00h
regbc           dw      11h
                dw      00h
regde           dw      22h
                dw      00h
reghl           dw      33h
                dw      00h
regpc           dw      00h
                dw      00h
regsp           dw      00h
                dw      00h

rega            equ     byte ptr [offset regaf+1]
regf            equ     byte ptr [offset regaf+0]
regb            equ     byte ptr [offset regbc+1]
regc            equ     byte ptr [offset regbc+0]
regd            equ     byte ptr [offset regde+1]
rege            equ     byte ptr [offset regde+0]
regh            equ     byte ptr [offset reghl+1]
regl            equ     byte ptr [offset reghl+0]

regeaf          equ     dword ptr [offset regaf]
regebc          equ     dword ptr [offset regbc]
regede          equ     dword ptr [offset regde]
regehl          equ     dword ptr [offset reghl]
regepc          equ     dword ptr [offset regpc]
regesp          equ     dword ptr [offset regsp]

SIGN_FLAG       equ     10000000b
ZERO_FLAG       equ     01000000b
HALF_FLAG       equ     00010000b
PARITY_FLAG     equ     00000100b
OVERFLOW_FLAG   equ     00000100b
CARRY_FLAG      equ     00000001b

; print opcodes routines ---------------------------------------------
; first number is size of instruction
; second number is number of strings
; third number is size of argument

PRINTOP100      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,1
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                ret

                endm

PRINTOP200      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                ret

                endm

PRINTOP211      macro number,desc        

msg&number:     db      desc
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetch
                call    printhex2
                ret

                endm

PRINTOP221      macro   number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetch
                call    printhex2
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP312      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,3
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetchw
                call    printhex4
                ret

                endm

PRINTOP322      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,3
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetchw
                call    printhex4
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

; setflag_xor --------------------------------------------------------
; sets the z80 flags after xor operations

setflag_xor     macro

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

; setflag_inc --------------------------------------------------------
; sets the z80 flags after inc operations

setflag_inc     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
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
                and     ecx,0000100011000001b
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
                mov     ebx,ecx
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
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
                mov     eax,offset emsg
                call    printmsg
                mov     eax,0
                mov     ecx,0
                mov     error,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_loop:
                and     edi,0ffffh
                call    fetch
                call    [offset iset + eax*4]
                cmp     error,1
                jne     emulate_loop
                mov     regpc,di
                mov     regaf,dx
                ret

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:
                mov     eax,offset emsg
                call    printmsg
                mov     eax,0
                mov     ecx,0
                mov     error,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_break_loop:
                and     edi,0ffffh
                cmp     edi,breakpoint
                je      emulate_break_end
                call    fetch
                call    [offset iset + eax*4]
                cmp     error,1
                jne     emulate_break_loop
emulate_break_end:
                mov     regpc,di
                mov     regaf,dx
                ret

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
                call    fetch
                call    [offset iset + eax*4]
                cmp     error,1
                jne     emulate_echo_loop
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

printopcode:
                mov     ebp,4
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                call    fetch
                call    printhex2
                call    printspace
                ret
printopcode0:
                push    ebp
                call    printspace
                call    printspace
                call    printspace
                pop     ebp
                dec     ebp
                jnz     printopcode0
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

; 04 - INC B
emul04:         inc     edi
                inc     regb
                setflag_inc
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

; 10 - DJNZ dd
emul10:         inc     edi
                call    fetch
                inc     edi
                dec     regbc
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

; 19 - ADD HL,DE
emul19:         inc     edi
                mov     ebx,regede
                add     reghl,bx
                setflag_add
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

; 24 - INC H
emul24:         inc     edi
                inc     regh
                setflag_inc
                ret

; 25 - DEC H
emul25:         inc     edi
                dec     regh
                setflag_dec
                ret

; 28 - JR Z,dd
emul28:         inc     edi
                call    fetch
                inc     edi
                test    dl,ZERO_FLAG    
                jz      emul28a
                movsx   ebx,al
                add     edi,ebx
emul28a:        ret

; 2B - DEC HL
emul2B:         inc     edi
                dec     reghl
                ret

; 2E - LD L,dd
emul2E:         inc     edi
                call    fetch
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

; 36 - LD (HL),dd
emul36:         inc     edi
                call    fetch
                mov     ecx,regehl        
                call    writemem
                inc     edi
                ret

; 39 - ADD HL,SP
emul39:         inc     edi
                mov     ebx,regehl
                add     bx,regsp
                mov     reghl,bx
                setflag_add             ; ricardo check this it's wrong
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

; 3C - INC A
emul3C:         inc     edi
                inc     dh
                setflag_inc
                ret

; 3E - LD A,dd
emul3E:         inc     edi
                call    fetch
                inc     edi
                mov     dh,al
                ret

; 4F - LD C,A
emul4F:         inc     edi
                mov     regc,dh
                ret

; 57 - LD D,A
emul57:         inc     edi
                mov     regd,dh
                ret

; 5F - LD E,A
emul5F:         inc     edi
                mov     rege,dh
                ret

; 67 - LD H,A
emul67:         inc     edi
                mov     regh,dh
                ret

; 6F - LD L,A
emul6F:         inc     edi
                mov     regl,dh
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

; 93 - SUB E
emul93:         inc     edi
                sub     dh,rege
                setflag_sub
                ret

; 9A - SBC A,D
emul9A:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,regd
                setflag_sbc
                ret

; 9F - SBC A,A
emul9F:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,regd
                setflag_sbc
                ret

; A7 - AND A
emulA7:         inc     edi
                and     dh,dh
                setflag_and
                ret

; AF - XOR A
emulAF:         inc     edi
                xor     dh,dh
                setflag_xor
                ret
                
; BE - CP (HL)
emulBE:         inc     edi
                mov     ecx,regehl
                call    readmem
                cmp     dh,al
                setflag_cp
                ret

; C3 - JP
emulC3:         inc     edi
                call    fetchw
                mov     edi,eax
                xor     eax,eax
                ret

; C6 - ADD A,dd
emulC6:         inc     edi
                call    fetch
                add     dh,al
                setflag_add
                inc     edi
                ret

; CB - group CB
emulCB:         inc     edi
                call    fetch
                jmp     [offset isetCBxx+eax*4]

; D3 - OUT (dd),A
emulD3:         inc     edi
                call    fetch
                inc     edi
                mov     bl,dh
                jmp     [offset outportxx+eax*4]

; D6 - SUB dd
emulD6:         inc     edi
                call    fetch
                sub     dh,al
                setflag_sub
                inc     edi
                ret

; DB - IN A,(dd)
emulDB:         inc     edi
                call    fetch
                inc     edi
                call    [offset inportxx+eax*4]
                mov     dh,bl
                ret

; E6 - AND dd
emulE6:         inc     edi
                call    fetch
                inc     edi
                and     dh,al
                setflag_and
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
                call    fetch
                and     eax,0ffh
                jmp     [offset isetEDxx+eax*4]

; F3 - DI
emulF3:         inc     edi
                mov     interrupt,0
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

; FE - CP dd
emulFE:         inc     edi
                call    fetch
                inc     edi
                cmp     dh,al
                setflag_cp
                ret

; CB 01 - RLC C
emulCB01:       inc     edi
                rcl     regc,1
                setflag_rlc
                ret

; CB 19 - RR C
emulCB19:       inc     edi
                rcr     regc,1
                setflag_rr
                ret

; CB 21 - SLA C
emulCB21:       inc     edi
                shl     regc,1
                setflag_shift
                ret

; CB C1 - SET 0,C
emulCBC1:       inc     edi
                or      regc,1
                ret

; ED 56 - IM 1
emulED56:       inc     edi
                ret

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

; XX - not found
emulXX:         mov     error,1
                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

outemulA8:      mov     outvalueA8,bl
                ret

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       ret

inemulA8:       mov     bl,outvalueA8
                ret

; --------------------------------------------------------------------

prinCB:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetCBxx+eax*4]

prinED:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetEDxx+eax*4]

PRINTOP100      00,'NOP$'
PRINTOP312      01,'LD BC,$'
PRINTOP100      04,'INC B$'
PRINTOP211      06,'LD B,$'
PRINTOP100      07,'RLCA$'
PRINTOP211      10,'DJNZ $'
PRINTOP312      11,'LD DE,$'
PRINTOP100      19,'ADD HL,DE$'
PRINTOP211      20,'JR NZ,$'
PRINTOP312      21,'LD HL,$'
PRINTOP322      22,'LD ($','),HL$'
PRINTOP100      24,'INC H$'
PRINTOP100      25,'DEC H$'
PRINTOP211      28,'JR Z,$'
PRINTOP100      2B,'DEC HL$'
PRINTOP211      2E,'LD L,$'
PRINTOP100      2F,'CPL$'
PRINTOP211      30,'JR NC,$'
PRINTOP312      31,'LD SP,$'
PRINTOP322      32,'LD ($','),A$'
PRINTOP211      36,'LD (HL),$'
PRINTOP100      39,'ADD HL,SP$'
PRINTOP322      3A,'LD A,($',')$'
PRINTOP100      3C,'INC A$'
PRINTOP211      3E,'LD A,$'
PRINTOP100      4F,'LD C,A$'                
PRINTOP100      57,'LD D,A$'
PRINTOP100      5F,'LD E,A$'
PRINTOP100      67,'LD H,A$'
PRINTOP100      6F,'LD L,A$'
PRINTOP100      77,'LD (HL),A$'
PRINTOP100      78,'LD A,B$'
PRINTOP100      79,'LD A,C$'
PRINTOP100      7C,'LD A,H$'
PRINTOP100      7D,'LD A,L$'
PRINTOP100      7E,'LD A,(HL)$'
PRINTOP100      93,'SUB E$'
PRINTOP100      9A,'SBC A,D$'
PRINTOP100      9F,'SBC A,A$'
PRINTOP100      A7,'AND A$'
PRINTOP100      AF,'XOR A$'
PRINTOP100      BE,'CP (HL)$'
PRINTOP312      C3,'JP $'
PRINTOP211      C6,'ADD A,$'
PRINTOP221      D3,'OUT ($','),A$'
PRINTOP211      D6,'SUB $'
PRINTOP221      DB,'IN A,($',')$'
PRINTOP211      E6,'AND $'
PRINTOP100      EB,'EX DE,HL$'
PRINTOP100      F3,'DI$'
PRINTOP100      F9,'LD SP,HL$'
PRINTOP312      FA,'JP M,$'
PRINTOP211      FE,'CP $'
PRINTOP200      CB01,'RLC C$'
PRINTOP200      CB19,'RR C$'
PRINTOP200      CB21,'SLA C$'
PRINTOP200      CBC1,'SET 0,C$'
PRINTOP200      ED56,'IM 1$'
PRINTOP200      EDB0,'LDIR$'
PRINTOP100      XX,'not emulated yet$'

; --------------------------------------------------------------------

code32          ends
                end



