; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include opcode.inc
include bit.inc

; DATA ---------------------------------------------------------------

include isetFD.inc
include isetFDCB.inc
public isetFDxx

; --------------------------------------------------------------------

setflag_cp      macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                or      dl,00000010b
                
                endm

setflag_add2    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11111100b
                or      dl,cl
                
                endm

; --------------------------------------------------------------------

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
LDREGIIDD       FD46,regb,regeiy

; FD 4E - LD C,(IY+dd)
LDREGIIDD       FD4E,regc,regeiy

; FD 56 - LD D,(IY+dd)
LDREGIIDD       FD56,regd,regeiy

; FD 5E - LD E,(IY+dd)
LDREGIIDD       FD5E,rege,regeiy

; FD 66 - LD H,(IY+dd)
LDREGIIDD       FD66,regh,regeiy

; FD 6E - LD L,(IY+dd)
LDREGIIDD       FD6E,regl,regeiy

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
LDREGIIDD       FD7E,dh,regeiy

; FD 86 - ADD A,(IY+dd)
ADDAII          FD86,regeiy

; FD 96 - SUB (IY+dd)
SUBII           FD96,regeiy

; FD AE - XOR (IY+dd)
XORII           FDAE,regeiy

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

; FD CB - group FD CB
emulFDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetFDCBxx+eax*4]

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

; FD CB 46 - BIT 0,(IX+dd)
BITII           FDCB46,0,regeiy

; FD CB 4E - BIT 1,(IX+dd)
BITII           FDCB4E,1,regeiy

; FD CB 56 - BIT 2,(IX+dd)
BITII           FDCB56,2,regeiy

; FD CB 5E - BIT 3,(IX+dd)
BITII           FDCB5E,3,regeiy

; FD CB 66 - BIT 4,(IX+dd)
BITII           FDCB66,4,regeiy

; FD CB 6E - BIT 5,(IX+dd)
BITII           FDCB6E,5,regeiy

; FD CB 76 - BIT 6,(IX+dd)
BITII           FDCB76,6,regeiy

; FD CB 7E - BIT 7,(IX+dd)
BITII           FDCB7E,7,regeiy

; FD CB 46 - RES 0,(IX+dd)
RESII           FDCB86,0,regeiy

; FD CB 4E - RES 1,(IX+dd)
RESII           FDCB8E,1,regeiy

; FD CB 56 - RES 2,(IX+dd)
RESII           FDCB96,2,regeiy

; FD CB 5E - RES 3,(IX+dd)
RESII           FDCB9E,3,regeiy

; FD CB 66 - RES 4,(IX+dd)
RESII           FDCBA6,4,regeiy

; FD CB 6E - RES 5,(IX+dd)
RESII           FDCBAE,5,regeiy

; FD CB 76 - RES 6,(IX+dd)
RESII           FDCBB6,6,regeiy

; FD CB 7E - RES 7,(IX+dd)
RESII           FDCBBE,7,regeiy

; FD CB 46 - SET 0,(IX+dd)
SETII           FDCBC6,0,regeiy

; FD CB 4E - SET 1,(IX+dd)
SETII           FDCBCE,1,regeiy

; FD CB 56 - SET 2,(IX+dd)
SETII           FDCBD6,2,regeiy

; FD CB 5E - SET 3,(IX+dd)
SETII           FDCBDE,3,regeiy

; FD CB 66 - SET 4,(IX+dd)
SETII           FDCBE6,4,regeiy

; FD CB 6E - SET 5,(IX+dd)
SETII           FDCBEE,5,regeiy

; FD CB 76 - SET 6,(IX+dd)
SETII           FDCBF6,6,regeiy

; FD CB 7E - SET 7,(IX+dd)
SETII           FDCBFE,7,regeiy


code32          ends
                end


