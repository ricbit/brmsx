; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pset.inc
include psetCB.inc
include psetDD.inc
include psetED.inc
include psetFD.inc

public pset

; print opcodes routines ---------------------------------------------
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

PRINTOP422      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     edx,3
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

; --------------------------------------------------------------------

printopcode:
                mov     ebp,4
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                push    edx
                call    fetch
                call    printhex2
                call    printspace
                pop     edx
                dec     ebp
                dec     edx
                jz      printopcode0

                inc     edi
                call    fetch
                call    printhex2
                call    printspace
                ret
printopcode0:
                push    ebp
                call    printspace
                call    printspace
                call    printspace
                pop     ebp
                dec     ebp
                jnz     printopcode0
                ret

; --------------------------------------------------------------------

prinCB:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetCBxx+eax*4]

prinDD:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetDDxx+eax*4]

prinED:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetEDxx+eax*4]

prinFD:         movzx   edi,regpc
                inc     edi
                call    fetch
                dec     edi
                jmp     [offset psetFDxx+eax*4]

PRINTOP100      00,'NOP$'
PRINTOP312      01,'LD BC,$'
PRINTOP100      02,'LD (BC),A$'
PRINTOP100      03,'INC BC$'
PRINTOP100      04,'INC B$'
PRINTOP100      05,'DEC B$'
PRINTOP211      06,'LD B,$'
PRINTOP100      07,'RLCA$'
PRINTOP100      08,'EX AF,AF''$'
PRINTOP100      09,'ADD HL,BC$'
PRINTOP100      0A,'LD A,(BC)$'
PRINTOP100      0B,'DEC BC$'
PRINTOP100      0C,'INC C$'
PRINTOP100      0D,'DEC C$'
PRINTOP211      0E,'LD C,$'
PRINTOP100      0F,'RRCA$'
PRINTOP211      10,'DJNZ $'
PRINTOP312      11,'LD DE,$'
PRINTOP100      12,'LD (DE),A$'
PRINTOP100      13,'INC DE$'
PRINTOP100      14,'INC D$'
PRINTOP100      15,'DEC D$'
PRINTOP211      16,'LD D,$'
PRINTOP100      17,'RLA$'
PRINTOP211      18,'JR $'
PRINTOP100      19,'ADD HL,DE$'
PRINTOP100      1A,'LD A,(DE)$'
PRINTOP100      1B,'DEC DE$'
PRINTOP100      1C,'INC E$'
PRINTOP100      1D,'DEC E$'
PRINTOP211      1E,'LD E,$'
PRINTOP100      1F,'RRA$'
PRINTOP211      20,'JR NZ,$'
PRINTOP312      21,'LD HL,$'
PRINTOP322      22,'LD ($','),HL$'
PRINTOP100      23,'INC HL$'
PRINTOP100      24,'INC H$'
PRINTOP100      25,'DEC H$'
PRINTOP211      26,'LD H,$'
PRINTOP211      28,'JR Z,$'
PRINTOP100      29,'ADD HL,HL$'
PRINTOP322      2A,'LD HL,($',')$'
PRINTOP100      2B,'DEC HL$'
PRINTOP100      2C,'INC L$'
PRINTOP100      2D,'DEC L$'
PRINTOP211      2E,'LD L,$'
PRINTOP100      2F,'CPL$'
PRINTOP211      30,'JR NC,$'
PRINTOP312      31,'LD SP,$'
PRINTOP322      32,'LD ($','),A$'
PRINTOP100      34,'INC (HL)$'
PRINTOP100      35,'DEC (HL)$'
PRINTOP211      36,'LD (HL),$'
PRINTOP100      37,'SCF$'
PRINTOP211      38,'JR C,$'
PRINTOP100      39,'ADD HL,SP$'
PRINTOP322      3A,'LD A,($',')$'
PRINTOP100      3C,'INC A$'
PRINTOP100      3D,'DEC A$'
PRINTOP211      3E,'LD A,$'
PRINTOP100      3F,'CCF$'
PRINTOP100      42,'LD B,D$'
PRINTOP100      44,'LD B,H$'
PRINTOP100      46,'LD B,(HL)$'
PRINTOP100      47,'LD B,A$'
PRINTOP100      48,'LD C,B$'
PRINTOP100      4B,'LD C,E$'
PRINTOP100      4D,'LD C,L$'
PRINTOP100      4E,'LD C,(HL)$'
PRINTOP100      4F,'LD C,A$'                
PRINTOP100      50,'LD D,B$'
PRINTOP100      53,'LD D,E$'
PRINTOP100      54,'LD D,H$'
PRINTOP100      56,'LD D,(HL)$'
PRINTOP100      57,'LD D,A$'
PRINTOP100      59,'LD E,C$'
PRINTOP100      5A,'LD E,D$'
PRINTOP100      5C,'LD E,H$'
PRINTOP100      5D,'LD E,L$'
PRINTOP100      5E,'LD E,(HL)$'
PRINTOP100      5F,'LD E,A$'
PRINTOP100      60,'LD H,B$'
PRINTOP100      62,'LD H,D$'
PRINTOP100      66,'LD H,(HL)$'
PRINTOP100      67,'LD H,A$'
PRINTOP100      68,'LD L,B$'
PRINTOP100      69,'LD L,C$'
PRINTOP100      6B,'LD L,E$'
PRINTOP100      6F,'LD L,A$'
PRINTOP100      70,'LD (HL),B$'
PRINTOP100      71,'LD (HL),C$'
PRINTOP100      72,'LD (HL),D$'
PRINTOP100      73,'LD (HL),E$'
PRINTOP100      74,'LD (HL),H$'
PRINTOP100      77,'LD (HL),A$'
PRINTOP100      78,'LD A,B$'
PRINTOP100      79,'LD A,C$'
PRINTOP100      7A,'LD A,D$'
PRINTOP100      7B,'LD A,E$'
PRINTOP100      7C,'LD A,H$'
PRINTOP100      7D,'LD A,L$'
PRINTOP100      7E,'LD A,(HL)$'
PRINTOP100      80,'ADD A,B$'
PRINTOP100      83,'ADD A,E$'
PRINTOP100      86,'ADD A,(HL)$'
PRINTOP100      87,'ADD A,A$'
PRINTOP100      8F,'ADC A,A$'
PRINTOP100      90,'SUB B$'
PRINTOP100      91,'SUB C$'
PRINTOP100      92,'SUB D$'
PRINTOP100      93,'SUB E$'
PRINTOP100      95,'SUB L$'
PRINTOP100      98,'SBC A,B$'
PRINTOP100      9A,'SBC A,D$'
PRINTOP100      9C,'SBC A,H$'
PRINTOP100      9F,'SBC A,A$'
PRINTOP100      A1,'AND C$'
PRINTOP100      A3,'AND E$'
PRINTOP100      A4,'AND H$'
PRINTOP100      A5,'AND L$'
PRINTOP100      A6,'AND (HL)$'
PRINTOP100      A7,'AND A$'
PRINTOP100      AE,'XOR (HL)$'
PRINTOP100      AF,'XOR A$'
PRINTOP100      B0,'OR B$'
PRINTOP100      B1,'OR C$'
PRINTOP100      B3,'OR E$'
PRINTOP100      B4,'OR H$'
PRINTOP100      B5,'OR L$'
PRINTOP100      B6,'OR (HL)$'
PRINTOP100      B7,'OR A$'
PRINTOP100      B8,'CP B$'
PRINTOP100      B9,'CP C$'
PRINTOP100      BA,'CP D$'
PRINTOP100      BB,'CP E$'
PRINTOP100      BC,'CP H$'
PRINTOP100      BD,'CP L$'
PRINTOP100      BE,'CP (HL)$'
PRINTOP100      BF,'CP A$'
PRINTOP100      C0,'RET NZ$'
PRINTOP100      C1,'POP BC$'    
PRINTOP312      C2,'JP NZ,$'
PRINTOP312      C3,'JP $'
PRINTOP312      C4,'CALL NZ,$'
PRINTOP100      C5,'PUSH BC$'
PRINTOP211      C6,'ADD A,$'
PRINTOP100      C8,'RET Z$'
PRINTOP100      C9,'RET$'
PRINTOP312      CA,'JP Z,$'
PRINTOP312      CC,'CALL Z,$'
PRINTOP312      CD,'CALL $'
PRINTOP100      CF,'RST 08$'
PRINTOP100      D0,'RET NC$'
PRINTOP100      D1,'POP DE$'
PRINTOP312      D2,'JP NC,$'
PRINTOP221      D3,'OUT ($','),A$'
PRINTOP312      D4,'CALL NC,$'
PRINTOP100      D5,'PUSH DE$'
PRINTOP211      D6,'SUB $'
PRINTOP100      D7,'RST 10$'
PRINTOP100      D8,'RET C$'
PRINTOP100      D9,'EXX$'
PRINTOP312      DA,'JP C,$'
PRINTOP221      DB,'IN A,($',')$'
PRINTOP312      DC,'CALL C,$'
PRINTOP100      DF,'RST 18$'
PRINTOP100      E1,'POP HL$'
PRINTOP100      E3,'EX (SP),HL$'
PRINTOP100      E5,'PUSH HL$'
PRINTOP211      E6,'AND $'
PRINTOP100      E7,'RST 20$'
PRINTOP100      EB,'EX DE,HL$'
PRINTOP211      EE,'XOR $'
PRINTOP100      EF,'RST 28$'
PRINTOP100      F0,'RET P$'
PRINTOP100      F1,'POP AF$'
PRINTOP312      F2,'JP P,$'
PRINTOP100      F3,'DI$'
PRINTOP100      F5,'PUSH AF$'
PRINTOP211      F6,'OR $'
PRINTOP100      F8,'RET M$'
PRINTOP100      F9,'LD SP,HL$'
PRINTOP312      FA,'JP M,$'
PRINTOP100      FB,'EI$'
PRINTOP312      FC,'CALL M,$'
PRINTOP211      FE,'CP $'
PRINTOP100      FF,'RST 38$'
PRINTOP200      CB01,'RLC C$'
PRINTOP200      CB11,'RL C$'
PRINTOP200      CB19,'RR C$'
PRINTOP200      CB1C,'RR H$'
PRINTOP200      CB21,'SLA C$'
PRINTOP200      CB4F,'BIT 1,A$'
PRINTOP200      CB63,'BIT 4,E$'
PRINTOP200      CBC1,'SET 0,C$'
PRINTOP200      DDE1,'POP IX$'
PRINTOP200      DDE5,'PUSH IX$'
PRINTOP422      ED53,'LD ($','),DE$'
PRINTOP200      ED56,'IM 1$'
PRINTOP422      ED5B,'LD DE,($',')$'
PRINTOP422      ED73,'LD ($','),SP$'
PRINTOP200      EDB0,'LDIR$'
PRINTOP200      FDE1,'POP IY$'
PRINTOP200      FDE5,'PUSH IY$'
PRINTOP100      XX,'not emulated yet$'

; --------------------------------------------------------------------

code32          ends
                end

