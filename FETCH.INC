; -------------------------------------------------------------------- 

FETCH1          macro   opcode

;                shr     ecx,8
                cmp     ebx,01FFFh
                jne     emul&opcode&_fetch

                call    fetch1
                jmp     emul&opcode&_continue

emul&opcode&_fetch:

                mov     al,[esi+ebx+1]

emul&opcode&_continue:

                endm

; -------------------------------------------------------------------- 

FETCHW1         macro   opcode

                ;shr     ecx,8
                cmp     ebx,01FFEh
                jb      emul&opcode&_fetch

                call    fetchw1
                jmp     emul&opcode&_continue

emul&opcode&_fetch:

                mov     ax,[esi+ebx+1]

emul&opcode&_continue:

                endm
