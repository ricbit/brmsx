; --------------------------------------------------------------------
; ADCREG - ADC A,rr rr=[a,b,c,d,e,h,l]

ADCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4+1
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCAHL - ADC A,(HL)

ADCAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                mov     ebp,7+2
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCIMM - ADC A,dd

ADCIMM          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                mov     bh,al
                mov     ebp,7+2
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCAII - ADC A,(II+dd)

ADCAII          macro   opcode,regii

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     bh,al
                mov     ebp,19+4
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADC rrw,regw   rrw=[hl] regw=[bc,de,hl,sp,ix,iy]

ADCREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     bl,reglow
                adc     rrlow,bl
                mov     bh,rrhigh
                mov     bl,reghigh
                mov     cl,0
                adc     rrhigh,bl
                mov     ebp,15+2
                adc     cl,cl
                mov     al,rrhigh
                xor     bl,bh
                xor     bl,al
                mov     dl,cl
                or      dl,[offset ARITP_table+eax]
                mov     al,cl
                and     bl,NBIT_0
                or      al,bl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset OVERFLOW_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ADDREG - ADD A,rr rr=[a,b,c,d,e,h,l]

ADDREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4+1
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDAHL - ADD A,(HL)

ADDAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                mov     ebp,7+2
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDIMM - ADD A,dd

ADDIMM          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                mov     bh,al
                mov     ebp,7+2
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDAII - ADD A,(II+dd)

ADDAII          macro   opcode,regii

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     bh,al
                mov     ebp,19+4
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADD rrw,regw   rrw=[hl,ix,iy] regw=[bc,de,hl,sp,ix,iy]

ADDREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh,cycles

emul&opcode:                
                inc     edi
                mov     bl,reglow
                add     rrlow,bl
                mov     bh,rrhigh
                mov     bl,reghigh
                mov     cl,0
                adc     rrhigh,bl
                mov     ebp,cycles+1
                adc     cl,cl
                mov     al,rrhigh
                xor     bl,bh
                xor     bl,al
                and     dl,11000100b
                or      dl,cl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ANDREG - AND rr rr=[a,b,c,d,e,h,l]

ANDREG           macro   opcode,reg

emul&opcode:                
                and     dh,reg
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                mov     ebp,4+1
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDHL - AND (HL)

ANDHL           macro   opcode

emul&opcode:                
                mov     ecx,regehl
                call    readmem
                and     dh,al
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                mov     ebp,7+3
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDIMM - AND dd

ANDIMM           macro   opcode

emul&opcode:                
                inc     edi
                call    fetch
                and     dh,al
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                mov     ebp,7+2
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDII - AND (II+dd)

ANDII           macro   opcode,regii

emul&opcode:                
                inc     edi
                call    fetch
                inc     edi
                movsx   ebx,al  
                mov     ecx,regii
                add     cx,bx
                call    readmem
                and     dh,al
                mov     al,dh
                mov     ebp,19+4
                mov     dl,[offset LOGICAL_table+eax]
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; BITREG - BIT nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

BITREG          macro   opcode,reg,bit

emul&opcode:                
                mov     al,reg
                inc     edi
                and     dl,01h
                mov     ebp,8+2
                or      dl,[offset BIT&bit&_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; BITHL - BIT nn,(HL) nn=[0..7]

BITHL           macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                and     dl,01h
                mov     ebp,12+3
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b
                ret

                endm

; --------------------------------------------------------------------
; BITII - BIT nn,(II+dd) nn=[0..7]

BITII           macro   opcode,bit,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                and     dl,01h
                mov     ebp,20+4
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b
                ret

                endm

; --------------------------------------------------------------------
; CPREG - CP rr rr=[a,b,c,d,e,h,l]

CPREG           macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4+1
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPAHL - CP (HL)

CPAHL           macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                mov     ebp,7+2
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPIMM - CP dd

CPIMM           macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                mov     bh,al
                mov     ebp,7+2
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPII - CP (II+dd)

CPII            macro   opcode,itype

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,itype
                call    fetch
                movsx   ebx,al
                inc     edi
                add     cx,bx
                call    readmem
                mov     bh,al
                mov     ebp,19+3
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; OPDAA - DAA

OPDAA           macro   opcode

emul&opcode:
                inc     edi
                xor     ecx,ecx
                mov     al,dh
                mov     cl,dl
                mov     dl,0
                add     dx,[offset DAA_table+ecx*2]
                mov     ebx,[offset DAA_select_table+ecx*4]
                add     dx,[ebx+eax*2]
                mov     cl,dh
                or      dl,[offset LOGICAL_table+ecx]
                and     edx,0ffffh
                mov     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; DECREG - DEC rr rr=[a,b,c,d,e,h,l]

DECREG          macro   opcode,reg

emul&opcode:
                inc     edi
                dec     reg
                and     dl,1
                mov     al,reg
                mov     ebp,4+1
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECHL - DEC (HL)

DECHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                dec     al
                call    writemem
                and     dl,1
                mov     ebp,11+3
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECII - DEC (II+dd)

DECII           macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,reg
                add     cx,bx
                call    readmem
                dec     al
                call    writemem
                and     dl,1
                mov     ebp,23+5
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECWREG - DEC rr rr=[bc,de,hl,sp,ix,iy]

DECWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                dec     reg
                mov     ebp,tcycles+1
                ret

                endm

; --------------------------------------------------------------------
; INADD - IN A,(dd) 

INADD           macro   opcode

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                call    [offset inportxx+eax*4]
                and     ebx,0ffh
                and     dl,1
                mov     dh,bl
                or      dl,[offset LOGICAL_table+ebx]
                mov     ebp,11+2
                ret

                endm

; --------------------------------------------------------------------
; INREG - IN rr,(C) 

INREG           macro   opcode,reg

emul&opcode:
                inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                and     ebx,0ffh
                and     dl,1
                mov     reg,bl
                or      dl,[offset LOGICAL_table+ebx]
                mov     ebp,12+2
                ret

                endm

; --------------------------------------------------------------------
; INCREG - INC rr rr=[a,b,c,d,e,h,l]

INCREG          macro   opcode,reg

emul&opcode:
                inc     edi
                inc     reg
                and     dl,1
                mov     al,reg
                mov     ebp,4+1
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCHL - INC (HL)

INCHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                inc     al
                call    writemem
                and     dl,1
                mov     ebp,11+3
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCII - INC (II+dd)

INCII           macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                movsx   ebx,al
                inc     edi
                mov     ecx,reg
                add     cx,bx
                call    readmem
                inc     al
                call    writemem
                and     dl,1
                mov     ebp,23+5
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCWREG - INC rr rr=[bc,de,hl,sp,ix,iy]

INCWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                inc     reg
                mov     ebp,tcycles+1
                ret

                endm

; --------------------------------------------------------------------
; JRCC - JR cc,dd

JRCC            macro   opcode,jcc,flagtype

emul&opcode:    inc     edi
                call    fetch
                inc     edi
                test    dl,flagtype
                jcc     emul&opcode&a    
                movsx   ebx,al
                mov     ebp,12+2
                add     edi,ebx
                ret
emul&opcode&a:  mov     ebp,7+2
                ret

                endm

; --------------------------------------------------------------------
; LDREGREG - LD rr,rr rr=[b,c,d,e,h,l]

LDREGREG        macro   opcode,reg1,reg2

emul&opcode:
                inc     edi
                mov     bl,reg2
                mov     ebp,4+1
                mov     reg1,bl
                ret

                endm

; --------------------------------------------------------------------
; LDREGA - LD rr,A rr=[b,c,d,e,h,l]

LDREGA          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     reg,dh
                mov     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; LDAREG - LD A,rr rr=[a,b,c,d,e,h,l]

LDAREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dh,reg
                mov     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; LDREGHL - LD rr,(HL) rr=[a,b,c,d,e,h,l]

LDREGHL         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     reg,al
                mov     ebp,7+2
                ret

                endm

; --------------------------------------------------------------------
; LDREGIMM - LD rr,dd rr=[a,b,c,d,e,h,l]

LDREGIMM        macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                mov     reg,al
                mov     ebp,7+2
                ret

                endm

; --------------------------------------------------------------------
; LDREGIIDD - LD rr,(II+dd)     rr=[a,b,c,d,e,h,l]

LDREGIIDD       macro   opcode,reg,regii

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     reg,al
                mov     ebp,19+4
                ret

                endm

; --------------------------------------------------------------------
; LDHLREG - LD (HL),rr rr=[a,b,c,d,e,h,l]

LDHLREG         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     al,reg
                mov     ecx,regehl
                mov     ebp,7+2
                call    writemem
                ret

                endm

; --------------------------------------------------------------------
; LDIIDDREG - LD (II+dd),rr     rr=[a,b,c,d,e,h,l]

LDIIDDREG       macro   opcode,reg,itype

emul&opcode:
                inc     edi
                call    fetch
                movsx   ebx,al
                mov     ecx,itype
                inc     edi
                add     cx,bx
                mov     al,reg
                call    writemem
                mov     ebp,19+4
                ret

                endm

; --------------------------------------------------------------------
; LDHLIMM - LD (HL),dd

LDHLIMM         macro   opcode

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                mov     ecx,regehl
                mov     ebp,10+3
                call    writemem
                ret

                endm

; --------------------------------------------------------------------
; LDIIDDNN - LD (II+dd),nn     rr=[a,b,c,d,e,h,l]

LDIIDDNN        macro   opcode,itype

emul&opcode:
                inc     edi
                call    fetch
                movsx   ebx,al
                mov     ecx,itype
                add     cx,bx
                inc     edi
                call    fetch
                inc     edi
                call    writemem
                mov     ebp,19+5
                ret

                endm

; --------------------------------------------------------------------
; LDAI - LD A,I

LDAI            macro   opcode

emul&opcode:    
                inc     edi
                mov     dh,regi
                mov     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                ret

                endm

; --------------------------------------------------------------------
; LDAR - LD A,R

LDAR            macro   opcode

emul&opcode:    
                inc     edi
                mov     dh,byte ptr [offset rcounter]
                and     dh,07fh
                or      dh,rmask
                mov     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                ret

                endm

; --------------------------------------------------------------------
; LDD

OPLDD           macro   opcode

emul&opcode:    
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                mov     ebp,16+4                        ; clock 3 U
                dec     regde                           ; clock 3 V
                dec     reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                dec     regbc                           ; clock 6 U
                jz      emul&opcode&a                   ; clock 6 V
                or      dl,[offset PVS53_table+eax]     ; clock 7 U
                ret                                     ; clock 7 V
emul&opcode&a:
                or      dl,[offset PVN53_table+eax]     ; clock 7 U
                ret                                     ; clock 7 V

                endm

; --------------------------------------------------------------------
; LDI

OPLDI           macro   opcode

emul&opcode:    
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                mov     ebp,16+4                        ; clock 3 U
                inc     regde                           ; clock 3 V
                inc     reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                dec     regbc                           ; clock 6 U
                jz      emul&opcode&a                   ; clock 6 V
                or      dl,[offset PVS53_table+eax]     ; clock 7 U
                ret                                     ; clock 7 V
emul&opcode&a:
                or      dl,[offset PVN53_table+eax]     ; clock 7 U
                ret                                     ; clock 7 V

                endm

; --------------------------------------------------------------------
; NEG

OPNEG           macro   opcode

emul&opcode:    
                mov     al,dh                           
                inc     edi
                mov     ebp,8+2
                mov     dx,[offset NEG_table+eax*2]
                ret

                endm

; --------------------------------------------------------------------
; ORREG - OR rr rr=[a,b,c,d,e,h,l]

ORREG           macro   opcode,reg

emul&opcode:                
                inc     edi
                or      dh,reg
                mov     al,dh
                mov     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORHL - OR (HL)

ORHL            macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                or      dh,al
                mov     al,dh
                mov     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORIMM - OR dd

ORIMM           macro   opcode

emul&opcode:                
                inc     edi
                call    fetch
                inc     edi
                or      dh,al
                mov     al,dh
                mov     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORII - OR (II+dd)

ORII            macro   opcode,regii

emul&opcode:                
                inc     edi
                call    fetch
                movsx   ebx,al
                mov     ecx,regii
                inc     edi
                add     cx,bx
                call    readmem
                or      dh,al
                mov     al,dh
                mov     ebp,19+4
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OUTIMM - OUT (dd),A

OUTIMM          macro   opcode

emul&opcode:    inc     edi
                call    fetch
                inc     edi
                mov     bl,dh
                mov     ebp,11+2
                jmp     [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OUTCREG - OUT (C),rr

OUTCREG         macro   opcode,reg

emul&opcode:    mov     al,regc
                inc     edi
                mov     ebp,12+2
                mov     bl,reg
                jmp     [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; RESREG - RES nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

RESREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                and     reg,NBIT_&bit
                mov     ebp,8+2
                ret

                endm

; --------------------------------------------------------------------
; RESHL - RES nn,(HL)

RESHL          macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                and     al,NBIT_&bit
                call    writemem
                mov     ebp,15+4
                ret

                endm

; --------------------------------------------------------------------
; RESII - RES nn,(II+dd)

RESII          macro   opcode,bit,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                and     al,NBIT_&bit
                call    writemem
                mov     ebp,23+6
                ret

                endm

; --------------------------------------------------------------------
; RLREG - RL rr rr=[a,b,c,d,e,h,l]

RLREG           macro   opcode,reg

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     dl,0
                rcl     reg,1
                mov     al,reg
                adc     dl,dl
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLHL - RL (HL)

RLHL            macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                call    writemem
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLII - RL (II+dd)

RLII            macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regehl
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                call    writemem
                mov     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLA - RLA

OPRLA           macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dl
                and     dl,11000100b
                shr     bl,1
                mov     bl,0
                rcl     dh,1
                mov     al,dh
                adc     bl,bl
                or      dl,bl
                mov     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCREG - RLC rr rr=[a,b,c,d,e,h,l]

RLCREG          macro opcode,reg

emul&opcode:                
                inc     edi
                rol     reg,1
                mov     dl,reg
                mov     al,dl
                and     dl,1
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCHL - RLC (HL)

RLCHL           macro opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                rol     al,1
                call    writemem
                mov     dl,al
                and     dl,1
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCII - RLC (II+dd)

RLCII           macro opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                rol     al,1
                call    writemem
                mov     dl,al
                and     dl,1
                mov     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLCA - RLCA

OPRLCA          macro opcode

emul&opcode:                
                inc     edi
                and     dl,11000100b
                rol     dh,1
                mov     bl,dh
                mov     al,bl
                and     bl,1
                or      dl,bl
                mov     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLD - RLD

OPRLD           macro   opcode

emul&opcode:
                inc     edi                            
                mov     ecx,regehl                    
                call    readmem                       
                mov     bl,al                         
                ; put low digit of hl in upper part of al
                shl     al,4
                mov     bh,dh                         
                ; dh has upper digit of a
                and     dh,0f0h
                ; bh has lower digit of a
                and     bh,0fh
                shr     bl,4
                ; mix
                or      dh,bl
                or      al,bh
                call    writemem
                mov     al,dh
                and     dl,1
                mov     ebp,18+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRREG - RR rr rr=[a,b,c,d,e,h,l]

RRREG           macro   opcode,reg

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     dl,reg
                rcr     reg,1
                and     dl,1
                mov     al,reg
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRHL - RR (HL)

RRHL            macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                call    writemem
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRII - RR (II+dd)

RRII            macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                call    writemem
                mov     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRA - RRA

OPRRA           macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dl
                and     dl,11000100b
                shr     bl,1
                mov     bl,dh
                rcr     dh,1
                and     bl,1
                or      dl,bl
                mov     al,dh
                mov     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCREG - RRC rr rr=[a,b,c,d,e,h,l]

RRCREG          macro opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                ror     reg,1
                mov     al,reg
                and     dl,1
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCHL - RRC (HL)

RRCHL           macro opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                ror     al,1
                call    writemem
                and     dl,1
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRCA - RRCA

OPRRCA          macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dh
                and     dl,11000100b
                ror     dh,1
                mov     al,dh
                and     bl,1
                or      dl,bl
                mov     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRD - RRD

OPRRD           macro   opcode

emul&opcode:
                inc     edi                            
                mov     ecx,regehl                    
                call    readmem                       
                mov     bl,al                         
                ; put high digit of hl in al
                shr     al,4
                ; put low digit of hl in bl
                and     bl,0fh                        
                mov     bh,dh                         
                ; put high digit of a in dh
                and     dh,0f0h
                ; put low digit of a in upper part of bh
                shl     bh,4
                or      dh,bl
                ; mix
                or      al,bh
                call    writemem
                mov     al,dh
                and     dl,1
                mov     ebp,18+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SBCREG - SBC A,rr rr=[a,b,c,d,e,h,l]

SBCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4+1
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCAHL - SBC A,(HL)

SBCAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                mov     ebp,7+2
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCIMM - SBC A,dd

SBCIMM          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                mov     bh,al
                mov     ebp,7+2
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCAII - SBC A,(II+dd)

SBCAII          macro   opcode,regii

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     bh,al
                mov     ebp,19+4
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBC HL,regw   regw=[bc,de,hl,sp]

SBCHLWREG       macro   opcode,reglow,reghigh

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     bl,reglow
                sbb     regl,bl
                mov     bh,regh
                mov     bl,reghigh
                mov     cl,0
                sbb     regh,bl
                mov     ebp,15+1
                adc     cl,cl
                mov     al,regh
                xor     bl,bh
                xor     bl,al
                mov     dl,cl
                or      dl,[offset ARITN_table+eax]
                mov     al,cl
                and     bl,NBIT_0
                or      al,bl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset OVERFLOW_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SETREG - SET nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

SETREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                or      reg,BIT_&bit
                mov     ebp,8+2
                ret

                endm

; --------------------------------------------------------------------
; SETHL - SET nn,(HL)

SETHL          macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_&bit
                call    writemem
                mov     ebp,15+4
                ret

                endm

; --------------------------------------------------------------------
; SETII - SET nn,(II+dd)

SETII          macro   opcode,bit,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                or      al,BIT_&bit
                call    writemem
                mov     ebp,23+6
                ret

                endm

; --------------------------------------------------------------------
; SLAREG - SLA rr rr=[a,b,c,d,e,h,l]

SLAREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dl,0
                shl     reg,1
                mov     ebp,8+2
                adc     dl,dl
                mov     al,reg
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLAHL - SLA (HL)

SLAHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,0
                shl     al,1
                mov     ebp,15+4
                adc     dl,dl
                call    writemem
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRAREG - SRA rr rr=[a,b,c,d,e,h,l]

SRAREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                sar     reg,1
                and     dl,1
                mov     al,reg
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRAHL - SRA (HL)

SRAHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                sar     al,1
                and     dl,1
                call    writemem
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLREG - SRL rr rr=[a,b,c,d,e,h,l]

SRLREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                shr     reg,1
                and     dl,1
                mov     al,reg
                mov     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLHL - SRL (HL)

SRLHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                shr     al,1
                and     dl,1
                call    writemem
                mov     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SUBREG - SUB rr rr=[a,b,c,d,e,h,l]

SUBREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4+1
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBAHL - SUB (HL)

SUBAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                mov     ebp,7+2
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBIMM - SUB dd

SUBIMM          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                call    fetch
                inc     edi
                mov     bh,al
                mov     ebp,7+2
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBII - SUB (II+dd)

SUBII           macro   opcode,itype

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,itype
                call    fetch
                movsx   ebx,al
                inc     edi
                add     cx,bx
                call    readmem
                mov     bh,al
                mov     ebp,19+4
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; XORREG - XOR rr rr=[a,b,c,d,e,h,l]

XORREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                xor     dh,reg
                mov     al,dh
                mov     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORHL - XOR (HL)

XORHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                xor     dh,al
                mov     al,dh
                mov     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORIMM - XOR dd

XORIMM          macro   opcode

emul&opcode:                
                inc     edi
                call    fetch
                inc     edi
                xor     dh,al
                mov     al,dh
                mov     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORII - XOR (II+dd)

XORII           macro   opcode,regii

emul&opcode:                
                inc     edi
                call    fetch
                inc     edi
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                xor     dh,al
                mov     al,dh
                mov     ebp,19+4
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

