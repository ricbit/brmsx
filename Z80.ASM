; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom:near
extrn msxvram:near
extrn pset:near

include io.inc
include debug.inc

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

public regaf
public regbc
public reghl
public regde
public regsp
public regpc
public vdpregs

; DATA ---------------------------------------------------------------

include iset.inc
include isetCB.inc
include isetDD.inc
include isetED.inc
include isetFD.inc
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
memlock00       dd      1
memlock20       dd      1
memlock40       dd      1
memlock60       dd      1
memlock80       dd      0
memlocka0       dd      0
memlockc0       dd      0
memlocke0       dd      0

breakpoint      dd      0
iff1            dd      0
interrupt       dd      0
error           dd      0

vdpcond         dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      8 dup (0)
vdptemp         db      0
vdpstatus       db      0

outvalueA8      db      0
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
CARRY_FLAG      equ     00000001b

BIT_0           equ     00000001b
BIT_1           equ     00000010b
BIT_2           equ     00000100b
BIT_3           equ     00001000b
BIT_4           equ     00010000b
BIT_5           equ     00100000b
BIT_6           equ     01000000b
BIT_7           equ     10000000b

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
                mov     iff1,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_loop:
                and     edi,0ffffh
                call    fetch
                call    [offset iset + eax*4]
                cmp     interrupt,1
                je      emulate_interrupt
                cmp     exit_now,1
                je      emulate_exit
                cmp     error,1
                jne     emulate_loop
emulate_exit:
                mov     regpc,di
                mov     regaf,dx
                ret
emulate_interrupt:
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
                mov     interrupt,0
                mov     exit_now,0
                movzx   edi,regpc
                movzx   edx,regaf
emulate_break_loop:
                and     edi,0ffffh
                cmp     edi,breakpoint
                je      emulate_break_end
                call    fetch
                call    [offset iset + eax*4]
                cmp     interrupt,1
                je      emulate_break_interrupt
                cmp     exit_now,1
                je      emulate_break_end
                cmp     error,1
                jne     emulate_break_loop
emulate_break_end:
                mov     regpc,di
                mov     regaf,dx
                ret
emulate_break_interrupt:
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
emul03:         inc     edi
                inc     regbc
                ret

; 04 - INC B
emul04:         inc     edi
                inc     regb
                setflag_inc
                ret

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
emul0C:         inc     edi
                inc     regc
                setflag_inc
                ret

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
emul13:         inc     edi
                inc     regde
                ret

; 14 - INC D
emul14:         inc     edi
                inc     regd
                setflag_inc
                ret

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
emul1C:         inc     edi
                inc     rege
                ret

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
emul23:         inc     edi
                inc     reghl
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

; 26 - LD H,dd
emul26:         inc     edi
                call    fetch
                inc     edi
                mov     regh,al
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
emul2C:         inc     edi
                inc     regl
                setflag_inc
                ret

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

; 34 - INC (HL)
emul34:         inc     edi
                mov     ecx,regehl
                call    readmem
                inc     al
                setflag_inc
                mov     ecx,regehl
                call    writemem
                ret

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

; 3C - INC A
emul3C:         inc     edi
                inc     dh
                setflag_inc
                ret

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

; 42 - LD B,D
emul42:         inc     edi
                mov     al,regd
                mov     regb,al
                ret

; 44 - LD B,H
emul44:         inc     edi
                mov     al,regh
                mov     regb,al
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

; 4B - LD C,E   
emul4B:         inc     edi
                mov     bl,rege
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

; 62 - LD H,D  
emul62:         inc     edi
                mov     al,regd
                mov     regh,al
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

; 69 - LD L,C   
emul69:         inc     edi
                mov     bl,regc
                mov     regl,bl
                ret

; 6B - LD L,E
emul6B:         inc     edi
                mov     al,rege
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
emul80:         inc     edi
                add     dh,regb
                setflag_add     
                ret

; 83 - ADD A,E
emul83:         inc     edi
                add     dh,rege
                setflag_add
                ret

; 86 - ADD A,(HL)
emul86:         inc     edi
                mov     ecx,regehl
                call    readmem
                add     dh,al
                setflag_add
                ret

; 87 - ADD A,A
emul87:         inc     edi
                add     dh,dh
                setflag_add
                ret

; 8F - ADC A,A
emul8F:         inc     edi
                mov     bl,dl
                shr     bl,1
                adc     dh,dh
                setflag_adc
                ret

; 90 - SUB B
emul90:         inc     edi
                sub     dh,regb
                setflag_sub
                ret

; 91 - SUB C
emul91:         inc     edi
                sub     dh,regc
                setflag_sub
                ret

; 92 - SUB D
emul92:         inc     edi
                sub     dh,regd
                setflag_sub
                ret

; 93 - SUB E
emul93:         inc     edi
                sub     dh,rege
                setflag_sub
                ret

; 95 - SUB L
emul95:         inc     edi
                sub     dh,regl
                setflag_sub
                ret

; 98 - SBC A,B
emul98:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,regb
                setflag_sbc
                ret

; 9A - SBC A,D
emul9A:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,regd
                setflag_sbc
                ret

; 9C - SBC A,H
emul9C:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,regh
                setflag_sbc
                ret

; 9F - SBC A,A
emul9F:         inc     edi
                mov     bl,dl
                shr     bl,1
                sbb     dh,dh
                setflag_sbc
                ret

; A1 - AND C
emulA1:         inc     edi
                and     dh,regc
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

; AE - XOR (HL)
emulAE:         inc     edi
                mov     ecx,regehl
                call    readmem
                xor     dh,al
                setflag_xor
                ret

; AF - XOR A
emulAF:         inc     edi
                xor     dh,dh
                setflag_xor
                ret
                
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
emulC6:         inc     edi
                call    fetch
                add     dh,al
                setflag_add
                inc     edi
                ret

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
                jnz     emulCD
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
emulD6:         inc     edi
                call    fetch
                sub     dh,al
                setflag_sub
                inc     edi
                ret

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
                call    fetch
                and     eax,0ffh
                jmp     [offset isetDDxx+eax*4]

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

; CB 11 - RL C
emulCB11:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcl     regc,1
                setflag_rl
                ret


; CB 19 - RR C
emulCB19:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regc,1
                setflag_rr
                ret

; CB 1C - RR H
emulCB1C:       inc     edi
                mov     bl,dl
                shr     bl,1
                rcr     regh,1
                setflag_rr
                ret

; CB 21 - SLA C
emulCB21:       inc     edi
                shl     regc,1
                setflag_shift
                ret

; CB 4F - BIT 1,A
emulCB4F:       inc     edi
                test    dh,BIT_1
                setflag_bit
                ret

; CB 63 - BIT 4,E
emulCB63:       inc     edi
                test    rege,BIT_4
                setflag_bit
                ret

; CB C1 - SET 0,C
emulCBC1:       inc     edi
                or      regc,1
                ret

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

outemulA8:      mov     outvalueA8,bl
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

inemulA8:       mov     bl,outvalueA8
                ret

inemulA9:       movzx   ecx,keyboard_line
                mov     bl,byte ptr [offset keymatrix+ecx]
                ret

; --------------------------------------------------------------------

code32          ends
                end




