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
emulED41:       inc     edi
                mov     bl,regb
                mov     al,regc
                call    [offset outportxx+eax*4]
                ret

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
                ret

; ED 44 - NEG
OPNEG           ED44

; ED 4A - ADC HL,BC
ADCHLWREG       ED4A,regc,regb

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
emulED4D:       mov     iff1,1
                jmp     emulC9

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
                ret

; ED 56 - IM 1
emulED56:       inc     edi
                ret

; ED 57 - LD A,I
LDAI            ED57

; ED 5A - ADC HL,DE
ADCHLWREG       ED5A,rege,regd

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
LDAR            ED5F    

; ED 62 - SBC HL,HL
SBCHLWREG       ED62,regl,regh

; ED 67 - RRD
OPRRD           ED67

; ED 6A - ADC HL,HL
ADCHLWREG       ED6A,regl,regh

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
                ret

; ED 79 - OUT (C),A
emulED79:       inc     edi
                mov     bl,dh
                mov     al,regc
                call    [offset outportxx+eax*4]
                ret

; ED 7A - ADC HL,SP
ADCHLWREG       ED7A,regspl,regsph

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
                pushfd
                pop     ecx
                and     dl,11101001b
                and     cl,01000000b 
                shr     cl,4
                or      dl,cl
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

; ED B1 - CPIR
emulEDB1:       inc     edi
emulEDB1b:      mov     ecx,regehl
                call    readmem
                cmp     dh,al
                jz      emulEDB1a
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
emulEDB9a:      
                dec     reghl
                dec     regbc
                or      dl,01000100b
                ret

code32          ends
                end


