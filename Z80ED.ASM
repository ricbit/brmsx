; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80ED.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80sing.inc
include pmode.inc
include opcode.inc
include bit.inc
include fetch.inc

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
OPRET           ED4D

; ED 50 - IN D,(C)
INREG           ED50,regd

; ED 51 - OUT (C),D
OUTCREG         ED51,regd

; ED 52 - SBC HL,DE
SBCHLWREG       ED52,rege,regd

; ED 53 - LD (dddd),DE
LDDDDDREGW      ED53,regede

; ED 56 - IM 1
OPIM1           ED56

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
OPINI           EDA2

; ED A3 - OUTI
OPOUTI          EDA3

; ED A8 - LDD
OPLDD           EDA8

; ED B0 - LDIR
OPLDIR          EDB0

; ED B1 - CPIR
OPCPIR          EDB1

; ED B8 - LDDR
OPLDDR          EDB8

; ED B9 - CPDR
OPCPDR          EDB9

code32          ends
                end


