; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include opcode.inc
include bit.inc

extrn emulEDFF: near

; DATA ---------------------------------------------------------------

include isetED.inc
public isetEDxx

; --------------------------------------------------------------------

; ED 41 - OUT (C),B
OUTCREG         ED41,regb

; ED 42 - SBC HL,BC
SBCHLWREG       ED42,regc,regb

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
                mov     ebp,20
                ret

; ED 44 - NEG
OPNEG           ED44

; ED 49 - OUT (C),C
OUTCREG         ED49,regc

; ED 4A - ADC HL,BC
ADCREGWREGW     ED4A,regl,regh,regc,regb

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
                mov     ebp,20
                ret

; ED 4D - RETI
emulED4D:       mov     iff1,1
                jmp     emulC9

; ED 51 - OUT (C),D
OUTCREG         ED51,regd

; ED 52 - SBC HL,DE
SBCHLWREG       ED52,rege,regd

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
                mov     ebp,20
                ret

; ED 56 - IM 1
emulED56:       inc     edi
                mov     ebp,8
                ret

; ED 57 - LD A,I
LDAI            ED57

; ED 59 - OUT (C),E
OUTCREG         ED59,rege

; ED 5A - ADC HL,DE
ADCREGWREGW     ED5A,regl,regh,rege,regd

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
                mov     ebp,20
                ret

; ED 5F - LD A,R
LDAR            ED5F    

; ED 61 - OUT (C),H
OUTCREG         ED61,regh

; ED 62 - SBC HL,HL
SBCHLWREG       ED62,regl,regh

; ED 67 - RRD
OPRRD           ED67

; ED 69 - OUT (C),L
OUTCREG         ED69,regl

; ED 6A - ADC HL,HL
ADCREGWREGW     ED6A,regl,regh,regl,regh

; ED 6F - RLD
OPRLD           ED6F  

; ED 72 - SBC HL,SP
SBCHLWREG       ED72,regspl,regsph

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
                mov     ebp,20
                ret

; ED 78 - IN A,(C)
emulED78:       inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     dh,bl
                or      dh,dh
                pushfd
                pop     ecx
                and     dl,00000001b
                and     cl,11111100b
                or      dl,cl
                mov     ebp,12
                ret

; ED 79 - OUT (C),A
OUTCREG         ED79,dh

; ED 7A - ADC HL,SP
ADCREGWREGW     ED7A,regl,regh,regspl,regsph

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
                mov     ebp,20
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
                pushfd
                pop     ecx
                and     dl,11101001b
                and     cl,01000000b 
                shr     cl,4
                or      dl,cl
                mov     ebp,16
                ret

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
                mov     ebp,16
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
                mov     ebp,16
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
                add     ebp,21
                inc     reghl
                inc     regde
                dec     regbc
                jnz     emulEDB0a
                ret

; ED B1 - CPIR
emulEDB1:       inc     edi
                mov     ebp,0
emulEDB1b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB1a
                add     ebp,21
                inc     reghl
                dec     regbc
                jnz     emulEDB1b
                and     dl,10111011b
                ret
emulEDB1a:      
                inc     reghl
                dec     regbc
                or      dl,01000100b
                ret

; ED B8 - LDDR
emulEDB8:       inc     edi
                mov     ebp,0
emulEDB8a:      mov     ecx,regehl
                call    readmem
                mov     ecx,regede
                call    writemem
                add     ebp,21
                dec     reghl
                dec     regde
                dec     regbc
                jnz     emulEDB8a
                ret

; ED B9 - CPDR
emulEDB9:       inc     edi
                mov     ebp,0
emulEDB9b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB9a
                add     ebp,21
                dec     reghl
                dec     regbc
                jnz     emulEDB9b
                and     dl,10111011b
                ret
emulEDB9a:      
                dec     reghl
                dec     regbc
                or      dl,01000100b
                ret

code32          ends
                end


