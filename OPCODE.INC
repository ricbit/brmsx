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
; SRLREG - SRL rr rr=[a,b,c,d,e,h,l]

SRLREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     al,reg
                mov     dl,[offset SRL_table+eax]
                shr     reg,1
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
; RESREG - RES nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

RESREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                and     reg,NBIT_&bit
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
; ADCREG - ADC A,rr rr=[a,b,c,d,e,h,l]

ADCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                jmp     adcreg

                endm

adcreg:
                shr     dl,1                            ; clock 2 U
                mov     ch,dh                           ; clock 2 V
                adc     dh,bh                           ; clock 3 U
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
