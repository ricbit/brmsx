;/****************************************************************************
;*                                                                           *
;* THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY     *
;* KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE       *
;* IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR     *
;* PURPOSE.                                                                  *
;*                                                                           *
;*    Copyright (C) 1997  Intel Corporation.  All Rights Reserved.           *
;*                                                                           *
;****************************************************************************/
;NOTE:NOTE:NOTE:

; IF YOU MODIFY ANY OF THE OPCODES HERE, MAKE SURE TO REFLECT THAT
; IN THE ValidMmxOpcode[] array in mm.c. 
;
;Please use MMWORD and not DWORD (QWORD does not work) for 64 bit data 
; in MMX instructions. After getting a real assembler you will just have to
; add the line " MMWORD	TEXTEQU	<QWORD>" to your code.
;
;
;For TASM older than 5.0 use dd, db instead of dword, byte.
;Also change textequ to equ.
;
MMWORD	equ	<DWORD>
opc_Rdpmc     = 033H
opc_Emms      = 077H
opc_Movd_ld   = 06EH
opc_Movd_st   = 07EH
opc_Movq_ld   = 06FH
opc_Movq_st   = 07FH
opc_Packssdw  = 06BH
opc_Packsswb  = 063H
opc_Packuswb  = 067H
opc_Paddb     = 0FCH
opc_Paddd     = 0FEH
opc_Paddsb    = 0ECH
opc_Paddsw    = 0EDH
opc_Paddusb   = 0DCH
opc_Paddusw   = 0DDH
opc_Paddw     = 0FDH
opc_Pand      = 0DBH
opc_Pandn     = 0DFH
opc_Pcmpeqb   = 074H
opc_Pcmpeqd   = 076H
opc_Pcmpeqw   = 075H
opc_Pcmpgtb   = 064H
opc_Pcmpgtd   = 066H
opc_Pcmpgtw   = 065H
opc_Pmaddwd   = 0F5H
opc_Pmulhw    = 0E5H
opc_Pmullw    = 0D5H
opc_Por       = 0EBH
opc_PSHimd    = 072H
opc_PSHimq    = 073H
opc_PSHimw    = 071H
opc_Pslld     = 0F2H
opc_Psllq     = 0F3H
opc_Psllw     = 0F1H
opc_Psrad     = 0E2H
opc_Psraw     = 0E1H
opc_Psrld     = 0D2H
opc_Psrlq     = 0D3H
opc_Psrlw     = 0D1H
opc_Psubb     = 0F8H
opc_Psubd     = 0FAH
opc_Psubsb    = 0E8H
opc_Psubsw    = 0E9H
opc_Psubusb   = 0D8H
opc_Psubusw   = 0D9H
opc_Psubw     = 0F9H
opc_Punpcklbw = 060H
opc_Punpckldq = 062H
opc_Punpcklwd = 061H
opc_Punpckhbw = 068H
opc_Punpckhdq = 06AH
opc_Punpckhwd = 069H
opc_Pxor      = 0EFH

.486P


; ALIAS R# to MM# registers

DefineMMxRegs Macro
IFDEF APP_16BIT
	MM0	equ	<AX>
	MM1	equ	<CX>
	MM2	equ	<DX>
	MM3	equ	<BX>
	MM4	equ	<SP>
	MM5	equ	<BP>
	MM6	equ	<SI>
	MM7	equ	<DI>

	mm0	equ	<AX>
	mm1	equ	<CX>
	mm2	equ	<DX>
	mm3	equ	<BX>
	mm4	equ	<SP>
	mm5	equ	<BP>
	mm6	equ	<SI>
	mm7	equ	<DI>

	Mm0	equ	<AX>
	Mm1	equ	<CX>
	Mm2	equ	<DX>
	Mm3	equ	<BX>
	Mm4	equ	<SP>
	Mm5	equ	<BP>
	Mm6	equ	<SI>
	Mm7	equ	<DI>

	mM0	equ	<AX>
	mM1	equ	<CX>
	mM2	equ	<DX>
	mM3	equ	<BX>
	mM4	equ	<SP>
	mM5	equ	<BP>
	mM6	equ	<SI>
	mM7	equ	<DI>

ELSE
	MM0	equ	<EAX>
	MM1	equ	<ECX>
	MM2	equ	<EDX>
	MM3	equ	<EBX>
	MM4	equ	<ESP>
	MM5	equ	<EBP>
	MM6	equ	<ESI>
	MM7	equ	<EDI>

	mm0	equ	<EAX>
	mm1	equ	<ECX>
	mm2	equ	<EDX>
	mm3	equ	<EBX>
	mm4	equ	<ESP>
	mm5	equ	<EBP>
	mm6	equ	<ESI>
	mm7	equ	<EDI>

	Mm0	equ	<EAX>
	Mm1	equ	<ECX>
	Mm2	equ	<EDX>
	Mm3	equ	<EBX>
	Mm4	equ	<ESP>
	Mm5	equ	<EBP>
	Mm6	equ	<ESI>
	Mm7	equ	<EDI>

	mM0	equ	<EAX>
	mM1	equ	<ECX>
	mM2	equ	<EDX>
	mM3	equ	<EBX>
	mM4	equ	<ESP>
	mM5	equ	<EBP>
	mM6	equ	<ESI>
	mM7	equ	<EDI>
ENDIF
EndM

; ALIAS R# to MM# registers
DefineMMxNUM Macro
	MM0	equ	<0>
	MM1	equ	<0>
	MM2	equ	<0>
	MM3	equ	<0>
	MM4	equ	<0>
	MM5	equ	<0>
	MM6	equ	<0>
	MM7	equ	<0>

	mm0	equ	<0>
	mm1	equ	<0>
	mm2	equ	<0>
	mm3	equ	<0>
	mm4	equ	<0>
	mm5	equ	<0>
	mm6	equ	<0>
	mm7	equ	<0>

	Mm0	equ	<0>
	Mm1	equ	<0>
	Mm2	equ	<0>
	Mm3	equ	<0>
	Mm4	equ	<0>
	Mm5	equ	<0>
	Mm6	equ	<0>
	Mm7	equ	<0>

	mM0	equ	<0>
	mM1	equ	<0>
	mM2	equ	<0>
	mM3	equ	<0>
	mM4	equ	<0>
	mM5	equ	<0>
	mM6	equ	<0>
	mM7	equ	<0>
EndM



UnDefineMMxRegs Macro
	MM0	equ	<MM0>
	MM1	equ	<MM1>
	MM2	equ	<MM2>
	MM3	equ	<MM3>
	MM4	equ	<MM4>
	MM5	equ	<MM5>
	MM6	equ	<MM6>
	MM7	equ	<MM7>

	mm0	equ	<mm0>
	mm1	equ	<mm1>
	mm2	equ	<mm2>
	mm3	equ	<mm3>
	mm4	equ	<mm4>
	mm5	equ	<mm5>
	mm6	equ	<mm6>
	mm7	equ	<mm7>

	Mm0	equ	<Mm0>
	Mm1	equ	<Mm1>
	Mm2	equ	<Mm2>
	Mm3	equ	<Mm3>
	Mm4	equ	<Mm4>
	Mm5	equ	<Mm5>
	Mm6	equ	<Mm6>
	Mm7	equ	<Mm7>

	mM0	equ	<mM0>
	mM1	equ	<mM1>
	mM2	equ	<mM2>
	mM3	equ	<mM3>
	mM4	equ	<mM4>
	mM5	equ	<mM5>
	mM6	equ	<mM6>
	mM7	equ	<mM7>
EndM


rdpmc     macro
	db	0fh, opc_Rdpmc
endm

emms     macro
	db	0fh, opc_Emms
endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movd1   macro   dst:req, src:req       ; MMX->EXX
       local   x, y
		DefineMMxNUM
		DefineMMxRegs
x:
        cmpxchg   dst, src
y:
        org     x+1
        db    opc_Movd_st 
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movd2   macro   dst:req, src:req	;  MEM || EXX || MMX -> MMX
       local   x, y
		DefineMMxNUM
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Movd_ld 
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movd3   macro   dst:req, src:req	; MMX -> MEM
       local   x, y
		DefineMMxNUM
		DefineMMxRegs
x:
        cmpxchg   dst, src
y:
        org     x+1
        db    opc_Movd_st 
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

movdt    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Movd_ld 
        org     y
		UnDefineMMxRegs
        endm

movdf   macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   dst, src
y:
        org     x+1
        db    opc_Movd_st
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movq1   macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Movq_ld 
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movq2   macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   dst, src
y:
        org     x+1
        db    opc_Movq_st 
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
packssdw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Packssdw
        org     y
		UnDefineMMxRegs
        endm

packsswb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Packsswb
        org     y
		UnDefineMMxRegs
        endm

packuswb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Packuswb
        org     y
		UnDefineMMxRegs
        endm

paddd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddd   
        org     y
		UnDefineMMxRegs
        endm

paddsb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddsb  
        org     y
		UnDefineMMxRegs
        endm

paddsw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddsw  
        org     y
		UnDefineMMxRegs
        endm

paddusb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddusb 
        org     y
		UnDefineMMxRegs
        endm

paddusw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddusw 
        org     y
		UnDefineMMxRegs
        endm

paddb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddb   
        org     y
		UnDefineMMxRegs
        endm

paddw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Paddw   
        org     y
		UnDefineMMxRegs
        endm

pand    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pand    
        org     y
		UnDefineMMxRegs
        endm

pandn    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pandn   
        org     y
		UnDefineMMxRegs
        endm

pcmpeqb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpeqb 
        org     y
		UnDefineMMxRegs
        endm

pcmpeqd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpeqd 
        org     y
		UnDefineMMxRegs
        endm

pcmpeqw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpeqw 
        org     y
		UnDefineMMxRegs
        endm

pcmpgtb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpgtb 
        org     y
		UnDefineMMxRegs
        endm

pcmpgtd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpgtd 
        org     y
		UnDefineMMxRegs
        endm

pcmpgtw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pcmpgtw 
        org     y
		UnDefineMMxRegs
        endm

pmaddwd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pmaddwd 
        org     y
		UnDefineMMxRegs
        endm

pmulhw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pmulhw  
        org     y
		UnDefineMMxRegs
        endm

pmullw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pmullw  
        org     y
		UnDefineMMxRegs
        endm

por    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Por     
        org     y
		UnDefineMMxRegs
        endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pslld1    macro   dst:req, src:req   ;; constant
        local   x, y
		DefineMMxRegs
x:
        btr   dst, src
y:
        org     x+1
        db    opc_PSHimd  
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pslld2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pslld   
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


psllw1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        btr   dst, src
y:
        org     x+1
        db    opc_PSHimw  
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psllw2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psllw   
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


psrad1    macro   dst:req, src:req  ;;immediate
        local   x, y
		DefineMMxRegs
x:
        bt   dst, src
y:
        org     x+1
        db    opc_PSHimd  
        org     y
		UnDefineMMxRegs
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrad2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psrad   
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psraw1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        bt   dst, src
y:
        org     x+1
        db    opc_PSHimw  
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psraw2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psraw   
        org     y
		UnDefineMMxRegs
        endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrld1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg dst,MM2
	db	src
y:
        org     x+1
        db    opc_PSHimd  
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrld2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psrld   
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
psrlq1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg dst,MM2
	db	src
y:
        org     x+1
        db    opc_PSHimq  
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrlq2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psrlq   
        org     y
		UnDefineMMxRegs
        endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
psllq1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        btr   dst, src
y:
        org     x+1
        db    opc_PSHimq  
        org     y
		UnDefineMMxRegs
        endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
psllq2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psllq   
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrlw1    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg dst,MM2
	db	src
y:
        org     x+1
        db    opc_PSHimw  
        org     y
		UnDefineMMxRegs
        endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psrlw2    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psrlw   
        org     y
		UnDefineMMxRegs
        endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

psubsb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubsb  
        org     y
		UnDefineMMxRegs
        endm

psubsw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubsw  
        org     y
		UnDefineMMxRegs
        endm

psubusb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubusb 
        org     y
		UnDefineMMxRegs
        endm

psubusw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubusw 
        org     y
		UnDefineMMxRegs
        endm

psubb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubb   
        org     y
		UnDefineMMxRegs
        endm

psubw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubw   
        org     y
		UnDefineMMxRegs
        endm

punpcklbw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpcklbw
        org     y
		UnDefineMMxRegs
        endm

punpckhdq    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpckhdq
        org     y
		UnDefineMMxRegs
        endm

punpcklwd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpcklwd
        org     y
		UnDefineMMxRegs
        endm

punpckhbw    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpckhbw
        org     y
		UnDefineMMxRegs
        endm

punpckldq    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpckldq
        org     y
		UnDefineMMxRegs
        endm

punpckhwd    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Punpckhwd
        org     y
		UnDefineMMxRegs
        endm

pxor    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Pxor    
        org     y
		UnDefineMMxRegs
        endm

psubd   macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        db    opc_Psubd   
        org     y
		UnDefineMMxRegs
        endm
