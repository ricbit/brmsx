FETCHIMM        equ     1
FETCHSIGNAL     equ     2
FETCHWIMM       equ     3

info_table:
	; 00
	dd      offset comp00
	db      (offset comp00_end)-(offset comp00)
	db      0,0,0
	; 01
	dd      offset comp01
	db      (offset comp01_end)-(offset comp01)
	db      FETCHWIMM,0,0
	; 02
	dd      offset comp02
	db      (offset comp02_end)-(offset comp02)
	db      0,0,0
	; 03
	dd      offset comp03
	db      (offset comp03_end)-(offset comp03)
	db      0,0,0
	; 04
	dd      offset comp04
	db      (offset comp04_end)-(offset comp04)
	db      0,0,0
	; 05
	dd      offset comp05
	db      (offset comp05_end)-(offset comp05)
	db      0,0,0
	; 06
	dd      offset comp06
	db      (offset comp06_end)-(offset comp06)
	db      FETCHIMM,0,0
	; 07
	dd      offset comp07
	db      (offset comp07_end)-(offset comp07)
	db      0,0,0
	; 08
	dd      offset comp08
	db      (offset comp08_end)-(offset comp08)
	db      0,0,0
	; 09
	dd      offset comp09
	db      (offset comp09_end)-(offset comp09)
	db      0,0,0
	; 0A
	dd      offset comp0A
	db      (offset comp0A_end)-(offset comp0A)
	db      0,0,0
	; 0B
	dd      offset comp0B
	db      (offset comp0B_end)-(offset comp0B)
	db      0,0,0
	; 0C
	dd      offset comp0C
	db      (offset comp0C_end)-(offset comp0C)
	db      0,0,0
	; 0D
	dd      offset comp0D
	db      (offset comp0D_end)-(offset comp0D)
	db      0,0,0
	; 0E
	dd      offset comp0E
	db      (offset comp0E_end)-(offset comp0E)
	db      FETCHIMM,0,0
	; 0F
	dd      offset comp0F
	db      (offset comp0F_end)-(offset comp0F)
	db      0,0,0
	; 10
	dd      offset comp10
	db      (offset comp10_end)-(offset comp10)
	db      FETCHSIGNAL,0,0
	; 11
	dd      offset comp11
	db      (offset comp11_end)-(offset comp11)
	db      FETCHWIMM,0,0
	; 12
	dd      offset comp12
	db      (offset comp12_end)-(offset comp12)
	db      0,0,0
	; 13
	dd      offset comp13
	db      (offset comp13_end)-(offset comp13)
	db      0,0,0
	; 14
	dd      offset comp14
	db      (offset comp14_end)-(offset comp14)
	db      0,0,0
	; 15
	dd      offset comp15
	db      (offset comp15_end)-(offset comp15)
	db      0,0,0
	; 16
	dd      offset comp16
	db      (offset comp16_end)-(offset comp16)
	db      FETCHIMM,0,0
	; 17
	dd      offset comp17
	db      (offset comp17_end)-(offset comp17)
	db      0,0,0
	; 18
	dd      offset comp18
	db      (offset comp18_end)-(offset comp18)
	db      FETCHSIGNAL,0,0
	; 19
	dd      offset comp19
	db      (offset comp19_end)-(offset comp19)
	db      0,0,0
	; 1A
	dd      offset comp1A
	db      (offset comp1A_end)-(offset comp1A)
	db      0,0,0
	; 1B
	dd      offset comp1B
	db      (offset comp1B_end)-(offset comp1B)
	db      0,0,0
	; 1C
	dd      offset comp1C
	db      (offset comp1C_end)-(offset comp1C)
	db      0,0,0
	; 1D
	dd      offset comp1D
	db      (offset comp1D_end)-(offset comp1D)
	db      0,0,0
	; 1E
	dd      offset comp1E
	db      (offset comp1E_end)-(offset comp1E)
	db      FETCHIMM,0,0
	; 1F
	dd      offset comp1F
	db      (offset comp1F_end)-(offset comp1F)
	db      0,0,0
	; 20
	dd      offset comp20
	db      (offset comp20_end)-(offset comp20)
	db      FETCHSIGNAL,0,0
	; 21
	dd      offset comp21
	db      (offset comp21_end)-(offset comp21)
	db      FETCHWIMM,0,0
	; 22
	dd      offset comp22
	db      (offset comp22_end)-(offset comp22)
	db      FETCHWIMM,0,0
	; 23
	dd      offset comp23
	db      (offset comp23_end)-(offset comp23)
	db      0,0,0
	; 24
	dd      offset comp24
	db      (offset comp24_end)-(offset comp24)
	db      0,0,0
	; 25
	dd      offset comp25
	db      (offset comp25_end)-(offset comp25)
	db      0,0,0
	; 26
	dd      offset comp26
	db      (offset comp26_end)-(offset comp26)
	db      FETCHIMM,0,0
	; 27
	dd      offset comp27
	db      (offset comp27_end)-(offset comp27)
	db      0,0,0
	; 28
	dd      offset comp28
	db      (offset comp28_end)-(offset comp28)
	db      FETCHSIGNAL,0,0
	; 29
	dd      offset comp29
	db      (offset comp29_end)-(offset comp29)
	db      0,0,0
	; 2A
	dd      offset comp2A
	db      (offset comp2A_end)-(offset comp2A)
	db      FETCHWIMM,0,0
	; 2B
	dd      offset comp2B
	db      (offset comp2B_end)-(offset comp2B)
	db      0,0,0
	; 2C
	dd      offset comp2C
	db      (offset comp2C_end)-(offset comp2C)
	db      0,0,0
	; 2D
	dd      offset comp2D
	db      (offset comp2D_end)-(offset comp2D)
	db      0,0,0
	; 2E
	dd      offset comp2E
	db      (offset comp2E_end)-(offset comp2E)
	db      FETCHIMM,0,0
	; 2F
	dd      offset comp2F
	db      (offset comp2F_end)-(offset comp2F)
	db      0,0,0
	; 30
	dd      offset comp30
	db      (offset comp30_end)-(offset comp30)
	db      FETCHSIGNAL,0,0
	; 31
	dd      offset comp31
	db      (offset comp31_end)-(offset comp31)
	db      FETCHWIMM,0,0
	; 32
	dd      offset comp32
	db      (offset comp32_end)-(offset comp32)
	db      FETCHWIMM,0,0
	; 33
	dd      offset comp33
	db      (offset comp33_end)-(offset comp33)
	db      0,0,0
	; 34
	dd      offset comp34
	db      (offset comp34_end)-(offset comp34)
	db      0,0,0
	; 35
	dd      offset comp35
	db      (offset comp35_end)-(offset comp35)
	db      0,0,0
	; 36
	dd      offset comp36
	db      (offset comp36_end)-(offset comp36)
	db      FETCHIMM,0,0
	; 37
	dd      offset comp37
	db      (offset comp37_end)-(offset comp37)
	db      0,0,0
	; 38
	dd      offset comp38
	db      (offset comp38_end)-(offset comp38)
	db      FETCHSIGNAL,0,0
	; 39
	dd      offset comp39
	db      (offset comp39_end)-(offset comp39)
	db      0,0,0
	; 3A
	dd      offset comp3A
	db      (offset comp3A_end)-(offset comp3A)
	db      FETCHWIMM,0,0
	; 3B
	dd      offset comp3B
	db      (offset comp3B_end)-(offset comp3B)
	db      0,0,0
	; 3C
	dd      offset comp3C
	db      (offset comp3C_end)-(offset comp3C)
	db      0,0,0
	; 3D
	dd      offset comp3D
	db      (offset comp3D_end)-(offset comp3D)
	db      0,0,0
	; 3E
	dd      offset comp3E
	db      (offset comp3E_end)-(offset comp3E)
	db      FETCHIMM,0,0
	; 3F
	dd      offset comp3F
	db      (offset comp3F_end)-(offset comp3F)
	db      0,0,0
	; 40
	dd      offset comp40
	db      (offset comp40_end)-(offset comp40)
	db      0,0,0
	; 41
	dd      offset comp41
	db      (offset comp41_end)-(offset comp41)
	db      0,0,0
	; 42
	dd      offset comp42
	db      (offset comp42_end)-(offset comp42)
	db      0,0,0
	; 43
	dd      offset comp43
	db      (offset comp43_end)-(offset comp43)
	db      0,0,0
	; 44
	dd      offset comp44
	db      (offset comp44_end)-(offset comp44)
	db      0,0,0
	; 45
	dd      offset comp45
	db      (offset comp45_end)-(offset comp45)
	db      0,0,0
	; 46
	dd      offset comp46
	db      (offset comp46_end)-(offset comp46)
	db      0,0,0
	; 47
	dd      offset comp47
	db      (offset comp47_end)-(offset comp47)
	db      0,0,0
	; 48
	dd      offset comp48
	db      (offset comp48_end)-(offset comp48)
	db      0,0,0
	; 49
	dd      offset comp49
	db      (offset comp49_end)-(offset comp49)
	db      0,0,0
	; 4A
	dd      offset comp4A
	db      (offset comp4A_end)-(offset comp4A)
	db      0,0,0
	; 4B
	dd      offset comp4B
	db      (offset comp4B_end)-(offset comp4B)
	db      0,0,0
	; 4C
	dd      offset comp4C
	db      (offset comp4C_end)-(offset comp4C)
	db      0,0,0
	; 4D
	dd      offset comp4D
	db      (offset comp4D_end)-(offset comp4D)
	db      0,0,0
	; 4E
	dd      offset comp4E
	db      (offset comp4E_end)-(offset comp4E)
	db      0,0,0
	; 4F
	dd      offset comp4F
	db      (offset comp4F_end)-(offset comp4F)
	db      0,0,0
	; 50
	dd      offset comp50
	db      (offset comp50_end)-(offset comp50)
	db      0,0,0
	; 51
	dd      offset comp51
	db      (offset comp51_end)-(offset comp51)
	db      0,0,0
	; 52
	dd      offset comp52
	db      (offset comp52_end)-(offset comp52)
	db      0,0,0
	; 53
	dd      offset comp53
	db      (offset comp53_end)-(offset comp53)
	db      0,0,0
	; 54
	dd      offset comp54
	db      (offset comp54_end)-(offset comp54)
	db      0,0,0
	; 55
	dd      offset comp55
	db      (offset comp55_end)-(offset comp55)
	db      0,0,0
	; 56
	dd      offset comp56
	db      (offset comp56_end)-(offset comp56)
	db      0,0,0
	; 57
	dd      offset comp57
	db      (offset comp57_end)-(offset comp57)
	db      0,0,0
	; 58
	dd      offset comp58
	db      (offset comp58_end)-(offset comp58)
	db      0,0,0
	; 59
	dd      offset comp59
	db      (offset comp59_end)-(offset comp59)
	db      0,0,0
	; 5A
	dd      offset comp5A
	db      (offset comp5A_end)-(offset comp5A)
	db      0,0,0
	; 5B
	dd      offset comp5B
	db      (offset comp5B_end)-(offset comp5B)
	db      0,0,0
	; 5C
	dd      offset comp5C
	db      (offset comp5C_end)-(offset comp5C)
	db      0,0,0
	; 5D
	dd      offset comp5D
	db      (offset comp5D_end)-(offset comp5D)
	db      0,0,0
	; 5E
	dd      offset comp5E
	db      (offset comp5E_end)-(offset comp5E)
	db      0,0,0
	; 5F
	dd      offset comp5F
	db      (offset comp5F_end)-(offset comp5F)
	db      0,0,0
	; 60
	dd      offset comp60
	db      (offset comp60_end)-(offset comp60)
	db      0,0,0
	; 61
	dd      offset comp61
	db      (offset comp61_end)-(offset comp61)
	db      0,0,0
	; 62
	dd      offset comp62
	db      (offset comp62_end)-(offset comp62)
	db      0,0,0
	; 63
	dd      offset comp63
	db      (offset comp63_end)-(offset comp63)
	db      0,0,0
	; 64
	dd      offset comp64
	db      (offset comp64_end)-(offset comp64)
	db      0,0,0
	; 65
	dd      offset comp65
	db      (offset comp65_end)-(offset comp65)
	db      0,0,0
	; 66
	dd      offset comp66
	db      (offset comp66_end)-(offset comp66)
	db      0,0,0
	; 67
	dd      offset comp67
	db      (offset comp67_end)-(offset comp67)
	db      0,0,0
	; 68
	dd      offset comp68
	db      (offset comp68_end)-(offset comp68)
	db      0,0,0
	; 69
	dd      offset comp69
	db      (offset comp69_end)-(offset comp69)
	db      0,0,0
	; 6A
	dd      offset comp6A
	db      (offset comp6A_end)-(offset comp6A)
	db      0,0,0
	; 6B
	dd      offset comp6B
	db      (offset comp6B_end)-(offset comp6B)
	db      0,0,0
	; 6C
	dd      offset comp6C
	db      (offset comp6C_end)-(offset comp6C)
	db      0,0,0
	; 6D
	dd      offset comp6D
	db      (offset comp6D_end)-(offset comp6D)
	db      0,0,0
	; 6E
	dd      offset comp6E
	db      (offset comp6E_end)-(offset comp6E)
	db      0,0,0
	; 6F
	dd      offset comp6F
	db      (offset comp6F_end)-(offset comp6F)
	db      0,0,0
	; 70
	dd      offset comp70
	db      (offset comp70_end)-(offset comp70)
	db      0,0,0
	; 71
	dd      offset comp71
	db      (offset comp71_end)-(offset comp71)
	db      0,0,0
	; 72
	dd      offset comp72
	db      (offset comp72_end)-(offset comp72)
	db      0,0,0
	; 73
	dd      offset comp73
	db      (offset comp73_end)-(offset comp73)
	db      0,0,0
	; 74
	dd      offset comp74
	db      (offset comp74_end)-(offset comp74)
	db      0,0,0
	; 75
	dd      offset comp75
	db      (offset comp75_end)-(offset comp75)
	db      0,0,0
	; 76
	dd      offset comp76
	db      (offset comp76_end)-(offset comp76)
	db      0,0,0
	; 77
	dd      offset comp77
	db      (offset comp77_end)-(offset comp77)
	db      0,0,0
	; 78
	dd      offset comp78
	db      (offset comp78_end)-(offset comp78)
	db      0,0,0
	; 79
	dd      offset comp79
	db      (offset comp79_end)-(offset comp79)
	db      0,0,0
	; 7A
	dd      offset comp7A
	db      (offset comp7A_end)-(offset comp7A)
	db      0,0,0
	; 7B
	dd      offset comp7B
	db      (offset comp7B_end)-(offset comp7B)
	db      0,0,0
	; 7C
	dd      offset comp7C
	db      (offset comp7C_end)-(offset comp7C)
	db      0,0,0
	; 7D
	dd      offset comp7D
	db      (offset comp7D_end)-(offset comp7D)
	db      0,0,0
	; 7E
	dd      offset comp7E
	db      (offset comp7E_end)-(offset comp7E)
	db      0,0,0
	; 7F
	dd      offset comp7F
	db      (offset comp7F_end)-(offset comp7F)
	db      0,0,0
	; 80
	dd      offset comp80
	db      (offset comp80_end)-(offset comp80)
	db      0,0,0
	; 81
	dd      offset comp81
	db      (offset comp81_end)-(offset comp81)
	db      0,0,0
	; 82
	dd      offset comp82
	db      (offset comp82_end)-(offset comp82)
	db      0,0,0
	; 83
	dd      offset comp83
	db      (offset comp83_end)-(offset comp83)
	db      0,0,0
	; 84
	dd      offset comp84
	db      (offset comp84_end)-(offset comp84)
	db      0,0,0
	; 85
	dd      offset comp85
	db      (offset comp85_end)-(offset comp85)
	db      0,0,0
	; 86
	dd      offset comp86
	db      (offset comp86_end)-(offset comp86)
	db      0,0,0
	; 87
	dd      offset comp87
	db      (offset comp87_end)-(offset comp87)
	db      0,0,0
	; 88
	dd      offset comp88
	db      (offset comp88_end)-(offset comp88)
	db      0,0,0
	; 89
	dd      offset comp89
	db      (offset comp89_end)-(offset comp89)
	db      0,0,0
	; 8A
	dd      offset comp8A
	db      (offset comp8A_end)-(offset comp8A)
	db      0,0,0
	; 8B
	dd      offset comp8B
	db      (offset comp8B_end)-(offset comp8B)
	db      0,0,0
	; 8C
	dd      offset comp8C
	db      (offset comp8C_end)-(offset comp8C)
	db      0,0,0
	; 8D
	dd      offset comp8D
	db      (offset comp8D_end)-(offset comp8D)
	db      0,0,0
	; 8E
	dd      offset comp8E
	db      (offset comp8E_end)-(offset comp8E)
	db      0,0,0
	; 8F
	dd      offset comp8F
	db      (offset comp8F_end)-(offset comp8F)
	db      0,0,0
	; 90
	dd      offset comp90
	db      (offset comp90_end)-(offset comp90)
	db      0,0,0
	; 91
	dd      offset comp91
	db      (offset comp91_end)-(offset comp91)
	db      0,0,0
	; 92
	dd      offset comp92
	db      (offset comp92_end)-(offset comp92)
	db      0,0,0
	; 93
	dd      offset comp93
	db      (offset comp93_end)-(offset comp93)
	db      0,0,0
	; 94
	dd      offset comp94
	db      (offset comp94_end)-(offset comp94)
	db      0,0,0
	; 95
	dd      offset comp95
	db      (offset comp95_end)-(offset comp95)
	db      0,0,0
	; 96
	dd      offset comp96
	db      (offset comp96_end)-(offset comp96)
	db      0,0,0
	; 97
	dd      offset comp97
	db      (offset comp97_end)-(offset comp97)
	db      0,0,0
	; 98
	dd      offset comp98
	db      (offset comp98_end)-(offset comp98)
	db      0,0,0
	; 99
	dd      offset comp99
	db      (offset comp99_end)-(offset comp99)
	db      0,0,0
	; 9A
	dd      offset comp9A
	db      (offset comp9A_end)-(offset comp9A)
	db      0,0,0
	; 9B
	dd      offset comp9B
	db      (offset comp9B_end)-(offset comp9B)
	db      0,0,0
	; 9C
	dd      offset comp9C
	db      (offset comp9C_end)-(offset comp9C)
	db      0,0,0
	; 9D
	dd      offset comp9D
	db      (offset comp9D_end)-(offset comp9D)
	db      0,0,0
	; 9E
	dd      offset comp9E
	db      (offset comp9E_end)-(offset comp9E)
	db      0,0,0
	; 9F
	dd      offset comp9F
	db      (offset comp9F_end)-(offset comp9F)
	db      0,0,0
	; A0
	dd      offset compA0
	db      (offset compA0_end)-(offset compA0)
	db      0,0,0
	; A1
	dd      offset compA1
	db      (offset compA1_end)-(offset compA1)
	db      0,0,0
	; A2
	dd      offset compA2
	db      (offset compA2_end)-(offset compA2)
	db      0,0,0
	; A3
	dd      offset compA3
	db      (offset compA3_end)-(offset compA3)
	db      0,0,0
	; A4
	dd      offset compA4
	db      (offset compA4_end)-(offset compA4)
	db      0,0,0
	; A5
	dd      offset compA5
	db      (offset compA5_end)-(offset compA5)
	db      0,0,0
	; A6
	dd      offset compA6
	db      (offset compA6_end)-(offset compA6)
	db      0,0,0
	; A7
	dd      offset compA7
	db      (offset compA7_end)-(offset compA7)
	db      0,0,0
	; A8
	dd      offset compA8
	db      (offset compA8_end)-(offset compA8)
	db      0,0,0
	; A9
	dd      offset compA9
	db      (offset compA9_end)-(offset compA9)
	db      0,0,0
	; AA
	dd      offset compAA
	db      (offset compAA_end)-(offset compAA)
	db      0,0,0
	; AB
	dd      offset compAB
	db      (offset compAB_end)-(offset compAB)
	db      0,0,0
	; AC
	dd      offset compAC
	db      (offset compAC_end)-(offset compAC)
	db      0,0,0
	; AD
	dd      offset compAD
	db      (offset compAD_end)-(offset compAD)
	db      0,0,0
	; AE
	dd      offset compAE
	db      (offset compAE_end)-(offset compAE)
	db      0,0,0
	; AF
	dd      offset compAF
	db      (offset compAF_end)-(offset compAF)
	db      0,0,0
	; B0
	dd      offset compB0
	db      (offset compB0_end)-(offset compB0)
	db      0,0,0
	; B1
	dd      offset compB1
	db      (offset compB1_end)-(offset compB1)
	db      0,0,0
	; B2
	dd      offset compB2
	db      (offset compB2_end)-(offset compB2)
	db      0,0,0
	; B3
	dd      offset compB3
	db      (offset compB3_end)-(offset compB3)
	db      0,0,0
	; B4
	dd      offset compB4
	db      (offset compB4_end)-(offset compB4)
	db      0,0,0
	; B5
	dd      offset compB5
	db      (offset compB5_end)-(offset compB5)
	db      0,0,0
	; B6
	dd      offset compB6
	db      (offset compB6_end)-(offset compB6)
	db      0,0,0
	; B7
	dd      offset compB7
	db      (offset compB7_end)-(offset compB7)
	db      0,0,0
	; B8
	dd      offset compB8
	db      (offset compB8_end)-(offset compB8)
	db      0,0,0
	; B9
	dd      offset compB9
	db      (offset compB9_end)-(offset compB9)
	db      0,0,0
	; BA
	dd      offset compBA
	db      (offset compBA_end)-(offset compBA)
	db      0,0,0
	; BB
	dd      offset compBB
	db      (offset compBB_end)-(offset compBB)
	db      0,0,0
	; BC
	dd      offset compBC
	db      (offset compBC_end)-(offset compBC)
	db      0,0,0
	; BD
	dd      offset compBD
	db      (offset compBD_end)-(offset compBD)
	db      0,0,0
	; BE
	dd      offset compBE
	db      (offset compBE_end)-(offset compBE)
	db      0,0,0
	; BF
	dd      offset compBF
	db      (offset compBF_end)-(offset compBF)
	db      0,0,0
	; C0
	dd      offset compC0
	db      (offset compC0_end)-(offset compC0)
	db      0,0,0
	; C1
	dd      offset compC1
	db      (offset compC1_end)-(offset compC1)
	db      0,0,0
	; C2
	dd      offset compC2
	db      (offset compC2_end)-(offset compC2)
	db      FETCHWIMM,0,0
	; C3
	dd      offset compC3
	db      (offset compC3_end)-(offset compC3)
	db      FETCHWIMM,0,0
	; C4
	dd      offset compC4
	db      (offset compC4_end)-(offset compC4)
	db      FETCHWIMM,0,0
	; C5
	dd      offset compC5
	db      (offset compC5_end)-(offset compC5)
	db      0,0,0
	; C6
	dd      offset compC6
	db      (offset compC6_end)-(offset compC6)
	db      FETCHIMM,0,0
	; C7
	dd      0; offset compC7
	db      0; (offset compC7_end)-(offset compC7)
	db      0,0,0
	; C8
	dd      offset compC8
	db      (offset compC8_end)-(offset compC8)
	db      0,0,0
	; C9
	dd      offset compC9
	db      (offset compC9_end)-(offset compC9)
	db      0,0,0
	; CA
	dd      offset compCA
	db      (offset compCA_end)-(offset compCA)
	db      FETCHWIMM,0,0
	; CB
	dd      offset compCB
	db      (offset compCB_end)-(offset compCB)
	db      0,0,0
	; CC
	dd      offset compCC
	db      (offset compCC_end)-(offset compCC)
	db      FETCHWIMM,0,0
	; CD
	dd      offset compCD
	db      (offset compCD_end)-(offset compCD)
	db      FETCHWIMM,0,0
	; CE    
	dd      offset compCE
	db      (offset compCE_end)-(offset compCE)
	db      FETCHIMM,0,0
	; CF
	dd      offset compCF
	db      (offset compCF_end)-(offset compCF)
	db      0,0,0
	; D0
	dd      offset compD0
	db      (offset compD0_end)-(offset compD0)
	db      0,0,0
	; D1
	dd      offset compD1
	db      (offset compD1_end)-(offset compD1)
	db      0,0,0
	; D2
	dd      offset compD2
	db      (offset compD2_end)-(offset compD2)
	db      FETCHWIMM,0,0
	; D3
	dd      offset compD3
	db      (offset compD3_end)-(offset compD3)
	db      FETCHIMM,0,0
	; D4
	dd      offset compD4
	db      (offset compD4_end)-(offset compD4)
	db      FETCHWIMM,0,0
	; D5
	dd      offset compD5
	db      (offset compD5_end)-(offset compD5)
	db      0,0,0
	; D6
	dd      offset compD6
	db      (offset compD6_end)-(offset compD6)
	db      FETCHIMM,0,0
	; D7
	dd      offset compD7
	db      (offset compD7_end)-(offset compD7)
	db      0,0,0
	; D8
	dd      offset compD8
	db      (offset compD8_end)-(offset compD8)
	db      0,0,0
	; D9
	dd      offset compD9
	db      (offset compD9_end)-(offset compD9)
	db      0,0,0
	; DA
	dd      offset compDA
	db      (offset compDA_end)-(offset compDA)
	db      FETCHWIMM,0,0
	; DB
	dd      offset compDB
	db      (offset compDB_end)-(offset compDB)
	db      FETCHIMM,0,0
	; DC
	dd      offset compDC
	db      (offset compDC_end)-(offset compDC)
	db      FETCHWIMM,0,0
	; DD
	dd      offset compDD
	db      (offset compDD_end)-(offset compDD)
	db      0,0,0
	; DE
	dd      offset compDE
	db      (offset compDE_end)-(offset compDE)
	db      FETCHIMM,0,0
	; DF
	dd      offset compDF
	db      (offset compDF_end)-(offset compDF)
	db      0,0,0
	; E0
	dd      offset compE0
	db      (offset compE0_end)-(offset compE0)
	db      0,0,0
	; E1
	dd      offset compE1
	db      (offset compE1_end)-(offset compE1)
	db      0,0,0
	; E2
	dd      offset compE2
	db      (offset compE2_end)-(offset compE2)
	db      FETCHWIMM,0,0
	; E3
	dd      offset compE3
	db      (offset compE3_end)-(offset compE3)
	db      0,0,0
	; E4
	dd      offset compE4
	db      (offset compE4_end)-(offset compE4)
	db      FETCHWIMM,0,0
	; E5
	dd      offset compE5
	db      (offset compE5_end)-(offset compE5)
	db      0,0,0
	; E6
	dd      offset compE6
	db      (offset compE6_end)-(offset compE6)
	db      FETCHIMM,0,0
	; E7
	dd      offset compE7
	db      (offset compE7_end)-(offset compE7)
	db      0,0,0
	; E8
	dd      offset compE8
	db      (offset compE8_end)-(offset compE8)
	db      0,0,0
	; E9
	dd      offset compE9
	db      (offset compE9_end)-(offset compE9)
	db      0,0,0
	; EA
	dd      offset compEA
	db      (offset compEA_end)-(offset compEA)
	db      FETCHWIMM,0,0
	; EB
	dd      offset compEB
	db      (offset compEB_end)-(offset compEB)
	db      0,0,0
	; EC
	dd      offset compEC
	db      (offset compEC_end)-(offset compEC)
	db      FETCHWIMM,0,0
	; ED
	dd      offset compED
	db      (offset compED_end)-(offset compED)
	db      0,0,0
	; EE
	dd      offset compEE
	db      (offset compEE_end)-(offset compEE)
	db      FETCHIMM,0,0
	; EF
	dd      offset compEF
	db      (offset compEF_end)-(offset compEF)
	db      0,0,0
	; F0
	dd      offset compF0
	db      (offset compF0_end)-(offset compF0)
	db      0,0,0
	; F1
	dd      offset compF1
	db      (offset compF1_end)-(offset compF1)
	db      0,0,0
	; F2
	dd      offset compF2
	db      (offset compF2_end)-(offset compF2)
	db      FETCHWIMM,0,0
	; F3
	dd      offset compF3
	db      (offset compF3_end)-(offset compF3)
	db      0,0,0
	; F4
	dd      offset compF4
	db      (offset compF4_end)-(offset compF4)
	db      FETCHWIMM,0,0
	; F5
	dd      offset compF5
	db      (offset compF5_end)-(offset compF5)
	db      0,0,0
	; F6
	dd      offset compF6
	db      (offset compF6_end)-(offset compF6)
	db      FETCHIMM,0,0
	; F7
	dd      offset compF7
	db      (offset compF7_end)-(offset compF7)
	db      0,0,0
	; F8
	dd      offset compF8
	db      (offset compF8_end)-(offset compF8)
	db      0,0,0
	; F9
	dd      offset compF9
	db      (offset compF9_end)-(offset compF9)
	db      0,0,0
	; FA
	dd      offset compFA
	db      (offset compFA_end)-(offset compFA)
	db      FETCHWIMM,0,0
	; FB
	dd      offset compFB
	db      (offset compFB_end)-(offset compFB)
	db      0,0,0
	; FC
	dd      offset compFC
	db      (offset compFC_end)-(offset compFC)
	db      FETCHWIMM,0,0
	; FD
	dd      offset compFD
	db      (offset compFD_end)-(offset compFD)
	db      0,0,0
	; FE
	dd      offset compFE
	db      (offset compFE_end)-(offset compFE)
	db      FETCHIMM,0,0
	; FF
	dd      offset compFF
	db      (offset compFF_end)-(offset compFF)
	db      0,0,0
