; print opcodes  routines ---------------------------------------------
; first number is size of instruction
; second number is number of strings
; third number is size of argument

PRINTOP100      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,1
                mov     eax,offset msg&number
                jmp     printmsgp

                endm

PRINTOP200      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,2
                mov     eax,offset msg&number
                jmp     printmsgp

                endm

PRINTOP211      macro   number,desc        

msg&number:     db      desc
prin&number:    mov     isize,2
                mov     eax,offset msg&number
                call    printmsgp
                inc     edi
                call    fetch
                jmp     printhex2p

                endm
                                  
PRINTOP221      macro   number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,2
                mov     eax,offset msg&number&a
                call    printmsgp
                inc     edi
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                jmp     printmsgp

                endm

PRINTOP312      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,3
                mov     eax,offset msg&number
                call    printmsgp
                inc     edi
                call    fetchw
                jmp     printhex4p

                endm

PRINTOP322      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,3
                mov     eax,offset msg&number&a
                call    printmsgp
                inc     edi
                call    fetchw
                call    printhex4p
                mov     eax,offset msg&number&b
                jmp     printmsgp

                endm

PRINTOP321      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,3
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                jmp     printmsgp

                endm

PRINTOP422      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetchw
                call    printhex4p
                mov     eax,offset msg&number&b
                jmp     printmsgp

                endm

PRINTOP421      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                inc     edi
                call    fetch
                jmp     printhex2p

                endm

PRINTOP42X      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                jmp     printmsgp

                endm

PRINTOP412      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,4
                mov     eax,offset msg&number
                call    printmsgp
                add     edi,2
                call    fetchw
                jmp     printhex4p

                endm

