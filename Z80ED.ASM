; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80ED.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include opcode.inc
include bit.inc

extrn emulEDFF: near

; DATA ---------------------------------------------------------------

align 4

include isetED.inc
public isetEDxx

; --------------------------------------------------------------------

; ED 40 - IN B,(C)
INREG           ED40,regb

; ED 41 - OUT (C),B
OUTCREG         ED41,regb

; ED 42 - SBC HL,BC
SBCHLWREG       ED42,regc,regb

; ED 43 - LD (dddd),BC
LDDDDDREGW      ED43,regebc

; ED 44 - NEG
OPNEG           ED44

; ED 48 - IN C,(C)
INREG           ED48,regc

; ED 49 - OUT (C),C
OUTCREG         ED49,regc

; ED 4A - ADC HL,BC
ADCREGWREGW     ED4A,regl,regh,regc,regb

; ED 4B - LD BC,(dddd)
LDREGWDDDD      ED4B,regebc

; ED 4D - RETI
emulED4D:       jmp     emulC9

; ED 50 - IN D,(C)
INREG           ED50,regd

; ED 51 - OUT (C),D
OUTCREG         ED51,regd

; ED 52 - SBC HL,DE
SBCHLWREG       ED52,rege,regd

; ED 53 - LD (dddd),DE
LDDDDDREGW      ED53,regede

; ED 56 - IM 1
emulED56:       inc     edi
                mov     ebp,8+2
                ret

; ED 57 - LD A,I
LDAI            ED57

; ED 58 - IN E,(C)
INREG           ED58,rege

; ED 59 - OUT (C),E
OUTCREG         ED59,rege

; ED 5A - ADC HL,DE
ADCREGWREGW     ED5A,regl,regh,rege,regd

; ED 5B - LD DE,(dddd)
LDREGWDDDD      ED5B,regede

; ED 5F - LD A,R
LDAR            ED5F    

; ED 60 - IN H,(C)
INREG           ED60,regh

; ED 61 - OUT (C),H
OUTCREG         ED61,regh

; ED 62 - SBC HL,HL
SBCHLWREG       ED62,regl,regh

; ED 67 - RRD
OPRRD           ED67

; ED 68 - IN L,(C)
INREG           ED68,regl

; ED 69 - OUT (C),L
OUTCREG         ED69,regl

; ED 6A - ADC HL,HL
ADCREGWREGW     ED6A,regl,regh,regl,regh

; ED 6F - RLD
OPRLD           ED6F  

; ED 72 - SBC HL,SP
SBCHLWREG       ED72,regspl,regsph

; ED 73 - LD (dddd),SP
LDDDDDREGW      ED73,regesp

; ED 78 - IN A,(C)
INREG           ED78,dh

; ED 79 - OUT (C),A
OUTCREG         ED79,dh

; ED 7A - ADC HL,SP
ADCREGWREGW     ED7A,regl,regh,regspl,regsph

; ED 7B - LD SP,(dddd)
LDREGWDDDD      ED7B,regesp

; ED A0 - LDI
OPLDI           EDA0

; ED A2 - INI
emulEDA2:       inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                inc     reghl
                dec     regb
                pushfd
                pop     ecx
                and     dl,10111111b
                and     cl,01000010b ;check
                or      dl,cl
                mov     ebp,16+3
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
                pushfd
                pop     ecx
                and     dl,10111111b
                and     cl,01000010b ;check
                or      dl,cl
                mov     ebp,16+3
                ret

; ED A8 - LDD
OPLDD           EDA8

; ED B0 - LDIR
emulEDB0:       inc     edi
                mov     ebp,0
emulEDB0a:      mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                add     ebp,21+2
                inc     reghl
                inc     regde
                dec     regbc
                jnz     emulEDB0a
                sub     ebp,5-2
                ret

; ED B1 - CPIR
emulEDB1:       inc     edi
                mov     ebp,0
emulEDB1b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB1a
                add     ebp,21+2
                inc     reghl
                dec     regbc
                jnz     emulEDB1b
                and     dl,10111011b
                sub     ebp,5-2
                ret
emulEDB1a:      
                inc     reghl
                dec     regbc
                or      dl,01000100b
                sub     ebp,5-2
                ret

; ED B8 - LDDR
emulEDB8:       inc     edi
                mov     ebp,0
emulEDB8a:      mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                add     ebp,21+2
                dec     reghl
                dec     regde
                dec     regbc
                jnz     emulEDB8a
                sub     ebp,5-2
                ret

; ED B9 - CPDR
emulEDB9:       inc     edi
                mov     ebp,0
emulEDB9b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB9a
                add     ebp,21+2
                dec     reghl
                dec     regbc
                jnz     emulEDB9b
                and     dl,10111011b
                sub     ebp,5-2
                ret
emulEDB9a:      
                dec     reghl
                dec     regbc
                or      dl,01000100b
                sub     ebp,5-2
                ret

code32          ends
                end


