; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80ED.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc
include copcode.inc
include bit.inc
include cfetch.inc

public info_table_ed

; DATA ---------------------------------------------------------------

align 4

include infoed.inc

; --------------------------------------------------------------------

ENDOPCODE       macro   opcode

comp&opcode&_end:

                endm

; --------------------------------------------------------------------

; ED 40 - IN B,(C)
INREG           ED40,regb
ENDOPCODE       ED40

; ED 41 - OUT (C),B
OUTCREG         ED41,regb
ENDOPCODE       ED41

; ED 42 - SBC HL,BC
SBCHLWREG       ED42,regc,regb
ENDOPCODE       ED42

; ED 43 - LD (dddd),BC
LDDDDDREGW2     ED43,regebc
ENDOPCODE       ED43

; ED 44 - NEG
OPNEG           ED44
ENDOPCODE       ED44

; ED 48 - IN C,(C)
INREG           ED48,regc
ENDOPCODE       ED48

; ED 49 - OUT (C),C
OUTCREG         ED49,regc
ENDOPCODE       ED49

; ED 4A - ADC HL,BC
ADCREGWREGW     ED4A,regl,regh,regc,regb
ENDOPCODE       ED4A

; ED 4B - LD BC,(dddd)
LDREGWDDDD2     ED4B,regebc
ENDOPCODE       ED4B

; ED 4D - RETI
OPRET           ED4D
ENDOPCODE       ED4D

; ED 50 - IN D,(C)
INREG           ED50,regd
ENDOPCODE       ED50

; ED 51 - OUT (C),D
OUTCREG         ED51,regd
ENDOPCODE       ED51

; ED 52 - SBC HL,DE
SBCHLWREG       ED52,rege,regd
ENDOPCODE       ED52

; ED 53 - LD (dddd),DE
LDDDDDREGW2     ED53,regede
ENDOPCODE       ED53

; ED 56 - IM 1
OPIM1           ED56
ENDOPCODE       ED56

; ED 57 - LD A,I
LDAI            ED57
ENDOPCODE       ED57

; ED 58 - IN E,(C)
INREG           ED58,rege
ENDOPCODE       ED58

; ED 59 - OUT (C),E
OUTCREG         ED59,rege
ENDOPCODE       ED59

; ED 5A - ADC HL,DE
ADCREGWREGW     ED5A,regl,regh,rege,regd
ENDOPCODE       ED5A

; ED 5B - LD DE,(dddd)
LDREGWDDDD2     ED5B,regede
ENDOPCODE       ED5B

; ED 5F - LD A,R
LDAR            ED5F    
ENDOPCODE       ED5F

; ED 60 - IN H,(C)
INREG           ED60,regh
ENDOPCODE       ED60

; ED 61 - OUT (C),H
OUTCREG         ED61,regh
ENDOPCODE       ED61

; ED 62 - SBC HL,HL
SBCHLWREG       ED62,regl,regh
ENDOPCODE       ED62

; ED 67 - RRD
OPRRD           ED67
ENDOPCODE       ED67

; ED 68 - IN L,(C)
INREG           ED68,regl
ENDOPCODE       ED68

; ED 69 - OUT (C),L
OUTCREG         ED69,regl
ENDOPCODE       ED69

; ED 6A - ADC HL,HL
ADCREGWREGW     ED6A,regl,regh,regl,regh
ENDOPCODE       ED6A

; ED 6F - RLD
OPRLD           ED6F  
ENDOPCODE       ED6F

; ED 72 - SBC HL,SP
SBCHLWREG       ED72,regspl,regsph
ENDOPCODE       ED72

; ED 73 - LD (dddd),SP
LDDDDDREGW2     ED73,regesp
ENDOPCODE       ED73

; ED 78 - IN A,(C)
INREG           ED78,dh
ENDOPCODE       ED78

; ED 79 - OUT (C),A
OUTCREG         ED79,dh
ENDOPCODE       ED79

; ED 7A - ADC HL,SP
ADCREGWREGW     ED7A,regl,regh,regspl,regsph
ENDOPCODE       ED7A

; ED 7B - LD SP,(dddd)
LDREGWDDDD2     ED7B,regesp
ENDOPCODE       ED7B

; ED A0 - LDI
OPLDI           EDA0
ENDOPCODE       EDA0

; ED A2 - INI
OPINI           EDA2
ENDOPCODE       EDA2

; ED A3 - OUTI
OPOUTI          EDA3
ENDOPCODE       EDA3

; ED A8 - LDD
OPLDD           EDA8
ENDOPCODE       EDA8

; ED B0 - LDIR
OPLDIR          EDB0
ENDOPCODE       EDB0

; ED B1 - CPIR
OPCPIR          EDB1
ENDOPCODE       EDB1

; ED B8 - LDDR
OPLDDR          EDB8
ENDOPCODE       EDB8

; ED B9 - CPDR
OPCPDR          EDB9
ENDOPCODE       EDB9

code32          ends
                end


