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

include isetDD.inc
public isetDDxx

; --------------------------------------------------------------------

setflag_add2    macro

                pushfd
                pop     ecx
                and     ecx,1
                and     dl,11111100b
                or      dl,cl
                
                endm

setflag_add     macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                
                endm

setflag_and     macro

                pushfd
                pop     ecx
                mov     dl,cl
                and     dl,11000100b
                or      dl,00010000b

                endm

setflag_cp      macro

                pushfd
                pop     ecx
                and     ecx,0000100011000001b
                shr     ch,1
                mov     dl,cl
                or      dl,ch
                or      dl,00000010b
                
                endm

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

; DD 29 - ADD IX,IX
emulDD29:       inc     edi
                mov     ecx,regeix
                add     regix,cx
                setflag_add2
                ret

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
DECWREG         DD2B,regix,10

; DD 34 - INC (IX+dd)
INCII           DD34,regeix

; DD 35 - DEC (IX+dd)
DECII           DD35,regeix

; DD 36 - LD (IX+dd),dd
LDIIDDNN        DD36,regeix

; DD 46 - LD B,(IX+dd)
emulDD46:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     regb,al
                ret

; DD 4E - LD C,(IX+dd)
emulDD4E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     regc,al
                ret

; DD 56 - LD D,(IX+dd)
emulDD56:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     regd,al
                ret

; DD 5E - LD E,(IX+dd)
emulDD5E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     rege,al
                ret

; DD 66 - LD H,(IX+dd)
emulDD66:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     regh,al
                ret

; DD 6E - LD L,(IX+dd)
emulDD6E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     regl,al
                ret

; DD 70 - LD (IX+dd),B
LDIIDDREG       DD70,regb,regeix

; DD 71 - LD (IX+dd),C
LDIIDDREG       DD71,regc,regeix

; DD 72 - LD (IX+dd),D
LDIIDDREG       DD72,regd,regeix

; DD 73 - LD (IX+dd),E
LDIIDDREG       DD73,rege,regeix

; DD 74 - LD (IX+dd),H
LDIIDDREG       DD74,regh,regeix

; DD 75 - LD (IX+dd),L
LDIIDDREG       DD75,regl,regeix

; DD 77 - LD (IX+dd),A
LDIIDDREG       DD77,dh,regeix

; DD 7E - LD A,(IX+dd)
emulDD7E:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                mov     dh,al
                ret

; DD 86 - ADD A,(IX+dd)
emulDD86:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                add     dh,al
                setflag_add
                ret

; DD 96 - SUB (IX+dd)
SUBII           DD96,regeix

; DD A6 - AND (IX+dd)
emulDDA6:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
                call    readmem
                and     dh,al
                setflag_and
                ret

; DD B6 - OR (IX+dd)
ORII            DDB6,regeix

; DD BE - CP (IX+dd)
emulDDBE:       inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,regeix
                add     cx,bx
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


code32          ends
                end


