; --------------------------------------------------------------------
; ADCREG - ADC A,rr rr=[a,b,c,d,e,h,l]

ADCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4
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
                mov     ebp,7
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
                mov     ebp,7
                jmp     opadcreg

                endm

opadcreg:
                shr     dl,1                            ; clock 2 U
                mov     ch,dh                           ; clock 2 V
                adc     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITP_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

; --------------------------------------------------------------------
; ADDREG - ADD A,rr rr=[a,b,c,d,e,h,l]

ADDREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4
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
                mov     ebp,7
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
                mov     ebp,7
                jmp     opaddreg

                endm

opaddreg:
                mov     ch,dh                           ; clock 2 
                add     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     ebp,4                           ; clock 4 U
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITP_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

; --------------------------------------------------------------------
; BITREG - BIT nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

BITREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                xor     ebx,ebx
                mov     bl,reg
                and     dl,01h
                mov     ebp,8
                or      dl,[offset BIT&bit&_table+ebx]
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
                mov     ebp,12
                or      dl,[offset BIT&bit&_table+eax]
                ret

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
                mov     ebp,4
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
                mov     ebp,4
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
                mov     ebp,11
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECII - DEC (II+dd)

DECII           macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                mov     ecx,reg
                add     cx,ax
                call    readmem
                dec     al
                call    writemem
                and     dl,1
                mov     ebp,23
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECWREG - DEC rr rr=[bc,de,hl,sp,ix,iy]

DECWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                dec     reg
                mov     ebp,tcycles
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
                mov     ebp,4
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
                mov     ebp,11
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCII - INC (II+dd)

INCII           macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                inc     edi
                mov     ecx,reg
                add     cx,ax
                call    readmem
                inc     al
                call    writemem
                and     dl,1
                mov     ebp,23
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCWREG - INC rr rr=[bc,de,hl,sp,ix,iy]

INCWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                inc     reg
                mov     ebp,tcycles
                ret

                endm

; --------------------------------------------------------------------
; RESREG - RES nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

RESREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                and     reg,NBIT_&bit
                mov     ebp,8
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
                mov     ebp,15
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
                mov     ebp,8
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
                mov     dl,al
                and     dl,1
                mov     ebp,15
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SBCREG - SBC A,rr rr=[a,b,c,d,e,h,l]

SBCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4
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
                mov     ebp,7
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
                mov     ebp,7
                jmp     opsbcreg

                endm

opsbcreg:
                shr     dl,1                            ; clock 2 U
                mov     ch,dh                           ; clock 2 V
                sbb     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITN_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

; --------------------------------------------------------------------
; SUBREG - SUB rr rr=[a,b,c,d,e,h,l]

SUBREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                mov     ebp,4
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
                mov     ebp,7
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
                mov     ebp,7
                jmp     opsubreg

                endm

opsubreg:
                mov     ch,dh                           ; clock 2 V
                sub     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     ebp,4                           ; clock 4 U
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITN_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

; --------------------------------------------------------------------
; SRLREG - SRL rr rr=[a,b,c,d,e,h,l]

SRLREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                shr     reg,1
                and     dl,1
                mov     al,reg
                mov     ebp,8
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SETREG - SET nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

SETREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                or      reg,BIT_&bit
                mov     ebp,8
                ret

                endm

; --------------------------------------------------------------------
; XORREG - XOR rr rr=[a,b,c,d,e,h,l]

XORREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                xor     dh,reg
                mov     al,dh
                mov     ebp,4
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
                mov     ebp,7
                mov     dl,[offset LOGICAL_table+eax]
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
                mov     ebp,16                          ; clock 3 U
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
; NEG

OPNEG           macro   opcode

emul&opcode:    
                mov     al,dh                           
                inc     edi
                mov     ebp,8
                mov     dx,[offset NEG_table+eax*2]
                ret

                endm

; --------------------------------------------------------------------
; LDIXDDREG - LD (IX+dd),rr     rr=[a,b,c,d,e,h,l]

LDIXDDREG       macro   opcode,reg

emul&opcode:
                inc     edi
                call    fetch
                mov     ecx,regeix
                inc     edi
                add     cx,ax
                mov     al,reg
                call    writemem
                mov     ebp,19
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
                shr     al,4
                and     bl,0fh                        
                mov     bh,dh                         
                and     dh,0f0h
                shl     bh,4
                or      dh,bl
                or      al,bh
                call    writemem
                mov     al,dh
                and     dl,1
                mov     ebp,18
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; LDREGREG - LD rr,rr rr=[b,c,d,e,h,l]

LDREGREG        macro   opcode,reg1,reg2

emul&opcode:
                inc     edi
                mov     bl,reg2
                mov     ebp,4
                mov     reg1,bl
                ret

                endm

; --------------------------------------------------------------------
; LDREGA - LD rr,A rr=[b,c,d,e,h,l]

LDREGA          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     reg,dh
                mov     ebp,4
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
                mov     ebp,7
                ret

                endm

; --------------------------------------------------------------------
; LDHLREG - LD (HL),rr rr=[a,b,c,d,e,h,l]

LDHLREG         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     al,reg
                mov     ecx,regehl
                mov     ebp,7
                call    writemem
                ret

                endm

; --------------------------------------------------------------------
; LDAREG - LD A,rr rr=[a,b,c,d,e,h,l]

LDAREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dh,reg
                mov     ebp,4
                ret

                endm

; --------------------------------------------------------------------
; LDAI - LD A,I

LDAI            macro   opcode

emul&opcode:    
                inc     edi
                mov     dh,regi
                mov     ebp,9
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
                mov     ebp,9
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                ret

                endm
