; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: COMPCB.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include copcode.inc
include bit.inc
include cfetch.inc

public info_table_cb

; DATA ---------------------------------------------------------------

align 4

include infocb.inc

; --------------------------------------------------------------------

ENDOPCODE       macro   opcode

comp&opcode&_end:

                endm

; --------------------------------------------------------------------

; CB 00 - RLC B
RLCREG          CB00,regb
ENDOPCODE       CB00

; CB 01 - RLC C
RLCREG          CB01,regc
ENDOPCODE       CB01

; CB 02 - RLC D
RLCREG          CB02,regd
ENDOPCODE       CB02

; CB 03 - RLC E
RLCREG          CB03,rege
ENDOPCODE       CB03

; CB 04 - RLC H
RLCREG          CB04,regh
ENDOPCODE       CB04

; CB 05 - RLC L
RLCREG          CB05,regl
ENDOPCODE       CB05

; CB 06 - RLC (HL)
RLCHL           CB06
ENDOPCODE       CB06

; CB 07 - RLC A
RLCREG          CB07,dh
ENDOPCODE       CB07

; CB 08 - RRC B
RRCREG          CB08,regb
ENDOPCODE       CB08

; CB 09 - RRC C
RRCREG          CB09,regc
ENDOPCODE       CB09

; CB 0A - RRC D
RRCREG          CB0A,regd
ENDOPCODE       CB0A

; CB 0B - RRC E
RRCREG          CB0B,rege
ENDOPCODE       CB0B

; CB 0C - RRC H
RRCREG          CB0C,regh
ENDOPCODE       CB0C

; CB 0D - RRC L
RRCREG          CB0D,regl
ENDOPCODE       CB0D

; CB 0E - RRC (HL)
RRCHL           CB0E
ENDOPCODE       CB0E

; CB 0F - RRC A
RRCREG          CB0F,dh
ENDOPCODE       CB0F

; CB 10 - RL B
RLREG           CB10,regb
ENDOPCODE       CB10

; CB 11 - RL C
RLREG           CB11,regc
ENDOPCODE       CB11

; CB 12 - RL D
RLREG           CB12,regd
ENDOPCODE       CB12

; CB 13 - RL E
RLREG           CB13,rege
ENDOPCODE       CB13

; CB 14 - RL H
RLREG           CB14,regh
ENDOPCODE       CB14

; CB 15 - RL L
RLREG           CB15,regl
ENDOPCODE       CB15

; CB 16 - RL (HL)
RLHL            CB16
ENDOPCODE       CB16

; CB 17 - RL A
RLREG           CB17,dh
ENDOPCODE       CB17

; CB 18 - RR B
RRREG           CB18,regb
ENDOPCODE       CB18

; CB 19 - RR C
RRREG           CB19,regc
ENDOPCODE       CB19

; CB 1A - RR D
RRREG           CB1A,regd
ENDOPCODE       CB1A

; CB 1B - RR E
RRREG           CB1B,rege
ENDOPCODE       CB1B

; CB 1C - RR H
RRREG           CB1C,regh
ENDOPCODE       CB1C

; CB 1D - RR L
RRREG           CB1D,regl
ENDOPCODE       CB1D

; CB 1E - RR (HL)
RRHL            CB1E
ENDOPCODE       CB1E

; CB 1F - RR A
RRREG           CB1F,dh
ENDOPCODE       CB1F

; CB 20 - SLA B
SLAREG          CB20,regb
ENDOPCODE       CB20

; CB 21 - SLA C
SLAREG          CB21,regc
ENDOPCODE       CB21

; CB 22 - SLA D
SLAREG          CB22,regd
ENDOPCODE       CB22

; CB 23 - SLA E
SLAREG          CB23,rege
ENDOPCODE       CB23

; CB 24 - SLA H
SLAREG          CB24,regh
ENDOPCODE       CB24

; CB 25 - SLA L
SLAREG          CB25,regl
ENDOPCODE       CB25

; CB 26 - SLA (HL)
SLAHL           CB26
ENDOPCODE       CB26

; CB 27 - SLA A
SLAREG          CB27,dh
ENDOPCODE       CB27

; CB 28 - SRA B
SRAREG          CB28,regb
ENDOPCODE       CB28

; CB 29 - SRA C
SRAREG          CB29,regc
ENDOPCODE       CB29

; CB 2A - SRA D
SRAREG          CB2A,regd
ENDOPCODE       CB2A

; CB 2B - SRA E
SRAREG          CB2B,rege
ENDOPCODE       CB2B

; CB 2C - SRA H
SRAREG          CB2C,regh
ENDOPCODE       CB2C

; CB 2D - SRA L
SRAREG          CB2D,regl
ENDOPCODE       CB2D

; CB 2E - SRA (HL)
SRAHL           CB2E
ENDOPCODE       CB2E

; CB 2F - SRA A
SRAREG          CB2F,dh
ENDOPCODE       CB2F

; CB 38 - SRL B
SRLREG          CB38,regb
ENDOPCODE       CB38

; CB 39 - SRL C
SRLREG          CB39,regc
ENDOPCODE       CB39

; CB 3A - SRL D
SRLREG          CB3A,regd
ENDOPCODE       CB3A

; CB 3B - SRL E
SRLREG          CB3B,rege
ENDOPCODE       CB3B

; CB 3C - SRL H
SRLREG          CB3C,regh
ENDOPCODE       CB3C

; CB 3D - SRL L
SRLREG          CB3D,regl
ENDOPCODE       CB3D

; CB 3E - SRL (HL)
SRLHL           CB3E
ENDOPCODE       CB3E

; CB 3F - SRL A
SRLREG          CB3F,dh
ENDOPCODE       CB3F

; CB 40 - BIT 0,B
BITREG          CB40,regb,0
ENDOPCODE       CB40

; CB 41 - BIT 0,C
BITREG          CB41,regc,0
ENDOPCODE       CB41

; CB 42 - BIT 0,D
BITREG          CB42,regd,0
ENDOPCODE       CB42

; CB 43 - BIT 0,E
BITREG          CB43,rege,0
ENDOPCODE       CB43

; CB 44 - BIT 0,H
BITREG          CB44,regh,0
ENDOPCODE       CB44

; CB 45 - BIT 0,L
BITREG          CB45,regl,0
ENDOPCODE       CB45

; CB 46 - BIT 0,(HL)
BITHL           CB46,0
ENDOPCODE       CB46

; CB 47 - BIT 0,A
BITREG          CB47,dh,0
ENDOPCODE       CB47

; CB 48 - BIT 1,B
BITREG          CB48,regb,1
ENDOPCODE       CB48

; CB 49 - BIT 1,C
BITREG          CB49,regc,1
ENDOPCODE       CB49

; CB 4A - BIT 1,D
BITREG          CB4A,regd,1
ENDOPCODE       CB4A

; CB 4B - BIT 1,E
BITREG          CB4B,rege,1
ENDOPCODE       CB4B

; CB 4C - BIT 1,H
BITREG          CB4C,regh,1
ENDOPCODE       CB4C

; CB 4D - BIT 1,L
BITREG          CB4D,regl,1
ENDOPCODE       CB4D

; CB 4E - BIT 1,(HL)
BITHL           CB4E,1
ENDOPCODE       CB4E

; CB 4F - BIT 1,A
BITREG          CB4F,dh,1
ENDOPCODE       CB4F

; CB 50 - BIT 2,B
BITREG          CB50,regb,2
ENDOPCODE       CB50

; CB 51 - BIT 2,C
BITREG          CB51,regc,2
ENDOPCODE       CB51

; CB 52 - BIT 2,D
BITREG          CB52,regd,2
ENDOPCODE       CB52

; CB 53 - BIT 2,E
BITREG          CB53,rege,2
ENDOPCODE       CB53

; CB 54 - BIT 2,H
BITREG          CB54,regh,2
ENDOPCODE       CB54

; CB 55 - BIT 2,L
BITREG          CB55,regl,2
ENDOPCODE       CB55

; CB 56 - BIT 2,(HL)
BITHL           CB56,2
ENDOPCODE       CB56

; CB 57 - BIT 2,A
BITREG          CB57,dh,2
ENDOPCODE       CB57

; CB 58 - BIT 3,B
BITREG          CB58,regb,3
ENDOPCODE       CB58

; CB 59 - BIT 3,C
BITREG          CB59,regc,3
ENDOPCODE       CB59

; CB 5A - BIT 3,D
BITREG          CB5A,regd,3
ENDOPCODE       CB5A

; CB 5B - BIT 3,E
BITREG          CB5B,rege,3
ENDOPCODE       CB5B

; CB 5C - BIT 3,H
BITREG          CB5C,regh,3
ENDOPCODE       CB5C

; CB 5D - BIT 3,L
BITREG          CB5D,regl,3
ENDOPCODE       CB5D

; CB 5E - BIT 3,(HL)
BITHL           CB5E,3
ENDOPCODE       CB5E

; CB 5F - BIT 3,A
BITREG          CB5F,dh,3
ENDOPCODE       CB5F

; CB 60 - BIT 4,B
BITREG          CB60,regb,4
ENDOPCODE       CB60

; CB 61 - BIT 4,C
BITREG          CB61,regc,4
ENDOPCODE       CB61

; CB 62 - BIT 4,D
BITREG          CB62,regd,4
ENDOPCODE       CB62

; CB 63 - BIT 4,E
BITREG          CB63,rege,4
ENDOPCODE       CB63

; CB 64 - BIT 4,H
BITREG          CB64,regh,4
ENDOPCODE       CB64

; CB 65 - BIT 4,L
BITREG          CB65,regl,4
ENDOPCODE       CB65

; CB 66 - BIT 4,(HL)
BITHL           CB66,4
ENDOPCODE       CB66

; CB 67 - BIT 4,A
BITREG          CB67,dh,4
ENDOPCODE       CB67

; CB 68 - BIT 5,B
BITREG          CB68,regb,5
ENDOPCODE       CB68

; CB 69 - BIT 5,C
BITREG          CB69,regc,5
ENDOPCODE       CB69

; CB 6A - BIT 5,D
BITREG          CB6A,regd,5
ENDOPCODE       CB6A

; CB 6B - BIT 5,E
BITREG          CB6B,rege,5
ENDOPCODE       CB6B

; CB 6C - BIT 5,H
BITREG          CB6C,regh,5
ENDOPCODE       CB6C

; CB 6D - BIT 5,L
BITREG          CB6D,regl,5
ENDOPCODE       CB6D

; CB 6E - BIT 5,(HL)
BITHL           CB6E,5
ENDOPCODE       CB6E

; CB 6F - BIT 5,A
BITREG          CB6F,dh,5
ENDOPCODE       CB6F

; CB 70 - BIT 6,B
BITREG          CB70,regb,6
ENDOPCODE       CB70

; CB 71 - BIT 6,C
BITREG          CB71,regc,6
ENDOPCODE       CB71

; CB 72 - BIT 6,D
BITREG          CB72,regd,6
ENDOPCODE       CB72

; CB 73 - BIT 6,E
BITREG          CB73,rege,6
ENDOPCODE       CB73

; CB 74 - BIT 6,H
BITREG          CB74,regh,6
ENDOPCODE       CB74

; CB 75 - BIT 6,L
BITREG          CB75,regl,6
ENDOPCODE       CB75

; CB 76 - BIT 6,(HL)
BITHL           CB76,6
ENDOPCODE       CB76

; CB 77 - BIT 6,A
BITREG          CB77,dh,6
ENDOPCODE       CB77

; CB 78 - BIT 7,B
BITREG          CB78,regb,7
ENDOPCODE       CB78

; CB 79 - BIT 7,C
BITREG          CB79,regc,7
ENDOPCODE       CB79

; CB 7A - BIT 7,D
BITREG          CB7A,regd,7
ENDOPCODE       CB7A

; CB 7B - BIT 7,E
BITREG          CB7B,rege,7
ENDOPCODE       CB7B

; CB 7C - BIT 7,H
BITREG          CB7C,regh,7
ENDOPCODE       CB7C

; CB 7D - BIT 7,L
BITREG          CB7D,regl,7
ENDOPCODE       CB7D

; CB 7E - BIT 7,(HL)
BITHL           CB7E,7
ENDOPCODE       CB7E

; CB 7F - BIT 7,A
BITREG          CB7F,dh,7
ENDOPCODE       CB7F

; CB 80 - RES 0,B
RESREG          CB80,regb,0
ENDOPCODE       CB80

; CB 81 - RES 0,C
RESREG          CB81,regc,0
ENDOPCODE       CB81

; CB 82 - RES 0,D
RESREG          CB82,regd,0
ENDOPCODE       CB82

; CB 83 - RES 0,E
RESREG          CB83,rege,0
ENDOPCODE       CB83

; CB 84 - RES 0,H
RESREG          CB84,regh,0
ENDOPCODE       CB84

; CB 85 - RES 0,L
RESREG          CB85,regl,0
ENDOPCODE       CB85

; CB 86 - RES 0,(HL)
RESHL           CB86,0
ENDOPCODE       CB86

; CB 87 - RES 0,A
RESREG          CB87,dh,0
ENDOPCODE       CB87

; CB 88 - RES 1,B
RESREG          CB88,regb,1
ENDOPCODE       CB88

; CB 89 - RES 1,C
RESREG          CB89,regc,1
ENDOPCODE       CB89

; CB 8A - RES 1,D
RESREG          CB8A,regd,1
ENDOPCODE       CB8A

; CB 8B - RES 1,E
RESREG          CB8B,rege,1
ENDOPCODE       CB8B

; CB 8C - RES 1,H
RESREG          CB8C,regh,1
ENDOPCODE       CB8C

; CB 8D - RES 1,L
RESREG          CB8D,regl,1
ENDOPCODE       CB8D

; CB 8E - RES 1,(HL)
RESHL           CB8E,1
ENDOPCODE       CB8E

; CB 8F - RES 1,A
RESREG          CB8F,dh,1
ENDOPCODE       CB8F

; CB 90 - RES 2,B
RESREG          CB90,regb,2
ENDOPCODE       CB90

; CB 91 - RES 2,C
RESREG          CB91,regc,2
ENDOPCODE       CB91

; CB 92 - RES 2,D
RESREG          CB92,regd,2
ENDOPCODE       CB92

; CB 93 - RES 2,E
RESREG          CB93,rege,2
ENDOPCODE       CB93

; CB 94 - RES 2,H
RESREG          CB94,regh,2
ENDOPCODE       CB94

; CB 95 - RES 2,L
RESREG          CB95,regl,2
ENDOPCODE       CB95

; CB 96 - RES 2,(HL)
RESHL           CB96,2
ENDOPCODE       CB96

; CB 97 - RES 2,A
RESREG          CB97,dh,2
ENDOPCODE       CB97

; CB 98 - RES 3,B
RESREG          CB98,regb,3
ENDOPCODE       CB98

; CB 99 - RES 3,C
RESREG          CB99,regc,3
ENDOPCODE       CB99

; CB 9A - RES 3,D
RESREG          CB9A,regd,3
ENDOPCODE       CB9A

; CB 9B - RES 3,E
RESREG          CB9B,rege,3
ENDOPCODE       CB9B

; CB 9C - RES 3,H
RESREG          CB9C,regh,3
ENDOPCODE       CB9C

; CB 9D - RES 3,L
RESREG          CB9D,regl,3
ENDOPCODE       CB9D

; CB 9E - RES 3,(HL)
RESHL           CB9E,3
ENDOPCODE       CB9E

; CB 9F - RES 3,A
RESREG          CB9F,dh,3
ENDOPCODE       CB9F

; CB A0 - RES 4,B
RESREG          CBA0,regb,4
ENDOPCODE       CBA0

; CB A1 - RES 4,C
RESREG          CBA1,regc,4
ENDOPCODE       CBA1

; CB A2 - RES 4,D
RESREG          CBA2,regd,4
ENDOPCODE       CBA2

; CB A3 - RES 4,E
RESREG          CBA3,rege,4
ENDOPCODE       CBA3

; CB A4 - RES 4,H
RESREG          CBA4,regh,4
ENDOPCODE       CBA4

; CB A5 - RES 4,L
RESREG          CBA5,regl,4
ENDOPCODE       CBA5

; CB A6 - RES 4,(HL)
RESHL           CBA6,4
ENDOPCODE       CBA6

; CB A7 - RES 4,A
RESREG          CBA7,dh,4
ENDOPCODE       CBA7

; CB A8 - RES 5,B
RESREG          CBA8,regb,5
ENDOPCODE       CBA8

; CB A9 - RES 5,C
RESREG          CBA9,regc,5
ENDOPCODE       CBA9

; CB AA - RES 5,D
RESREG          CBAA,regd,5
ENDOPCODE       CBAA

; CB AB - RES 5,E
RESREG          CBAB,rege,5
ENDOPCODE       CBAB

; CB AC - RES 5,H
RESREG          CBAC,regh,5
ENDOPCODE       CBAC

; CB AD - RES 5,L
RESREG          CBAD,regl,5
ENDOPCODE       CBAD

; CB AE - RES 5,(HL)
RESHL           CBAE,5
ENDOPCODE       CBAE

; CB AF - RES 5,A
RESREG          CBAF,dh,5
ENDOPCODE       CBAF

; CB B0 - RES 6,B
RESREG          CBB0,regb,6
ENDOPCODE       CBB0

; CB B1 - RES 6,C
RESREG          CBB1,regc,6
ENDOPCODE       CBB1

; CB B2 - RES 6,D
RESREG          CBB2,regd,6
ENDOPCODE       CBB2

; CB B3 - RES 6,E
RESREG          CBB3,rege,6
ENDOPCODE       CBB3

; CB B4 - RES 6,H
RESREG          CBB4,regh,6
ENDOPCODE       CBB4

; CB B5 - RES 6,L
RESREG          CBB5,regl,6
ENDOPCODE       CBB5

; CB B6 - RES 6,(HL)
RESHL           CBB6,6
ENDOPCODE       CBB6

; CB B7 - RES 6,A
RESREG          CBB7,dh,6
ENDOPCODE       CBB7

; CB B8 - RES 7,B
RESREG          CBB8,regb,7
ENDOPCODE       CBB8

; CB B9 - RES 7,C
RESREG          CBB9,regc,7
ENDOPCODE       CBB9

; CB BA - RES 7,D
RESREG          CBBA,regd,7
ENDOPCODE       CBBA

; CB BB - RES 7,E
RESREG          CBBB,rege,7
ENDOPCODE       CBBB

; CB BC - RES 7,H
RESREG          CBBC,regh,7
ENDOPCODE       CBBC

; CB BD - RES 7,L
RESREG          CBBD,regl,7
ENDOPCODE       CBBD

; CB BE - RES 7,(HL)
RESHL           CBBE,7
ENDOPCODE       CBBE

; CB BF - RES 7,A
RESREG          CBBF,dh,7
ENDOPCODE       CBBF

; CB C0 - SET 0,B
SETREG          CBC0,regb,0
ENDOPCODE       CBC0

; CB C1 - SET 0,C
SETREG          CBC1,regc,0
ENDOPCODE       CBC1

; CB C2 - SET 0,D
SETREG          CBC2,regd,0
ENDOPCODE       CBC2

; CB C3 - SET 0,E
SETREG          CBC3,rege,0
ENDOPCODE       CBC3

; CB C4 - SET 0,H
SETREG          CBC4,regh,0
ENDOPCODE       CBC4

; CB C5 - SET 0,L
SETREG          CBC5,regl,0
ENDOPCODE       CBC5

; CB C6 - SET 0,(HL)
SETHL           CBC6,0
ENDOPCODE       CBC6

; CB C7 - SET 0,A
SETREG          CBC7,dh,0
ENDOPCODE       CBC7

; CB C8 - SET 1,B
SETREG          CBC8,regb,1
ENDOPCODE       CBC8

; CB C9 - SET 1,C
SETREG          CBC9,regc,1
ENDOPCODE       CBC9

; CB CA - SET 1,D
SETREG          CBCA,regd,1
ENDOPCODE       CBCA

; CB CB - SET 1,E
SETREG          CBCB,rege,1
ENDOPCODE       CBCB

; CB CC - SET 1,H
SETREG          CBCC,regh,1
ENDOPCODE       CBCC

; CB CD - SET 1,L
SETREG          CBCD,regl,1
ENDOPCODE       CBCD

; CB CE - SET 1,(HL)
SETHL           CBCE,1
ENDOPCODE       CBCE

; CB CF - SET 1,A
SETREG          CBCF,dh,1
ENDOPCODE       CBCF

; CB D0 - SET 2,B
SETREG          CBD0,regb,2
ENDOPCODE       CBD0

; CB D1 - SET 2,C
SETREG          CBD1,regc,2
ENDOPCODE       CBD1

; CB D2 - SET 2,D
SETREG          CBD2,regd,2
ENDOPCODE       CBD2

; CB D3 - SET 2,E
SETREG          CBD3,rege,2
ENDOPCODE       CBD3

; CB D4 - SET 2,H
SETREG          CBD4,regh,2
ENDOPCODE       CBD4

; CB D5 - SET 2,L
SETREG          CBD5,regl,2
ENDOPCODE       CBD5

; CB D6 - SET 2,(HL)
SETHL           CBD6,2
ENDOPCODE       CBD6

; CB D7 - SET 2,A
SETREG          CBD7,dh,2
ENDOPCODE       CBD7

; CB D8 - SET 3,B
SETREG          CBD8,regb,3
ENDOPCODE       CBD8

; CB D9 - SET 3,C
SETREG          CBD9,regc,3
ENDOPCODE       CBD9

; CB DA - SET 3,D
SETREG          CBDA,regd,3
ENDOPCODE       CBDA

; CB DB - SET 3,E
SETREG          CBDB,rege,3
ENDOPCODE       CBDB

; CB DC - SET 3,H
SETREG          CBDC,regh,3
ENDOPCODE       CBDC

; CB DD - SET 3,L
SETREG          CBDD,regl,3
ENDOPCODE       CBDD

; CB DE - SET 3,(HL)
SETHL           CBDE,3
ENDOPCODE       CBDE

; CB DF - SET 3,A
SETREG          CBDF,dh,3
ENDOPCODE       CBDF

; CB E0 - SET 4,B
SETREG          CBE0,regb,4
ENDOPCODE       CBE0

; CB E1 - SET 4,C
SETREG          CBE1,regc,4
ENDOPCODE       CBE1

; CB E2 - SET 4,D
SETREG          CBE2,regd,4
ENDOPCODE       CBE2

; CB E3 - SET 4,E
SETREG          CBE3,rege,4
ENDOPCODE       CBE3

; CB E4 - SET 4,H
SETREG          CBE4,regh,4
ENDOPCODE       CBE4

; CB E5 - SET 4,L
SETREG          CBE5,regl,4
ENDOPCODE       CBE5

; CB E6 - SET 4,(HL)
SETHL           CBE6,4
ENDOPCODE       CBE6

; CB E7 - SET 4,A
SETREG          CBE7,dh,4
ENDOPCODE       CBE7

; CB E8 - SET 5,B
SETREG          CBE8,regb,5
ENDOPCODE       CBE8

; CB E9 - SET 5,C
SETREG          CBE9,regc,5
ENDOPCODE       CBE9

; CB EA - SET 5,D
SETREG          CBEA,regd,5
ENDOPCODE       CBEA

; CB EB - SET 5,E
SETREG          CBEB,rege,5
ENDOPCODE       CBEB

; CB EC - SET 5,H
SETREG          CBEC,regh,5
ENDOPCODE       CBEC

; CB ED - SET 5,L
SETREG          CBED,regl,5
ENDOPCODE       CBED

; CB EE - SET 5,(HL)
SETHL           CBEE,5
ENDOPCODE       CBEE

; CB EF - SET 5,A
SETREG          CBEF,dh,5
ENDOPCODE       CBEF

; CB F0 - SET 6,B
SETREG          CBF0,regb,6
ENDOPCODE       CBF0

; CB F1 - SET 6,C
SETREG          CBF1,regc,6
ENDOPCODE       CBF1

; CB F2 - SET 6,D
SETREG          CBF2,regd,6
ENDOPCODE       CBF2

; CB F3 - SET 6,E
SETREG          CBF3,rege,6
ENDOPCODE       CBF3

; CB F4 - SET 6,H
SETREG          CBF4,regh,6
ENDOPCODE       CBF4

; CB F5 - SET 6,L
SETREG          CBF5,regl,6
ENDOPCODE       CBF5

; CB F6 - SET 6,(HL)
SETHL           CBF6,6
ENDOPCODE       CBF6

; CB F7 - SET 6,A
SETREG          CBF7,dh,6
ENDOPCODE       CBF7

; CB F8 - SET 7,B
SETREG          CBF8,regb,7
ENDOPCODE       CBF8

; CB F9 - SET 7,C
SETREG          CBF9,regc,7
ENDOPCODE       CBF9

; CB FA - SET 7,D
SETREG          CBFA,regd,7
ENDOPCODE       CBFA

; CB FB - SET 7,E
SETREG          CBFB,rege,7
ENDOPCODE       CBFB

; CB FC - SET 7,H
SETREG          CBFC,regh,7
ENDOPCODE       CBFC

; CB FD - SET 7,L
SETREG          CBFD,regl,7
ENDOPCODE       CBFD

; CB FE - SET 7,(HL)
SETHL           CBFE,7
ENDOPCODE       CBFE

; CB FF - SET 7,A
SETREG          CBFF,dh,7
ENDOPCODE       CBFF

code32          ends
                end


