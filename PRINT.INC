; print opcodes froutines ---------------------------------------------
; first number is size of instruction
; second number is number of strings
; third number is size of argument

PRINTOP100      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,1
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                ret

                endm

PRINTOP200      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                ret

                endm

PRINTOP211      macro number,desc        

msg&number:     db      desc
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetch
                call    printhex2
                ret

                endm
                                  
PRINTOP221      macro   number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,2
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetch
                call    printhex2
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP312      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,3
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetchw
                call    printhex4
                ret

                endm

PRINTOP322      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,3
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                inc     edi
                call    fetchw
                call    printhex4
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP321      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,3
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                add     edi,2
                call    fetch
                call    printhex2
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP422      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,4
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                add     edi,2
                call    fetchw
                call    printhex4
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP421      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,4
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                add     edi,2
                call    fetch
                call    printhex2
                mov     eax,offset msg&number&b
                call    printmsg
                movzx   edi,regpc
                add     edi,3
                call    fetch
                call    printhex2
                ret

                endm

PRINTOP42X      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,4
                call    printopcode
                mov     eax,offset msg&number&a
                call    printmsg
                movzx   edi,regpc
                add     edi,2
                call    fetch
                call    printhex2
                mov     eax,offset msg&number&b
                call    printmsg
                ret

                endm

PRINTOP412      macro number,desc

msg&number:     db      desc
prin&number:    mov     edx,4
                call    printopcode
                mov     eax,offset msg&number
                call    printmsg
                movzx   edi,regpc
                add     edi,2
                call    fetchw
                call    printhex4
                ret

                endm

