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
include psetDDCB.inc
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

prinDDCB:       movzx   edi,regpc
                add     edi,3
                call    fetch
                sub     edi,3
                jmp     [offset psetDDCBxx+eax*4]

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
PRINTOP100      27,'DAA$'
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
PRINTOP100      33,'INC SP$'
PRINTOP100      34,'INC (HL)$'
PRINTOP100      35,'DEC (HL)$'
PRINTOP211      36,'LD (HL),$'
PRINTOP100      37,'SCF$'
PRINTOP211      38,'JR C,$'
PRINTOP100      39,'ADD HL,SP$'
PRINTOP322      3A,'LD A,($',')$'
PRINTOP100      3B,'DEC SP$'
PRINTOP100      3C,'INC A$'
PRINTOP100      3D,'DEC A$'
PRINTOP211      3E,'LD A,$'
PRINTOP100      3F,'CCF$'
PRINTOP100      40,'LD B,B$'
PRINTOP100      41,'LD B,C$'
PRINTOP100      42,'LD B,D$'
PRINTOP100      43,'LD B,E$'
PRINTOP100      44,'LD B,H$'
PRINTOP100      45,'LD B,L$'
PRINTOP100      46,'LD B,(HL)$'
PRINTOP100      47,'LD B,A$'
PRINTOP100      48,'LD C,B$'
PRINTOP100      49,'LD C,C$'
PRINTOP100      4A,'LD C,D$'
PRINTOP100      4B,'LD C,E$'
PRINTOP100      4C,'LD C,H$'    
PRINTOP100      4D,'LD C,L$'
PRINTOP100      4E,'LD C,(HL)$'
PRINTOP100      4F,'LD C,A$'                
PRINTOP100      50,'LD D,B$'
PRINTOP100      51,'LD D,C$'
PRINTOP100      52,'LD D,D$'
PRINTOP100      53,'LD D,E$'
PRINTOP100      54,'LD D,H$'
PRINTOP100      55,'LD D,L$'
PRINTOP100      56,'LD D,(HL)$'
PRINTOP100      57,'LD D,A$'
PRINTOP100      58,'LD E,B$'
PRINTOP100      59,'LD E,C$'
PRINTOP100      5A,'LD E,D$'
PRINTOP100      5B,'LD E,E$'
PRINTOP100      5C,'LD E,H$'
PRINTOP100      5D,'LD E,L$'
PRINTOP100      5E,'LD E,(HL)$'
PRINTOP100      5F,'LD E,A$'
PRINTOP100      60,'LD H,B$'
PRINTOP100      61,'LD H,C$'
PRINTOP100      62,'LD H,D$'
PRINTOP100      63,'LD H,E$'
PRINTOP100      64,'LD H,H$'
PRINTOP100      65,'LD H,L$'
PRINTOP100      66,'LD H,(HL)$'
PRINTOP100      67,'LD H,A$'
PRINTOP100      68,'LD L,B$'
PRINTOP100      69,'LD L,C$'
PRINTOP100      6A,'LD L,D$'
PRINTOP100      6B,'LD L,E$'
PRINTOP100      6C,'LD L,H$'
PRINTOP100      6D,'LD L,L$'
PRINTOP100      6E,'LD L,(HL)$'
PRINTOP100      6F,'LD L,A$'
PRINTOP100      70,'LD (HL),B$'
PRINTOP100      71,'LD (HL),C$'
PRINTOP100      72,'LD (HL),D$'
PRINTOP100      73,'LD (HL),E$'
PRINTOP100      74,'LD (HL),H$'
PRINTOP100      75,'LD (HL),L$'
PRINTOP100      76,'HALT$'
PRINTOP100      77,'LD (HL),A$'
PRINTOP100      78,'LD A,B$'
PRINTOP100      79,'LD A,C$'
PRINTOP100      7A,'LD A,D$'
PRINTOP100      7B,'LD A,E$'
PRINTOP100      7C,'LD A,H$'
PRINTOP100      7D,'LD A,L$'
PRINTOP100      7E,'LD A,(HL)$'
PRINTOP100      7F,'LD A,A$'
PRINTOP100      80,'ADD A,B$'
PRINTOP100      81,'ADD A,C$'
PRINTOP100      82,'ADD A,D$'
PRINTOP100      83,'ADD A,E$'
PRINTOP100      84,'ADD A,h$'
PRINTOP100      85,'ADD A,L$'
PRINTOP100      86,'ADD A,(HL)$'
PRINTOP100      87,'ADD A,A$'
PRINTOP100      88,'ADC A,B$'
PRINTOP100      89,'ADC A,C$'
PRINTOP100      8A,'ADC A,D$'
PRINTOP100      8B,'ADC A,E$'
PRINTOP100      8C,'ADC A,H$'
PRINTOP100      8D,'ADC A,L$'
PRINTOP100      8E,'ADC A,(HL)$'
PRINTOP100      8F,'ADC A,A$'
PRINTOP100      90,'SUB B$'
PRINTOP100      91,'SUB C$'
PRINTOP100      92,'SUB D$'
PRINTOP100      93,'SUB E$'
PRINTOP100      94,'SUB H$'
PRINTOP100      95,'SUB L$'
PRINTOP100      96,'SUB (HL)$'
PRINTOP100      97,'SUB A$'
PRINTOP100      98,'SBC A,B$'
PRINTOP100      99,'SBC A,C$'
PRINTOP100      9A,'SBC A,D$'
PRINTOP100      9B,'SBC A,E$'
PRINTOP100      9C,'SBC A,H$'
PRINTOP100      9D,'SBC A,L$'
PRINTOP100      9E,'SBC A,(HL)$'
PRINTOP100      9F,'SBC A,A$'
PRINTOP100      A0,'AND B$'
PRINTOP100      A1,'AND C$'
PRINTOP100      A2,'AND D$'
PRINTOP100      A3,'AND E$'
PRINTOP100      A4,'AND H$'
PRINTOP100      A5,'AND L$'
PRINTOP100      A6,'AND (HL)$'
PRINTOP100      A7,'AND A$'
PRINTOP100      A8,'XOR B$'
PRINTOP100      A9,'XOR C$'
PRINTOP100      AA,'XOR D$'
PRINTOP100      AB,'XOR E$'
PRINTOP100      AC,'XOR H$'
PRINTOP100      AD,'XOR L$'
PRINTOP100      AE,'XOR (HL)$'
PRINTOP100      AF,'XOR A$'
PRINTOP100      B0,'OR B$'
PRINTOP100      B1,'OR C$'
PRINTOP100      B2,'OR D$'
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
PRINTOP211      CE,'ADC A,$'
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
PRINTOP211      DE,'SBC A,$'
PRINTOP100      DF,'RST 18$'
PRINTOP100      E0,'RET PO$'
PRINTOP100      E1,'POP HL$'
PRINTOP312      E2,'JP PO,$'
PRINTOP100      E3,'EX (SP),HL$'
PRINTOP100      E5,'PUSH HL$'
PRINTOP211      E6,'AND $'
PRINTOP100      E7,'RST 20$'
PRINTOP100      E8,'RET PE$'
PRINTOP100      E9,'JP (HL)$'
PRINTOP312      EA,'JP PO,$'
PRINTOP100      EB,'EX DE,HL$'
PRINTOP211      EE,'XOR $'
PRINTOP100      EF,'RST 28$'
PRINTOP100      F0,'RET P$'
PRINTOP100      F1,'POP AF$'
PRINTOP312      F2,'JP P,$'
PRINTOP100      F3,'DI$'
PRINTOP312      F4,'CALL P,$'
PRINTOP100      F5,'PUSH AF$'
PRINTOP211      F6,'OR $'
PRINTOP100      F7,'RST 30$'
PRINTOP100      F8,'RET M$'
PRINTOP100      F9,'LD SP,HL$'
PRINTOP312      FA,'JP M,$'
PRINTOP100      FB,'EI$'
PRINTOP312      FC,'CALL M,$'
PRINTOP211      FE,'CP $'
PRINTOP100      FF,'RST 38$'
PRINTOP200      CB00,'RLC B$'
PRINTOP200      CB01,'RLC C$'
PRINTOP200      CB02,'RLC D$'
PRINTOP200      CB03,'RLC E$'
PRINTOP200      CB04,'RLC H$'
PRINTOP200      CB05,'RLC L$'
PRINTOP200      CB06,'RLC (HL)$'
PRINTOP200      CB07,'RLC A$'
PRINTOP200      CB08,'RLC B$'
PRINTOP200      CB09,'RLC C$'
PRINTOP200      CB0A,'RLC D$'
PRINTOP200      CB0B,'RLC E$'
PRINTOP200      CB0C,'RLC H$'
PRINTOP200      CB0D,'RLC L$'
PRINTOP200      CB0E,'RLC (HL)$'
PRINTOP200      CB0F,'RLC A$'
PRINTOP200      CB10,'RL B$'
PRINTOP200      CB11,'RL C$'
PRINTOP200      CB12,'RL D$'
PRINTOP200      CB13,'RL E$'
PRINTOP200      CB14,'RL H$'
PRINTOP200      CB15,'RL L$'
PRINTOP200      CB16,'RL (HL)$'
PRINTOP200      CB17,'RL A$'
PRINTOP200      CB18,'RR B$'
PRINTOP200      CB19,'RR C$'
PRINTOP200      CB1A,'RR D$'
PRINTOP200      CB1B,'RR E$'
PRINTOP200      CB1C,'RR H$'
PRINTOP200      CB1D,'RR L$'
PRINTOP200      CB1E,'RR (HL)$'
PRINTOP200      CB1F,'RR A$'
PRINTOP200      CB20,'SLA B$'
PRINTOP200      CB21,'SLA C$'
PRINTOP200      CB22,'SLA D$'
PRINTOP200      CB23,'SLA E$'
PRINTOP200      CB24,'SLA H$'
PRINTOP200      CB25,'SLA L$'
PRINTOP200      CB26,'SLA (HL)$'
PRINTOP200      CB27,'SLA A$'
PRINTOP200      CB38,'SRL B$'
PRINTOP200      CB39,'SRL C$'
PRINTOP200      CB3A,'SRL D$'
PRINTOP200      CB3B,'SRL E$'
PRINTOP200      CB3C,'SRL H$'
PRINTOP200      CB3D,'SRL L$'
PRINTOP200      CB3F,'SRL A$'
PRINTOP200      CB40,'BIT 0,B$'
PRINTOP200      CB41,'BIT 0,C$'
PRINTOP200      CB42,'BIT 0,D$'
PRINTOP200      CB43,'BIT 0,E$'
PRINTOP200      CB44,'BIT 0,H$'
PRINTOP200      CB45,'BIT 0,L$'
PRINTOP200      CB46,'BIT 0,(HL)$'
PRINTOP200      CB47,'BIT 0,A$'
PRINTOP200      CB48,'BIT 1,B$'
PRINTOP200      CB49,'BIT 1,C$'
PRINTOP200      CB4A,'BIT 1,D$'
PRINTOP200      CB4B,'BIT 1,E$'
PRINTOP200      CB4C,'BIT 1,H$'
PRINTOP200      CB4D,'BIT 1,L$'
PRINTOP200      CB4E,'BIT 1,(HL)$'
PRINTOP200      CB4F,'BIT 1,A$'
PRINTOP200      CB50,'BIT 2,B$'
PRINTOP200      CB51,'BIT 2,C$'
PRINTOP200      CB52,'BIT 2,D$'
PRINTOP200      CB53,'BIT 2,E$'
PRINTOP200      CB54,'BIT 2,H$'
PRINTOP200      CB55,'BIT 2,L$'
PRINTOP200      CB56,'BIT 2,(HL)$'
PRINTOP200      CB57,'BIT 2,A$'
PRINTOP200      CB58,'BIT 3,B$'
PRINTOP200      CB59,'BIT 3,C$'
PRINTOP200      CB5A,'BIT 3,D$'
PRINTOP200      CB5B,'BIT 3,E$'
PRINTOP200      CB5C,'BIT 3,H$'
PRINTOP200      CB5D,'BIT 3,L$'
PRINTOP200      CB5E,'BIT 3,(HL)$'
PRINTOP200      CB5F,'BIT 3,A$'
PRINTOP200      CB60,'BIT 4,B$'
PRINTOP200      CB61,'BIT 4,C$'
PRINTOP200      CB62,'BIT 4,D$'
PRINTOP200      CB63,'BIT 4,E$'
PRINTOP200      CB64,'BIT 4,H$'
PRINTOP200      CB65,'BIT 4,L$'
PRINTOP200      CB66,'BIT 4,(HL)$'
PRINTOP200      CB67,'BIT 4,A$'
PRINTOP200      CB68,'BIT 5,B$'
PRINTOP200      CB69,'BIT 5,C$'
PRINTOP200      CB6A,'BIT 5,D$'
PRINTOP200      CB6B,'BIT 5,E$'
PRINTOP200      CB6C,'BIT 5,H$'
PRINTOP200      CB6D,'BIT 5,L$'
PRINTOP200      CB6E,'BIT 5,(HL)$'
PRINTOP200      CB6F,'BIT 5,A$'
PRINTOP200      CB70,'BIT 6,B$'
PRINTOP200      CB71,'BIT 6,C$'
PRINTOP200      CB72,'BIT 6,D$'
PRINTOP200      CB73,'BIT 6,E$'
PRINTOP200      CB74,'BIT 6,H$'
PRINTOP200      CB75,'BIT 6,L$'
PRINTOP200      CB76,'BIT 6,(HL)$'
PRINTOP200      CB77,'BIT 6,A$'
PRINTOP200      CB78,'BIT 7,B$'
PRINTOP200      CB79,'BIT 7,C$'
PRINTOP200      CB7A,'BIT 7,D$'
PRINTOP200      CB7B,'BIT 7,E$'
PRINTOP200      CB7C,'BIT 7,H$'
PRINTOP200      CB7D,'BIT 7,L$'
PRINTOP200      CB7E,'BIT 7,(HL)$'
PRINTOP200      CB7F,'BIT 7,A$'
PRINTOP200      CB80,'RES 0,B$'
PRINTOP200      CB81,'RES 0,C$'
PRINTOP200      CB82,'RES 0,D$'
PRINTOP200      CB83,'RES 0,E$'
PRINTOP200      CB84,'RES 0,H$'
PRINTOP200      CB85,'RES 0,L$'
PRINTOP200      CB86,'RES 0,(HL)$'
PRINTOP200      CB87,'RES 0,A$'
PRINTOP200      CB88,'RES 1,B$'
PRINTOP200      CB89,'RES 1,C$'
PRINTOP200      CB8A,'RES 1,D$'
PRINTOP200      CB8B,'RES 1,E$'
PRINTOP200      CB8C,'RES 1,H$'
PRINTOP200      CB8D,'RES 1,L$'
PRINTOP200      CB8E,'RES 1,(HL)$'
PRINTOP200      CB8F,'RES 1,A$'
PRINTOP200      CB90,'RES 2,B$'
PRINTOP200      CB91,'RES 2,C$'
PRINTOP200      CB92,'RES 2,D$'
PRINTOP200      CB93,'RES 2,E$'
PRINTOP200      CB94,'RES 2,H$'
PRINTOP200      CB95,'RES 2,L$'
PRINTOP200      CB96,'RES 2,(HL)$'
PRINTOP200      CB97,'RES 2,A$'
PRINTOP200      CB98,'RES 3,B$'
PRINTOP200      CB99,'RES 3,C$'
PRINTOP200      CB9A,'RES 3,D$'
PRINTOP200      CB9B,'RES 3,E$'
PRINTOP200      CB9C,'RES 3,H$'
PRINTOP200      CB9D,'RES 3,L$'
PRINTOP200      CB9E,'RES 3,(HL)$'
PRINTOP200      CB9F,'RES 3,A$'
PRINTOP200      CBA0,'RES 4,B$'
PRINTOP200      CBA1,'RES 4,C$'
PRINTOP200      CBA2,'RES 4,D$'
PRINTOP200      CBA3,'RES 4,E$'
PRINTOP200      CBA4,'RES 4,H$'
PRINTOP200      CBA5,'RES 4,L$'
PRINTOP200      CBA6,'RES 4,(HL)$'
PRINTOP200      CBA7,'RES 4,A$'
PRINTOP200      CBA8,'RES 5,B$'
PRINTOP200      CBA9,'RES 5,C$'
PRINTOP200      CBAA,'RES 5,D$'
PRINTOP200      CBAB,'RES 5,E$'
PRINTOP200      CBAC,'RES 5,H$'
PRINTOP200      CBAD,'RES 5,L$'
PRINTOP200      CBAE,'RES 5,(HL)$'
PRINTOP200      CBAF,'RES 5,A$'
PRINTOP200      CBB0,'RES 6,B$'
PRINTOP200      CBB1,'RES 6,C$'
PRINTOP200      CBB2,'RES 6,D$'
PRINTOP200      CBB3,'RES 6,E$'
PRINTOP200      CBB4,'RES 6,H$'
PRINTOP200      CBB5,'RES 6,L$'
PRINTOP200      CBB6,'RES 6,(HL)$'
PRINTOP200      CBB7,'RES 6,A$'
PRINTOP200      CBB8,'RES 7,B$'
PRINTOP200      CBB9,'RES 7,C$'
PRINTOP200      CBBA,'RES 7,D$'
PRINTOP200      CBBB,'RES 7,E$'
PRINTOP200      CBBC,'RES 7,H$'
PRINTOP200      CBBD,'RES 7,L$'
PRINTOP200      CBBE,'RES 7,(HL)$'
PRINTOP200      CBBF,'RES 7,A$'
PRINTOP200      CBC0,'SET 0,B$'
PRINTOP200      CBC1,'SET 0,C$'
PRINTOP200      CBC2,'SET 0,D$'
PRINTOP200      CBC3,'SET 0,E$'
PRINTOP200      CBC4,'SET 0,H$'
PRINTOP200      CBC5,'SET 0,L$'
PRINTOP200      CBC6,'SET 0,(HL)$'
PRINTOP200      CBC7,'SET 0,A$'
PRINTOP200      CBC8,'SET 1,B$'
PRINTOP200      CBC9,'SET 1,C$'
PRINTOP200      CBCA,'SET 1,D$'
PRINTOP200      CBCB,'SET 1,E$'
PRINTOP200      CBCC,'SET 1,H$'
PRINTOP200      CBCD,'SET 1,L$'
PRINTOP200      CBCE,'SET 1,(HL)$'
PRINTOP200      CBCF,'SET 1,A$'
PRINTOP200      CBD0,'SET 2,B$'
PRINTOP200      CBD1,'SET 2,C$'
PRINTOP200      CBD2,'SET 2,D$'
PRINTOP200      CBD3,'SET 2,E$'
PRINTOP200      CBD4,'SET 2,H$'
PRINTOP200      CBD5,'SET 2,L$'
PRINTOP200      CBD6,'SET 2,(HL)$'
PRINTOP200      CBD7,'SET 2,A$'
PRINTOP200      CBD8,'SET 3,B$'
PRINTOP200      CBD9,'SET 3,C$'
PRINTOP200      CBDA,'SET 3,D$'
PRINTOP200      CBDB,'SET 3,E$'
PRINTOP200      CBDC,'SET 3,H$'
PRINTOP200      CBDD,'SET 3,L$'
PRINTOP200      CBDE,'SET 3,(HL)$'
PRINTOP200      CBDF,'SET 3,A$'
PRINTOP200      CBE0,'SET 4,B$'
PRINTOP200      CBE1,'SET 4,C$'
PRINTOP200      CBE2,'SET 4,D$'
PRINTOP200      CBE3,'SET 4,E$'
PRINTOP200      CBE4,'SET 4,H$'
PRINTOP200      CBE5,'SET 4,L$'
PRINTOP200      CBE6,'SET 4,(HL)$'
PRINTOP200      CBE7,'SET 4,A$'
PRINTOP200      CBE8,'SET 5,B$'
PRINTOP200      CBE9,'SET 5,C$'
PRINTOP200      CBEA,'SET 5,D$'
PRINTOP200      CBEB,'SET 5,E$'
PRINTOP200      CBEC,'SET 5,H$'
PRINTOP200      CBED,'SET 5,L$'
PRINTOP200      CBEE,'SET 5,(HL)$'
PRINTOP200      CBEF,'SET 5,A$'
PRINTOP200      CBF0,'SET 6,B$'
PRINTOP200      CBF1,'SET 6,C$'
PRINTOP200      CBF2,'SET 6,D$'
PRINTOP200      CBF3,'SET 6,E$'
PRINTOP200      CBF4,'SET 6,H$'
PRINTOP200      CBF5,'SET 6,L$'
PRINTOP200      CBF6,'SET 6,(HL)$'
PRINTOP200      CBF7,'SET 6,A$'
PRINTOP200      CBF8,'SET 7,B$'
PRINTOP200      CBF9,'SET 7,C$'
PRINTOP200      CBFA,'SET 7,D$'
PRINTOP200      CBFB,'SET 7,E$'
PRINTOP200      CBFC,'SET 7,H$'
PRINTOP200      CBFD,'SET 7,L$'
PRINTOP200      CBFE,'SET 7,(HL)$'
PRINTOP200      CBFF,'SET 7,A$'
PRINTOP200      DD09,'ADD IX,BC$'
PRINTOP200      DD19,'ADD IX,DE$'
PRINTOP412      DD21,'LD IX,$'
PRINTOP422      DD22,'LD ($','),IX$'
PRINTOP200      DD23,'INC IX$'
PRINTOP200      DD29,'ADD IX,IX$'
PRINTOP422      DD2A,'LD IX,($',')$'
PRINTOP200      DD2B,'DEC IX$'
PRINTOP321      DD34,'INC (IX+$',')$'
PRINTOP321      DD35,'DEC (IX+$',')$'
PRINTOP421      DD36,'LD (IX+$','),$'
PRINTOP321      DD46,'LD B,(IX+$',')$'
PRINTOP321      DD4E,'LD C,(IX+$',')$'
PRINTOP321      DD56,'LD D,(IX+$',')$'
PRINTOP321      DD5E,'LD E,(IX+$',')$'
PRINTOP321      DD66,'LD H,(IX+$',')$'
PRINTOP321      DD6E,'LD L,(IX+$',')$'
PRINTOP321      DD70,'LD (IX+$','),B$'
PRINTOP321      DD71,'LD (IX+$','),C$'
PRINTOP321      DD72,'LD (IX+$','),D$'
PRINTOP321      DD73,'LD (IX+$','),E$'
PRINTOP321      DD74,'LD (IX+$','),H$'
PRINTOP321      DD75,'LD (IX+$','),L$'
PRINTOP321      DD77,'LD (IX+$','),A$'
PRINTOP321      DD7E,'LD A,(IX+$',')$'
PRINTOP321      DD86,'ADD A,(IX+$',')$'
PRINTOP321      DD96,'SUB (IX+$',')$'
PRINTOP321      DDA6,'AND (IX+$',')$'
PRINTOP321      DDBE,'CP (IX+$',')$'
PRINTOP200      DDE1,'POP IX$'
PRINTOP200      DDE5,'PUSH IX$'
PRINTOP200      DDE9,'JP (IX)$'
PRINTOP42X      DDCB1E,'RR (IX+$',')$'
PRINTOP42X      DDCB46,'BIT 0,(IX+$',')$'
PRINTOP42X      DDCB4E,'BIT 1,(IX+$',')$'
PRINTOP42X      DDCB5E,'BIT 3,(IX+$',')$'
PRINTOP42X      DDCB6E,'BIT 5,(IX+$',')$'
PRINTOP42X      DDCB76,'BIT 6,(IX+$',')$'
PRINTOP42X      DDCB7E,'BIT 7,(IX+$',')$'
PRINTOP42X      DDCBAE,'RES 5,(IX+$',')$'
PRINTOP42X      DDCBFE,'SET 7,(IX+$',')$'
PRINTOP200      ED41,'OUT (C),B$'
PRINTOP200      ED42,'SBC HL,DE$'
PRINTOP422      ED43,'LD ($','),BC$'
PRINTOP200      ED44,'NEG$'
PRINTOP422      ED4B,'LD BC,($',')$'
PRINTOP200      ED4D,'RETI$'
PRINTOP200      ED52,'SBC HL,DE$'
PRINTOP422      ED53,'LD ($','),DE$'
PRINTOP200      ED56,'IM 1$'
PRINTOP200      ED57,'LD A,I$'
PRINTOP422      ED5B,'LD DE,($',')$'
PRINTOP200      ED5F,'LD A,R$'
PRINTOP200      ED62,'SBC HL,HL$'
PRINTOP200      ED67,'RRD$'
PRINTOP200      ED6A,'ADC HL,HL$'
PRINTOP200      ED6F,'RLD$'
PRINTOP422      ED73,'LD ($','),SP$'
PRINTOP200      ED78,'IN A,(C)$'
PRINTOP200      ED79,'OUT (C),A$'
PRINTOP422      ED7B,'LD SP,($',')$'
PRINTOP200      EDA0,'LDI$'
PRINTOP200      EDA3,'OUTI$'
PRINTOP200      EDA8,'LDD$'
PRINTOP200      EDB0,'LDIR$'
PRINTOP200      EDB1,'CPIR$'
PRINTOP200      EDB8,'LDDR$'
PRINTOP200      EDB9,'CPDR$'
PRINTOP200      FD09,'ADD IY,BC$'
PRINTOP200      FD19,'ADD IY,DE$'
PRINTOP412      FD21,'LD IY,$'
PRINTOP422      FD22,'LD ($','),IY$'
PRINTOP200      FD23,'INC IY$'
PRINTOP200      FD29,'ADD IY,IY$'
PRINTOP422      FD2A,'LD IY,($',')$'
PRINTOP200      FD2B,'DEC IY$'
PRINTOP321      FD34,'INC (IY+$',')$'
PRINTOP321      FD35,'DEC (IY+$',')$'
PRINTOP421      FD36,'LD (IY+$','),$'
PRINTOP321      FD46,'LD B,(IY+$',')$'
PRINTOP321      FD4E,'LD C,(IY+$',')$'
PRINTOP321      FD56,'LD D,(IY+$',')$'
PRINTOP321      FD5E,'LD E,(IY+$',')$'
PRINTOP321      FD70,'LD (IY+$','),B$'
PRINTOP321      FD71,'LD (IY+$','),C$'
PRINTOP321      FD72,'LD (IY+$','),D$'
PRINTOP321      FD73,'LD (IY+$','),E$'
PRINTOP321      FD74,'LD (IY+$','),H$'
PRINTOP321      FD75,'LD (IY+$','),L$'
PRINTOP321      FD77,'LD (IY+$','),A$'
PRINTOP321      FD7E,'LD A,(IY+$',')$'
PRINTOP321      FD96,'SUB (IY+$',')$'
PRINTOP321      FDAE,'XOR (IY+$',')$'
PRINTOP321      FDBE,'CP (IY+$',')$'
PRINTOP200      FDE1,'POP IY$'
PRINTOP200      FDE5,'PUSH IY$'
PRINTOP100      XX,'not emulated yet$'

; --------------------------------------------------------------------

code32          ends
                end

