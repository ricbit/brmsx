; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: COMPILER.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc
include cfetch.inc
include flags.inc
include io.inc
include vdp.inc
include z80sing.inc

extrn compbuffer: dword
extrn dirtycode: dword
extrn start_counter: near
extrn end_counter: near

extrn info_table_cb: byte
extrn info_table_ed: byte

public compile_pipeline
public nextopcode

; DATA ---------------------------------------------------------------

include copcode.inc

align 4

include info.inc

nextopcode      dd      0

; --------------------------------------------------------------------

ENDOPCODE       macro   opcode

comp&opcode&_end:

                endm

; compile_pipeline ---------------------------------------------------
; this is the main compile pipeline

compile_pipeline:
                
                mov     edi,regepc
                mov     edx,regeaf
                mov     eax,0
                mov     exit_now,eax
                mov     error,eax
                mov     ebp,59659

compile_loop:

                mov     esi,dirtycode
                mov     al,[esi+edi*8]
                or      al,al
                jnz     compile_already

                mov     byte ptr [esi+edi*8],1
                mov     ebx,nextopcode
                mov     dword ptr [esi+edi*8+4],ebx

                push    ebx
                call    fetch

                cmp     al,0CBh
                je      compile_cb

                cmp     al,0EDh
                je      compile_ed

                cmp     al,018h
                je      compile_18

                jmp     compile_single

compile_18:
                call    fetch1
                cmp     al,0FEh
                jne     compile_18a
                
                push    edi
                mov     esi,offset comp18_alt
                mov     edi,nextopcode
                mov     ecx,(offset comp18_alt_end)-(offset comp18_alt)
                rep     movsb
                mov     byte ptr [edi],0C3h
                inc     edi
                mov     nextopcode,edi
                pop     edi
                pop     ebx
                mov     esi,0
                jmp     compile_done

compile_18a:
                mov     al,018h
                jmp     compile_single

compile_cb:                
                call    fetch1
                push    edi
                mov     esi,dword ptr [offset info_table_cb+eax*8]
                mov     edi,nextopcode
                movzx   ecx,byte ptr [offset info_table_cb+eax*8+4]
                rep     movsb
                mov     byte ptr [edi],0C3h
                inc     edi
                mov     nextopcode,edi
                pop     edi
                pop     ebx
                movzx   esi,byte ptr [offset info_table_cb+eax*8+5]
                jmp     compile_done

compile_ed:                
                call    fetch1
                push    edi
                mov     esi,dword ptr [offset info_table_ed+eax*8]
                mov     edi,nextopcode
                movzx   ecx,byte ptr [offset info_table_ed+eax*8+4]
                rep     movsb
                mov     byte ptr [edi],0C3h
                inc     edi
                mov     nextopcode,edi
                pop     edi
                pop     ebx
                movzx   esi,byte ptr [offset info_table_ed+eax*8+5]
                jmp     compile_done

compile_single:
                push    edi
                mov     esi,dword ptr [offset info_table+eax*8]
                mov     edi,nextopcode
                movzx   ecx,byte ptr [offset info_table+eax*8+4]
                rep     movsb
                mov     byte ptr [edi],0C3h
                inc     edi
                mov     nextopcode,edi
                pop     edi
                pop     ebx

                movzx   esi,byte ptr [offset info_table+eax*8+5]

compile_patch:                
                cmp     esi,FETCHIMM
                je      compile_fetchimm
                cmp     esi,FETCHSIGNAL
                je      compile_fetchsignal
                cmp     esi,FETCHWIMM
                je      compile_fetchwimm
                cmp     esi,FETCHWIMM2
                je      compile_fetchwimm2

                jmp     compile_done

compile_fetchimm:
                push    ebx
                call    fetch1
                pop     ebx
                mov     [ebx+1],al
                jmp     compile_done

compile_fetchsignal:
                push    ebx
                call    fetch1
                pop     ebx
                movsx   ecx,al
                add     ecx,edi
                add     ecx,2
                and     ecx,0FFFFh
                mov     dword ptr [ebx+1],ecx
                jmp     compile_done
                
compile_fetchwimm:
                push    ebx
                call    fetchw1
                pop     ebx
                mov     dword ptr [ebx+1],eax
                mov     eax,0
                jmp     compile_done

compile_fetchwimm2:
                push    ebx
                inc     edi
                call    fetchw1
                dec     edi
                pop     ebx
                mov     dword ptr [ebx+1],eax
                mov     eax,0
                jmp     compile_done

compile_done:                
                mov     esi,dirtycode
compile_already:
                mov     ebx,dword ptr [esi+edi*8+4]
                call    ebx

                cmp     ebp,0
                jg      compile_loop
                
                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                xor     eax,eax

compiler_synch:
                cmp     interrupt,1
                jne     compiler_synch

                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax

                mov     ebp,59659
                mov     interrupt,0
                
                cmp     exit_now,1
                je      compiler_exit

                cmp     error,1
                je      compiler_exit

                cmp     iff1,1
                jne     compile_loop

                mov     iff1,0 
                dec     edi
                and     edi,0ffffh
                call    emulFF
                jmp     compile_loop

compiler_exit:
                mov     regpc,di
                mov     regaf,dx
                ret

; --------------------------------------------------------------------


; 00 - NOP
OPNOP           00
ENDOPCODE       00

; 01 - LD BC,dddd
LDREGWIMM       01,regebc
ENDOPCODE       01

; 02 - LD (BC),A
LDREGWA         02,regebc
ENDOPCODE       02

; 03 - INC BC
INCWREG         03,regbc,6
ENDOPCODE       03

; 04 - INC B
INCREG          04,regb
ENDOPCODE       04

; 05 - DEC B
DECREG          05,regb
ENDOPCODE       05

; 06 - LD B,dd
LDREGIMM        06,regb
ENDOPCODE       06

; 07 - RLCA
OPRLCA          07
ENDOPCODE       07

; 08 - EX AF,AF'
OPEXAFAF        08
ENDOPCODE       08

; 09 - ADD HL,BC
ADDREGWREGW     09,regl,regh,regc,regb,11
ENDOPCODE       09

; 0A - LD A,(BC)
LDAREGW         0A,regebc
ENDOPCODE       0A

; 0B - DEC BC
DECWREG         0B,regbc,6
ENDOPCODE       0B

; 0C - INC C
INCREG          0C,regc
ENDOPCODE       0C

; 0D - DEC C
DECREG          0D,regc
ENDOPCODE       0D

; 0E - LD C,dd
LDREGIMM        0E,regc
ENDOPCODE       0E

; 0F - RRCA
OPRRCA          0F      
ENDOPCODE       0F

; 10 - DJNZ dd
OPDJNZ          10
ENDOPCODE       10

; 11 - LD DE,dddd
LDREGWIMM       11,regede
ENDOPCODE       11

; 12 - LD (DE),A
LDREGWA         12,regede
ENDOPCODE       12

; 13 - INC DE
INCWREG         13,regde,6
ENDOPCODE       13

; 14 - INC D
INCREG          14,regd
ENDOPCODE       14

; 15 - DEC D
DECREG          15,regd
ENDOPCODE       15

; 16 - LD D,dd
LDREGIMM        16,regd
ENDOPCODE       16

; 17 - RLA
OPRLA           17
ENDOPCODE       17

; 18 - JR dd
OPJR            18
ENDOPCODE       18

; 19 - ADD HL,DE
ADDREGWREGW     19,regl,regh,rege,regd,11
ENDOPCODE       19

; 1A - LD A,(DE)
LDAREGW         1A,regede
ENDOPCODE       1A

; 1B - DEC DE
DECWREG         1B,regde,6
ENDOPCODE       1B

; 1C - INC E
INCREG          1C,rege
ENDOPCODE       1C

; 1D - DEC E
DECREG          1D,rege
ENDOPCODE       1D

; 1E - LD E,dd
LDREGIMM        1E,rege
ENDOPCODE       1E

; 1F - RRA
OPRRA           1F
ENDOPCODE       1F

; 20 - JR NZ,dd
JRCC            20,jnz,ZERO_FLAG
ENDOPCODE       20

; 21 - LD HL,dddd
LDREGWIMM       21,regehl
ENDOPCODE       21

; 22 - LD (dddd),HL
LDDDDDREGW      22,regehl
ENDOPCODE       22

; 23 - INC HL
INCWREG         23,reghl,6
ENDOPCODE       23

; 24 - INC H
INCREG          24,regh
ENDOPCODE       24

; 25 - DEC H
DECREG          25,regh
ENDOPCODE       25

; 26 - LD H,dd
LDREGIMM        26,regh
ENDOPCODE       26

; 27 - DAA
OPDAA           27
ENDOPCODE       27

; 28 - JR Z,dd
JRCC            28,jz,ZERO_FLAG
ENDOPCODE       28

; 29 - ADD HL,HL
ADDREGWREGW     29,regl,regh,regl,regh,11
ENDOPCODE       29

; 2A - LD HL,(dddd)
LDREGWDDDD      2A,regehl
ENDOPCODE       2A

; 2B - DEC HL
DECWREG         2B,reghl,6
ENDOPCODE       2B

; 2C - INC L
INCREG          2C,regl
ENDOPCODE       2C

; 2D - DEC L
DECREG          2D,regl
ENDOPCODE       2D

; 2E - LD L,dd
LDREGIMM        2E,regl
ENDOPCODE       2E

; 2F - CPL
OPCPL           2F
ENDOPCODE       2F

; 30 - JR NC,dd
JRCC            30,jnz,CARRY_FLAG
ENDOPCODE       30

; 31 - LD SP,dddd
LDREGWIMM       31,regesp
ENDOPCODE       31

; 32 - LD (dddd),A
LDINDA          32
ENDOPCODE       32

; 33 - INC SP
INCWREG         33,regsp,6
ENDOPCODE       33

; 34 - INC (HL)
INCHL           34
ENDOPCODE       34

; 35 - DEC (HL)
DECHL           35
ENDOPCODE       35

; 36 - LD (HL),dd
LDHLIMM         36
ENDOPCODE       36

; 37 - SCF
OPSCF           37
ENDOPCODE       37

; 38 - JR C,dd
JRCC            38,jz,CARRY_FLAG
ENDOPCODE       38

; 39 - ADD HL,SP
ADDREGWREGW     39,regl,regh,regspl,regsph,11
ENDOPCODE       39

; 3A - LD A,(dddd)
LDAIND          3A
ENDOPCODE       3A

; 3B - DEC SP
DECWREG         3B,regsp,6
ENDOPCODE       3B

; 3C - INC A
INCREG          3C,dh
ENDOPCODE       3C

; 3D - DEC A
DECREG          3D,dh
ENDOPCODE       3D

; 3E - LD A,dd
LDREGIMM        3E,dh
ENDOPCODE       3E

; 3F - CCF
OPCCF           3F
ENDOPCODE       3F

; 40 - LD B,B
LDREGREG        40,regb,regb
ENDOPCODE       40

; 41 - LD B,C
LDREGREG        41,regb,regc
ENDOPCODE       41

; 42 - LD B,D
LDREGREG        42,regb,regd
ENDOPCODE       42

; 43 - LD B,E
LDREGREG        43,regb,rege
ENDOPCODE       43

; 44 - LD B,H
LDREGREG        44,regb,regh
ENDOPCODE       44

; 45 - LD B,L
LDREGREG        45,regb,regl
ENDOPCODE       45

; 46 - LD B,(HL)
LDREGHL         46,regb
ENDOPCODE       46

; 47 - LD B,A
LDREGA          47,regb
ENDOPCODE       47

; 48 - LD C,B
LDREGREG        48,regc,regb
ENDOPCODE       48

; 49 - LD C,C
LDREGREG        49,regc,regc
ENDOPCODE       49

; 4A - LD C,D
LDREGREG        4A,regc,regd
ENDOPCODE       4A

; 4B - LD C,E
LDREGREG        4B,regc,rege
ENDOPCODE       4B

; 4C - LD C,H
LDREGREG        4C,regc,regh
ENDOPCODE       4C

; 4D - LD C,L
LDREGREG        4D,regc,regl
ENDOPCODE       4D

; 4E - LD C,(HL)
LDREGHL         4E,regc
ENDOPCODE       4E

; 4F - LD C,A
LDREGA          4F,regc
ENDOPCODE       4F

; 50 - LD D,B
LDREGREG        50,regd,regb
ENDOPCODE       50

; 51 - LD D,C
LDREGREG        51,regd,regc
ENDOPCODE       51

; 52 - LD D,D
LDREGREG        52,regd,regd
ENDOPCODE       52

; 53 - LD D,E
LDREGREG        53,regd,rege
ENDOPCODE       53

; 54 - LD D,H
LDREGREG        54,regd,regh
ENDOPCODE       54

; 55 - LD D,L
LDREGREG        55,regd,regl
ENDOPCODE       55

; 56 - LD D,(HL)
LDREGHL         56,regd
ENDOPCODE       56

; 57 - LD D,A
LDREGA          57,regd
ENDOPCODE       57

; 58 - LD E,B
LDREGREG        58,rege,regb
ENDOPCODE       58

; 59 - LD E,C
LDREGREG        59,rege,regc
ENDOPCODE       59

; 5A - LD E,D
LDREGREG        5A,rege,regd
ENDOPCODE       5A

; 5B - LD E,E
LDREGREG        5B,rege,rege
ENDOPCODE       5B

; 5C - LD E,H
LDREGREG        5C,rege,regh
ENDOPCODE       5C

; 5D - LD E,L
LDREGREG        5D,rege,regl
ENDOPCODE       5D

; 5E - LD E,(HL)
LDREGHL         5E,rege
ENDOPCODE       5E

; 5F - LD E,A
LDREGA          5F,rege
ENDOPCODE       5F

; 60 - LD H,B
LDREGREG        60,regh,regb
ENDOPCODE       60

; 61 - LD H,C
LDREGREG        61,regh,regc
ENDOPCODE       61

; 62 - LD H,D
LDREGREG        62,regh,regd
ENDOPCODE       62

; 63 - LD H,E
LDREGREG        63,regh,rege
ENDOPCODE       63

; 64 - LD H,H
LDREGREG        64,regh,regh
ENDOPCODE       64

; 65 - LD H,L
LDREGREG        65,regh,regl
ENDOPCODE       65

; 66 - LD H,(HL)
LDREGHL         66,regh
ENDOPCODE       66

; 67 - LD H,A
LDREGA          67,regh
ENDOPCODE       67

; 68 - LD L,B
LDREGREG        68,regl,regb
ENDOPCODE       68

; 69 - LD L,C
LDREGREG        69,regl,regc
ENDOPCODE       69

; 6A - LD L,D
LDREGREG        6A,regl,regd
ENDOPCODE       6A

; 6B - LD L,E
LDREGREG        6B,regl,rege
ENDOPCODE       6B

; 6C - LD L,H
LDREGREG        6C,regl,regh
ENDOPCODE       6C

; 6D - LD L,L
LDREGREG        6D,regl,regl
ENDOPCODE       6D

; 6E - LD L,(HL)
LDREGHL         6E,regl
ENDOPCODE       6E

; 6F - LD L,A
LDREGA          6F,regl
ENDOPCODE       6F

; 70 - LD (HL),B
LDHLREG         70,regb
ENDOPCODE       70

; 71 - LD (HL),C
LDHLREG         71,regc
ENDOPCODE       71

; 72 - LD (HL),D
LDHLREG         72,regd
ENDOPCODE       72

; 73 - LD (HL),E
LDHLREG         73,rege
ENDOPCODE       73

; 74 - LD (HL),H
LDHLREG         74,regh
ENDOPCODE       74

; 75 - LD (HL),L
LDHLREG         75,regl
ENDOPCODE       75

; 76 - HALT
OPHALT          76
ENDOPCODE       76

; 77 - LD (HL),A
LDHLREG         77,dh
ENDOPCODE       77

; 78 - LD A,B
LDAREG          78,regb
ENDOPCODE       78

; 79 - LD A,C
LDAREG          79,regc
ENDOPCODE       79

; 7A - LD A,D
LDAREG          7A,regd
ENDOPCODE       7A

; 7B - LD A,E
LDAREG          7B,rege
ENDOPCODE       7B

; 7C - LD A,H
LDAREG          7C,regh
ENDOPCODE       7C

; 7D - LD A,L
LDAREG          7D,regl
ENDOPCODE       7D

; 7E - LD A,(HL)
LDREGHL         7E,dh
ENDOPCODE       7E

; 7F - LD A,A
LDAREG          7F,dh
ENDOPCODE       7F

; 80 - ADD A,B  
ADDREG          80,regb
ENDOPCODE       80

; 81 - ADD A,C
ADDREG          81,regc
ENDOPCODE       81

; 82 - ADD A,D
ADDREG          82,regd
ENDOPCODE       82

; 83 - ADD A,E
ADDREG          83,rege
ENDOPCODE       83

; 84 - ADD A,H
ADDREG          84,regh
ENDOPCODE       84

; 85 - ADD A,L
ADDREG          85,regl
ENDOPCODE       85

; 86 - ADD A,(HL)
ADDAHL          86
ENDOPCODE       86

; 87 - ADD A,A
ADDREG          87,dh
ENDOPCODE       87

; 88 - ADC A,B
ADCREG          88,regb
ENDOPCODE       88

; 89 - ADC A,C
ADCREG          89,regc
ENDOPCODE       89

; 8A - ADC A,D
ADCREG          8A,regd
ENDOPCODE       8A

; 8B - ADC A,E
ADCREG          8B,rege
ENDOPCODE       8B

; 8C - ADC A,H
ADCREG          8C,regh
ENDOPCODE       8C

; 8D - ADC A,L
ADCREG          8D,regl
ENDOPCODE       8D

; 8E - ADC A,(HL)
ADCAHL          8E
ENDOPCODE       8E

; 8F - ADC A,A
ADCREG          8F,dh
ENDOPCODE       8F

; 90 - SUB B
SUBREG          90,regb
ENDOPCODE       90

; 91 - SUB C
SUBREG          91,regc
ENDOPCODE       91

; 92 - SUB D
SUBREG          92,regd
ENDOPCODE       92

; 93 - SUB E
SUBREG          93,rege
ENDOPCODE       93

; 94 - SUB H
SUBREG          94,regh
ENDOPCODE       94

; 95 - SUB L
SUBREG          95,regl
ENDOPCODE       95

; 96 - SUB (HL)
SUBAHL          96
ENDOPCODE       96

; 97 - SUB A
SUBREG          97,dh
ENDOPCODE       97

; 98 - SBC A,B
SBCREG          98,regb
ENDOPCODE       98

; 99 - SBC A,C
SBCREG          99,regc
ENDOPCODE       99

; 9A - SBC A,D
SBCREG          9A,regd
ENDOPCODE       9A

; 9B - SBC A,E
SBCREG          9B,rege
ENDOPCODE       9B

; 9C - SBC A,H
SBCREG          9C,regh
ENDOPCODE       9C

; 9D - SBC A,L
SBCREG          9D,regl
ENDOPCODE       9D

; 9E - SBC A,(HL)
SBCAHL          9E
ENDOPCODE       9E

; 9F - SBC A,A
SBCREG          9F,dh
ENDOPCODE       9F

; A0 - AND B
ANDREG          A0,regb
ENDOPCODE       A0

; A1 - AND C
ANDREG          A1,regc
ENDOPCODE       A1

; A2 - AND D
ANDREG          A2,regd
ENDOPCODE       A2

; A3 - AND E
ANDREG          A3,rege
ENDOPCODE       A3

; A4 - AND H
ANDREG          A4,regh
ENDOPCODE       A4

; A5 - AND L
ANDREG          A5,regl
ENDOPCODE       A5

; A6 - AND (HL)
ANDHL           A6
ENDOPCODE       A6

; A7 - AND A
ANDREG          A7,dh
ENDOPCODE       A7

; A8 - XOR B
XORREG          A8,regb
ENDOPCODE       A8

; A9 - XOR C
XORREG          A9,regc
ENDOPCODE       A9

; AA - XOR D
XORREG          AA,regd
ENDOPCODE       AA

; AB - XOR E
XORREG          AB,rege
ENDOPCODE       AB

; AC - XOR H
XORREG          AC,regh
ENDOPCODE       AC

; AD - XOR L
XORREG          AD,regl
ENDOPCODE       AD

; AE - XOR (HL)
XORHL           AE
ENDOPCODE       AE

; AF - XOR A
XORREG          AF,dh
ENDOPCODE       AF
                
; B0 - OR B
ORREG           B0,regb
ENDOPCODE       B0

; B1 - OR C
ORREG           B1,regc
ENDOPCODE       B1

; B2 - OR D
ORREG           B2,regd
ENDOPCODE       B2

; B3 - OR E
ORREG           B3,rege
ENDOPCODE       B3

; B4 - OR H
ORREG           B4,regh
ENDOPCODE       B4

; B5 - OR L
ORREG           B5,regl
ENDOPCODE       B5

; B6 - OR (HL)
ORHL            B6
ENDOPCODE       B6

; B7 - OR A
ORREG           B7,dh
ENDOPCODE       B7

; B8 - CP B
CPREG           B8,regb
ENDOPCODE       B8

; B9 - CP C
CPREG           B9,regc
ENDOPCODE       B9

; BA - CP D
CPREG           BA,regd
ENDOPCODE       BA

; BB - CP E
CPREG           BB,rege
ENDOPCODE       BB

; BC - CP H
CPREG           BC,regh
ENDOPCODE       BC

; BD - CP L
CPREG           BD,regl
ENDOPCODE       BD

; BE - CP (HL)
CPAHL           BE
ENDOPCODE       BE

; BF - CP A
CPREG           BF,dh
ENDOPCODE       BF

; C0 - RET NZ
RETCC           C0,ZERO_FLAG,jz
ENDOPCODE       C0

; C1 - POP BC
POPREGW         C1,regebc
ENDOPCODE       C1

; C2 - JP NZ,dddd
JPCC            C2,jnz,ZERO_FLAG
ENDOPCODE       C2

; C3 - JP dddd
OPJP            C3
ENDOPCODE       C3

; C4 - CALL NZ,dddd
CALLCC          C4,ZERO_FLAG,jz
ENDOPCODE       C4

; C5 - PUSH BC
PUSHREGW        C5,regebc
ENDOPCODE       C5

; C6 - ADD A,dd
ADDIMM          C6
ENDOPCODE       C6

; C8 - RET Z
RETCC           C8,ZERO_FLAG,jnz
ENDOPCODE       C8

; C9 - RET
OPRET           C9
ENDOPCODE       C9

; CA - JP Z,dddd
JPCC            CA,jz,ZERO_FLAG
ENDOPCODE       CA

; CB - group CB
compCB:
                mov     ebx,offset emulCB
                call    ebx
ENDOPCODE       CB

; CC - CALL Z,dddd
CALLCC          CC,ZERO_FLAG,jnz
ENDOPCODE       CC

; CD - CALL dddd
OPCALL          CD
ENDOPCODE       CD

; CE - ADC A,dd
ADCIMM          CE
ENDOPCODE       CE

; CF - RST 08
OPRST           CF,08h
ENDOPCODE       CF

; D0 - RET NC
RETCC           D0,CARRY_FLAG,jz
ENDOPCODE       D0

; D1 - POP DE
POPREGW         D1,regede
ENDOPCODE       D1

; D2 - JP NC,dddd
JPCC            D2,jnz,CARRY_FLAG
ENDOPCODE       D2

; D3 - OUT (dd),A
OUTIMM          D3
ENDOPCODE       D3

; D4 - CALL NC,dddd
CALLCC          D4,CARRY_FLAG,jz
ENDOPCODE       D4

; D5 - PUSH DE
PUSHREGW        D5,regede
ENDOPCODE       D5

; D6 - SUB dd
SUBIMM          D6
ENDOPCODE       D6

; D7 - RST 10
OPRST           D7,010h
ENDOPCODE       D7

; D8 - RET C
RETCC           D8,CARRY_FLAG,jnz
ENDOPCODE       D8

; D9 - EXX
OPEXX           D9
ENDOPCODE       D9

; DA - JP C,dddd
JPCC            DA,jz,CARRY_FLAG
ENDOPCODE       DA

; DB - IN A,(dd)
INADD           DB
ENDOPCODE       DB

; DC - CALL C,dddd 
CALLCC          DC,CARRY_FLAG,jnz
ENDOPCODE       DC

; DD - group DD
compDD:
                mov     ebx,offset emulDD
                call    ebx
ENDOPCODE       DD

; DE - SBC A,dd
SBCIMM          DE
ENDOPCODE       DE

; DF - RST 18
OPRST           DF,018h
ENDOPCODE       DF

; E0 - RET PO
RETCC           E0,PARITY_FLAG,jz
ENDOPCODE       E0

; E1 - POP HL
POPREGW         E1,regehl
ENDOPCODE       E1

; E2 - JP PO,dddd
JPCC            E2,jnz,PARITY_FLAG
ENDOPCODE       E2

; E3 - EX (SP),HL
OPEXSPREGW      E3,regehl
ENDOPCODE       E3

; E4 - CALL PO,dddd
CALLCC          E4,PARITY_FLAG,jz
ENDOPCODE       E4

; E5 - PUSH HL
PUSHREGW        E5,regehl
ENDOPCODE       E5

; E6 - AND dd
ANDIMM          E6
ENDOPCODE       E6

; E7 - RST 20
OPRST           E7,020h
ENDOPCODE       E7

; E8 - RET PE
RETCC           E8,PARITY_FLAG,jnz
ENDOPCODE       E8

; E9 - JP (HL)
OPJPREGW        E9,regehl
ENDOPCODE       E9

; EA - JP PE,dddd
JPCC            EA,jz,PARITY_FLAG
ENDOPCODE       EA

; EB - EX DE,HL
OPEXDEHL        EB                
ENDOPCODE       EB

; EC - CALL PE,dddd
CALLCC          EC,PARITY_FLAG,jnz
ENDOPCODE       EC

; ED - group ED
compED:
                mov     ebx,offset emulED
                call    ebx
ENDOPCODE       ED

; EE - XOR dd
XORIMM          EE
ENDOPCODE       EE

; EF - RST 28
OPRST           EF,028h
ENDOPCODE       EF

; F0 - RET P
RETCC           F0,SIGN_FLAG,jz
ENDOPCODE       F0

; F1 - POP AF
POPREGW         F1,edx
ENDOPCODE       F1

; F2 - JP P,dddd
JPCC            F2,jnz,SIGN_FLAG
ENDOPCODE       F2

; F3 - DI
OPDI            F3
ENDOPCODE       F3

; F4 - CALL P,dddd
CALLCC          F4,SIGN_FLAG,jz
ENDOPCODE       F4

; F5 - PUSH AF
PUSHREGW        F5,edx
ENDOPCODE       F5

; F6 - OR dd
ORIMM           F6
ENDOPCODE       F6

; F7 - RST 30
OPRST           F7,030h
ENDOPCODE       F7

; F8 - RET M
RETCC           F8,SIGN_FLAG,jnz
ENDOPCODE       F8

; F9 - LD SP,HL
LDSPREGW        F9,regehl
ENDOPCODE       F9

; FA - JP M,dddd
JPCC            FA,jz,SIGN_FLAG
ENDOPCODE       FA

; FB - EI
OPEI            FB      
ENDOPCODE       FB

; FC - CALL M,dddd
CALLCC          FC,SIGN_FLAG,jnz
ENDOPCODE       FC

; FD - group FD
compFD:
                mov     ebx,offset emulFD
                call    ebx
ENDOPCODE       FD

; FE - CP dd
CPIMM           FE
ENDOPCODE       FE

; FF - RST 38
OPRST           FF,038h
ENDOPCODE       FF

comp18_alt:
                mov     ebp,0
comp18_alt_end:


code32          ends
                end


