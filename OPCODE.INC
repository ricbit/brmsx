BITREG          macro   opcode,reg,bit

                inc     edi
                test    reg,BIT_&bit
                setflag_bit
                ret

                endm


