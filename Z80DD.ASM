; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80DD.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80sing.inc
include opcode.inc
include bit.inc
include fetch.inc

; DATA ---------------------------------------------------------------

align 4

include isetDD.inc
include isetDDCB.inc
public isetDDxx

; --------------------------------------------------------------------

; DD 09 - ADD IX,BC
ADDREGWREGW     DD09,regixl,regixh,regc,regb,15+2

; DD 19 - ADD IX,DE
ADDREGWREGW     DD19,regixl,regixh,rege,regd,15+2

; DD 21 - LD IX,dddd
LDREGWIMM      DD21,regeix

; DD 22 - LD (dddd),IX
LDDDDDREGW      DD22,regeix,20+2

; DD 23 - INC IX
INCWREG         DD23,regix,10+2

; DD 29 - ADD IX,IX
ADDREGWREGW     DD29,regixl,regixh,regixl,regixh,15+2

; DD 2A - LD IX,(dddd)
LDREGWDDDD      DD2A,regeix,20+2

; DD 2B - DEC IX
DECWREG         DD2B,regix,10+2

; DD 34 - INC (IX+dd)
INCII           DD34,regeix

; DD 35 - DEC (IX+dd)
DECII           DD35,regeix

; DD 36 - LD (IX+dd),dd
LDIIDDNN        DD36,regeix

; DD 39 - ADD IX,SP
ADDREGWREGW     DD39,regixl,regixh,regspl,regsph,15+2

; DD 46 - LD B,(IX+dd)
LDREGIIDD       DD46,regb,regeix

; DD 4E - LD C,(IX+dd)
LDREGIIDD       DD4E,regc,regeix

; DD 56 - LD D,(IX+dd)
LDREGIIDD       DD56,regd,regeix

; DD 5E - LD E,(IX+dd)
LDREGIIDD       DD5E,rege,regeix

; DD 66 - LD H,(IX+dd)
LDREGIIDD       DD66,regh,regeix

; DD 6E - LD L,(IX+dd)
LDREGIIDD       DD6E,regl,regeix

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
LDREGIIDD       DD7E,dh,regeix

; DD 86 - ADD A,(IX+dd)
ADDAII          DD86,regeix

; DD 8E - ADC A,(IX+dd)
ADCAII          DD8E,regeix

; DD 96 - SUB (IX+dd)
SUBII           DD96,regeix

; DD 9E - SBC A,(IX+dd)
SBCAII          DD9E,regeix

; DD A6 - AND (IX+dd)
ANDII           DDA6,regeix

; DD AE - XOR (IX+dd)
XORII           DDAE,regeix

; DD B6 - OR (IX+dd)
ORII            DDB6,regeix

; DD BE - CP (IX+dd)
CPII            DDBE,regeix

; DD CB - group DD CB
emulDDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetDDCBxx+eax*4]

; DD E1 - POP IX
POPREGW         DDE1,regeix,14+2

; DD E3 - EX (SP),IX
OPEXSPREGW      DDE3,regeix,23+2

; DD E5 - PUSH IX
PUSHREGW        DDE5,regeix,15+2

; DD E9 - JP (IX)
OPJPREGW        DDE9,regeix,8+2

; DD F9 - LD SP,IX
LDSPREGW        DDF9,regeix,10+2

; DD CB 06 - RLC (IX+dd)
RLCII           DDCB06,regeix

; DD CB 16 - RL (IX+dd)
RLII            DDCB16,regeix

; DD CB 1E - RR (IX+dd)
RRII            DDCB1E,regeix

; DD CB 46 - BIT 0,(IX+dd)
BITII           DDCB46,0,regeix

; DD CB 4E - BIT 1,(IX+dd)
BITII           DDCB4E,1,regeix

; DD CB 56 - BIT 2,(IX+dd)
BITII           DDCB56,2,regeix

; DD CB 5E - BIT 3,(IX+dd)
BITII           DDCB5E,3,regeix

; DD CB 66 - BIT 4,(IX+dd)
BITII           DDCB66,4,regeix

; DD CB 6E - BIT 5,(IX+dd)
BITII           DDCB6E,5,regeix

; DD CB 76 - BIT 6,(IX+dd)
BITII           DDCB76,6,regeix

; DD CB 7E - BIT 7,(IX+dd)
BITII           DDCB7E,7,regeix

; DD CB 46 - RES 0,(IX+dd)
RESII           DDCB86,0,regeix

; DD CB 4E - RES 1,(IX+dd)
RESII           DDCB8E,1,regeix

; DD CB 56 - RES 2,(IX+dd)
RESII           DDCB96,2,regeix

; DD CB 5E - RES 3,(IX+dd)
RESII           DDCB9E,3,regeix

; DD CB 66 - RES 4,(IX+dd)
RESII           DDCBA6,4,regeix

; DD CB 6E - RES 5,(IX+dd)
RESII           DDCBAE,5,regeix

; DD CB 76 - RES 6,(IX+dd)
RESII           DDCBB6,6,regeix

; DD CB 7E - RES 7,(IX+dd)
RESII           DDCBBE,7,regeix

; DD CB C6 - SET 0,(IX+dd)
SETII           DDCBC6,0,regeix

; DD CB CE - SET 1,(IX+dd)
SETII           DDCBCE,1,regeix

; DD CB D6 - SET 2,(IX+dd)
SETII           DDCBD6,2,regeix

; DD CB DE - SET 3,(IX+dd)
SETII           DDCBDE,3,regeix

; DD CB E6 - SET 4,(IX+dd)
SETII           DDCBE6,4,regeix

; DD CB EE - SET 5,(IX+dd)
SETII           DDCBEE,5,regeix

; DD CB F6 - SET 6,(IX+dd)
SETII           DDCBF6,6,regeix

; DD CB FE - SET 7,(IX+dd)
SETII           DDCBFE,7,regeix

code32          ends
                end


