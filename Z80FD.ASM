; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80FD.ASM
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

include isetFD.inc
include isetFDCB.inc
public isetFDxx

; --------------------------------------------------------------------

; FD 09 - ADD IY,BC
ADDREGWREGW     FD09,regiyl,regiyh,regc,regb,15+2

; FD 19 - ADD IY,DE
ADDREGWREGW     FD19,regiyl,regiyh,rege,regd,15+2

; FD 21 - LD IY,dddd
LDREGWIMM      FD21,regeiy

; FD 22 - LD (dddd),IY
LDDDDDREGW      FD22,regeiy,20+2

; FD 23 - INC IY
INCWREG         FD23,regiy,10+2

; FD 24 - INC IYh
INCREG          FD24,regiyh

; FD 25 - DEC IYh
DECREG          FD25,regiyh

; FD 26 - LD IYh,dd
LDREGIMM        FD26,regiyh

; FD 29 - ADD IY,IY
ADDREGWREGW     FD29,regiyl,regiyh,regiyl,regiyh,15+2

; FD 2A - LD IY,(dddd)
LDREGWDDDD      FD2A,regeiy,20+2

; FD 2B - DEC IY
DECWREG         FD2B,regiy,10+2

; FD 2C - INC IYl
INCREG          FD2C,regiyl

; FD 2D - DEC IYl
DECREG          FD2D,regiyl

; FD 2E - LD IYl,dd
LDREGIMM        FD2E,regiyl

; FD 34 - INC (IY+dd)
INCII           FD34,regeiy

; FD 35 - DEC (IY+dd)
DECII           FD35,regeiy

; FD 36 - LD (IY+dd),dd
LDIIDDNN        FD36,regeiy

; FD 39 - ADD IY,SP
ADDREGWREGW     FD39,regiyl,regiyh,regspl,regsph,15+2

; FD 40 - FD null prefix
XNULL           FD40

; FD 41 - FD null prefix
XNULL           FD41

; FD 42 - FD null prefix
XNULL           FD42

; FD 43 - FD null prefix
XNULL           FD43

; FD 44 - LD B,IYh
LDREGREG        FD44,regb,regiyh

; FD 45 - LD B,IYl
LDREGREG        FD45,regb,regiyl

; FD 46 - LD B,(IY+dd)
LDREGIIDD       FD46,regb,regeiy

; FD 47 - FD null prefix
XNULL           FD47

; FD 48 - FD null prefix
XNULL           FD48

; FD 49 - FD null prefix
XNULL           FD49

; FD 4A - FD null prefix
XNULL           FD4A

; FD 4B - FD null prefix
XNULL           FD4B

; FD 4C - LD C,IYh
LDREGREG        FD4C,regc,regiyh

; FD 4D - LD C,IYl
LDREGREG        FD4D,regc,regiyl

; FD 4E - LD C,(IY+dd)
LDREGIIDD       FD4E,regc,regeiy

; FD 4F - FD null prefix
XNULL           FD4F

; FD 50 - FD null prefix
XNULL           FD50

; FD 51 - FD null prefix
XNULL           FD51

; FD 52 - FD null prefix
XNULL           FD52

; FD 53 - FD null prefix
XNULL           FD53

; FD 54 - LD D,IYh
LDREGREG        FD54,regd,regiyh

; FD 55 - LD D,IYl
LDREGREG        FD55,regd,regiyl

; FD 56 - LD D,(IY+dd)
LDREGIIDD       FD56,regd,regeiy

; FD 57 - FD null prefix
XNULL           FD57

; FD 58 - FD null prefix
XNULL           FD58

; FD 59 - FD null prefix
XNULL           FD59

; FD 5A - FD null prefix
XNULL           FD5A

; FD 5B - FD null prefix
XNULL           FD5B

; FD 5C - LD E,IYh
LDREGREG        FD5C,rege,regiyh

; FD 5D - LD E,IYl
LDREGREG        FD5D,rege,regiyl

; FD 5E - LD E,(IY+dd)
LDREGIIDD       FD5E,rege,regeiy

; FD 5F - FD null prefix
XNULL           FD5F

; FD 60 - LD IYh,B
LDREGREG        FD60,regiyh,regb

; FD 61 - LD IYh,C
LDREGREG        FD61,regiyh,regc

; FD 62 - LD IYh,D
LDREGREG        FD62,regiyh,regd

; FD 63 - LD IYh,E
LDREGREG        FD63,regiyh,rege

; FD 64 - LD IYh,IYh
LDREGREG        FD64,regiyh,regiyh

; FD 65 - LD IYh,IYl
LDREGREG        FD65,regiyh,regiyl

; FD 66 - LD H,(IY+dd)
LDREGIIDD       FD66,regh,regeiy

; FD 67 - LD IYh,A
LDREGREG        FD67,regiyh,dh

; FD 68 - LD IYl,B
LDREGREG        FD68,regiyl,regb

; FD 69 - LD IYl,C
LDREGREG        FD69,regiyl,regc

; FD 6A - LD IYl,D
LDREGREG        FD6A,regiyl,regd

; FD 6B - LD IYl,E
LDREGREG        FD6B,regiyl,rege

; FD 6C - LD IYl,IYh
LDREGREG        FD6C,regiyl,regiyh

; FD 6D - LD IYl,IYl
LDREGREG        FD6D,regiyl,regiyl

; FD 6E - LD L,(IY+dd)
LDREGIIDD       FD6E,regl,regeiy

; FD 6F - LD IYl,A
LDREGREG        FD6F,regiyl,dh

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

; FD 76 - FD null prefix
XNULL           FD76

; FD 77 - LD (IY+dd),A
LDIIDDREG       FD77,dh,regeiy

; FD 78 - FD null prefix
XNULL           FD78

; FD 79 - FD null prefix
XNULL           FD79

; FD 7A - FD null prefix
XNULL           FD7A

; FD 7B - FD null prefix
XNULL           FD7B

; FD 7C - LD A,IYh
LDREGREG        FD7C,dh,regiyh

; FD 7D - LD A,IYl
LDREGREG        FD7D,dh,regiyl

; FD 7E - LD A,(IY+dd)
LDREGIIDD       FD7E,dh,regeiy

; FD 7F - FD null prefix
XNULL           FD7F

; FD 84 - ADD A,IXh
ADDREG          FD84,regiyh

; FD 85 - ADD A,IXl
ADDREG          FD85,regiyl

; FD 86 - ADD A,(IY+dd)
ADDAII          FD86,regeiy

; FD 8C - ADC A,IXh
ADCREG          FD8C,regiyh

; FD 8D - ADC A,IXl
ADCREG          FD8D,regiyl

; FD 8E - ADC A,(IY+dd)
ADCAII          FD8E,regeiy

; FD 94 - SUB IXh
SUBREG          FD94,regiyh

; FD 95 - SUB IXl
SUBREG          FD95,regiyl

; FD 96 - SUB (IY+dd)
SUBII           FD96,regeiy

; FD 9C - SBC A,IXh
SBCREG          FD9C,regiyh

; FD 9D - SBC A,IXl
SBCREG          FD9D,regiyl

; FD 9E - SBC A,(IY+dd)
SBCAII          FD9E,regeiy

; FD A4 - AND IXh
ANDREG          FDA4,regiyh

; FD A5 - AND IXl
ANDREG          FDA5,regiyl

; FD A6 - AND (IY+dd)
ANDII           FDA6,regeiy

; FD AC - AND IXh
XORREG          FDAC,regiyh

; FD AD - AND IXl
XORREG          FDAD,regiyl

; FD AE - XOR (IY+dd)
XORII           FDAE,regeiy

; FD B4 - OR IXh
ORREG           FDB4,regiyh

; FD B5 - OR IXl
ORREG           FDB5,regiyl

; FD B6 - OR (IY+dd)
ORII            FDB6,regeiy

; FD BC - CP IXh
CPREG           FDBC,regiyh

; FD BD - CP IXl
CPREG           FDBD,regiyl

; FD BE - CP (IY+dd)
CPII            FDBE,regeiy

; FD CB - group FD CB
emulFDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetFDCBxx+eax*4]

; FD E1 - POP IY
POPREGW         FDE1,regeiy,14+2

; FD E3 - EX (SP),IY
OPEXSPREGW      FDE3,regeiy,23+2

; FD E5 - PUSH IY
PUSHREGW        FDE5,regeiy,15+2

; FD E9 - JP (IY)
OPJPREGW        FDE9,regeiy,8+2

; FD F9 - LD SP,IY
LDSPREGW        FDF9,regeiy,10+2

; FD CB 06 - RLC (IY+dd)
RLCII           FDCB06,regeiy

; FD CB 0E - RRC (IY+dd)
RRCII           FDCB0E,regeiy

; FD CB 16 - RL (IY+dd)
RLII            FDCB16,regeiy

; FD CB 1E - RR (IY+dd)
RRII            FDCB1E,regeiy

; FD CB 26 - SLA (IY+dd)
SLAII           FDCB26,regeiy

; FD CB 2E - SRA (IY+dd)
SRAII           FDCB2E,regeiy

; FD CB 36 - SLL (IY+dd)
SLLII           FDCB36,regeiy

; FD CB 3E - SRL (IY+dd)
SRLII           FDCB3E,regeiy

; FD CB 46 - BIT 0,(IY+dd)
BITII           FDCB46,0,regeiy

; FD CB 4E - BIT 1,(IY+dd)
BITII           FDCB4E,1,regeiy

; FD CB 56 - BIT 2,(IY+dd)
BITII           FDCB56,2,regeiy

; FD CB 5E - BIT 3,(IY+dd)
BITII           FDCB5E,3,regeiy

; FD CB 66 - BIT 4,(IY+dd)
BITII           FDCB66,4,regeiy

; FD CB 6E - BIT 5,(IY+dd)
BITII           FDCB6E,5,regeiy

; FD CB 76 - BIT 6,(IY+dd)
BITII           FDCB76,6,regeiy

; FD CB 7E - BIT 7,(IY+dd)
BITII           FDCB7E,7,regeiy

; FD CB 46 - RES 0,(IY+dd)
RESII           FDCB86,0,regeiy

; FD CB 4E - RES 1,(IY+dd)
RESII           FDCB8E,1,regeiy

; FD CB 56 - RES 2,(IY+dd)
RESII           FDCB96,2,regeiy

; FD CB 5E - RES 3,(IY+dd)
RESII           FDCB9E,3,regeiy

; FD CB 66 - RES 4,(IY+dd)
RESII           FDCBA6,4,regeiy

; FD CB 6E - RES 5,(IY+dd)
RESII           FDCBAE,5,regeiy

; FD CB 76 - RES 6,(IY+dd)
RESII           FDCBB6,6,regeiy

; FD CB 7E - RES 7,(IY+dd)
RESII           FDCBBE,7,regeiy

; FD CB 46 - SET 0,(IY+dd)
SETII           FDCBC6,0,regeiy

; FD CB 4E - SET 1,(IY+dd)
SETII           FDCBCE,1,regeiy

; FD CB 56 - SET 2,(IY+dd)
SETII           FDCBD6,2,regeiy

; FD CB 5E - SET 3,(IY+dd)
SETII           FDCBDE,3,regeiy

; FD CB 66 - SET 4,(IY+dd)
SETII           FDCBE6,4,regeiy

; FD CB 6E - SET 5,(IY+dd)
SETII           FDCBEE,5,regeiy

; FD CB 76 - SET 6,(IY+dd)
SETII           FDCBF6,6,regeiy

; FD CB 7E - SET 7,(IY+dd)
SETII           FDCBFE,7,regeiy


code32          ends
                end


