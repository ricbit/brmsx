; -------------------------------------------------------------------- 

FETCH1          macro   opcode

                mov     ebx,offset fetch1
                call    ebx

                endm

; -------------------------------------------------------------------- 

FETCHW1         macro   opcode

                mov     ebx,offset fetchw1
                call    ebx

                endm

; -------------------------------------------------------------------- 

READMEM         macro   

                mov     esi,offset readmem
                call    esi

                endm

; -------------------------------------------------------------------- 

READMEMW        macro   

                mov     esi,offset readmemw
                call    esi

                endm

; -------------------------------------------------------------------- 

WRITEMEM        macro   
                
                mov     esi,offset writemem
                call    esi

                endm

; -------------------------------------------------------------------- 

WRITEMEMW       macro   
                
                mov     esi,offset writememw
                call    esi

                endm
