; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PSG.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc
include pmode.inc
include pentium.inc

extrn dmabuffer: dword
extrn dmatemp: dword

public init_sound_blaster
public sound_on
public sound_off
public compose_soundstream
public soundenabled
public sound_ack
public sbbaseaddr
public sbirq
public sbdma
public sounddetected
public read_master_volume
public write_master_volume

; DATA ---------------------------------------------------------------

align 4

SKIPFACTOR              equ     6
CONV_FACTOR             equ     336975
BUFFERSIZE              equ     757*SKIPFACTOR

DSP_RESET               dd      06h
DSP_READ_DATA           dd      0Ah
DSP_WRITE_DATA          dd      0Ch
DSP_WRITE_STATUS        dd      0Ch
DSP_DATA_AVAIL          dd      0Eh

DMA_page_table          db      087h,083h,081h,082h

sounddetected           dd      0
soundenabled            dd      0

sbbaseaddr              dd      0220h
sbirq                   dd      5
sbdma                   dd      1
  
dsp_time_cte            dd      235     ; sample rate 45455
dsp_buffer_size         dd      BUFFERSIZE

sb_stub_buf             db      21 dup (0)
oldsbpirqvect           dd      0
oldsbrirqvect           dd      0

irqskip                 dd      0
dmaready                dd      0
waitingsynch            dd      0

PSGcounter              db      4*4 dup (0)
PSGstate                db      4*4 dup (0)
start_counter           db      4*4 dup (0)
PSGvolume               db      4*4 dup (0)
PSGzeroflag             db      4*4 dup (0)
conv_factor             dd      CONV_FACTOR
                        dd      CONV_FACTOR
                        dd      CONV_FACTOR
                        dd      CONV_FACTOR

psgregstack             db      (16*(SKIPFACTOR+1)) dup (0)
PSGreg                  db      16 dup (0)
psgpointer              dd      0

sb_default_pic1         db      0
sb_default_pic2         db      0

; reset_dsp ----------------------------------------------------------
; reset the dsp
; return flag c if any error

reset_dsp:
                mov     edx,DSP_RESET
                mov     al,1
                out     dx,al
                call    delay10

                mov     edx,DSP_RESET
                mov     al,0
                out     dx,al
                call    delay10

                mov     edx,DSP_DATA_AVAIL
                in      al,dx
                test    al,BIT_7
                jz      reset_dsp_failed

                mov     edx,DSP_READ_DATA
                in      al,dx
                cmp     al,0AAh
                jne     reset_dsp_failed

                or      eax,eax
                ret

reset_dsp_failed:
                stc
                ret

; delay10 ------------------------------------------------------------
; make a 10 ms delay

delay10:
                mov     v86r_ah,86h
                mov     v86r_cx,0
                mov     v86r_dx,10
                mov     al,15h
                int     33h
                ret

; init_sound_blaster -------------------------------------------------
; initialise the sb variables 

init_sound_blaster:
                mov     eax,sbbaseaddr
                add     DSP_RESET,eax
                add     DSP_READ_DATA,eax
                add     DSP_WRITE_DATA,eax
                add     DSP_WRITE_STATUS,eax
                add     DSP_DATA_AVAIL,eax
                call    reset_dsp
                ret
  
; init_dma_buffer ----------------------------------------------------
; init the dma buffer
; this version uses a constant tone of about 60 Hz


init_dma_buffer:
                mov     edi,dmabuffer
                mov     ecx,BUFFERSIZE
                mov     al,0
                rep     stosb

                ret

; write_dsp ----------------------------------------------------------
; write a byte in the dsp
; in: bl=byte

write_dsp:
                mov     edx,DSP_WRITE_STATUS     
                
write_dsp_loop:
                in      al,dx              
                test    al,BIT_7
                jnz     write_dsp_loop

                mov     edx,DSP_WRITE_DATA
                mov     al,bl
                out     dx,al

                ret

; play ---------------------------------------------------------------
; turn on the DSP and start DMA transfers to sound board

play:
                mov     eax,sbdma
                or      eax,BIT_2
                mov     dx,0Ah
                out     dx,al

                mov     al,0
                mov     dx,0Ch
                out     dx,al

                mov     eax,(048h or 010h)
                or      eax,sbdma
                mov     dx,0Bh
                out     dx,al

                mov     edi,dmabuffer
                add     edi,_code32a

                mov     eax,edi
                mov     edx,sbdma
                shl     edx,1
                out     dx,al

                shr     eax,8
                out     dx,al

                shr     eax,8
                mov     edx,sbdma
                movzx   edx,byte ptr [offset DMA_page_table+edx]
                out     dx,al

                mov     al,((BUFFERSIZE-1) and 0FFh)
                mov     edx,sbdma
                shl     edx,1
                inc     edx
                out     dx,al

                mov     al,(((BUFFERSIZE-1) shr 8) and 0FFh)
                out     dx,al

                mov     eax,sbdma
                mov     dx,0Ah
                out     dx,al

                mov     bl,040h
                call    write_dsp

                mov     ebx,dsp_time_cte
                call    write_dsp

                mov     bl,048h
                call    write_dsp
                
                mov     bl,((BUFFERSIZE-1) and 0FFh)
                call    write_dsp
                
                mov     bl,(((BUFFERSIZE-1) shr 8) and 0FFh)
                call    write_dsp

                mov     bl,090h
                call    write_dsp

                ret

; sound_ack ----------------------------------------------------------
; acknowledge the sound blaster that the dma is ready
; used to get better synch between the Z80 emulation and 
; the sound emulation

sound_ack:
                cmp     waitingsynch,1
                jne     _ret
                mov     edx,DSP_DATA_AVAIL
                in      al,dx
                mov     waitingsynch,0
                ret

; my_sb_irq_handler --------------------------------------------------
; sound blaster interrupt handler

my_sb_irq_handler:
                cli
                pushad
                push    ds 
                mov     ds,cs:_seldata

                mov     edi,dmabuffer
                mov     esi,dmatemp
                mov     ecx,(BUFFERSIZE+4)/4
                rep     movsd

                cmp     waitingsynch,0
                jne     sbirq1
                mov     edx,DSP_DATA_AVAIL
                in      al,dx

sbirq1:
                
                mov     al,20h
                out     20h,al
                mov     al,20h
                out     0A0h,al

                pop     ds
                popad
                sti
                iretd


; turnon_sbirq -------------------------------------------------------
; turn on the sound blaster interrupt handler

turnon_sbirq:
                mov     ebx,sbirq
                call    _getirqvect
                mov     oldsbpirqvect,edx
                mov     edx,offset my_sb_irq_handler
                call    _setirqvect
                mov     edi,offset sb_stub_buf
                call    _rmpmirqset
                mov     oldsbrirqvect,eax

                mov     dx,021h
                in      al,dx
                mov     sb_default_pic1,al

                mov     dx,0A1h
                in      al,dx
                mov     sb_default_pic2,al

                mov     eax,1
                mov     ecx,sbirq
                shl     eax,cl
                xor     eax,0FFFFFFFFh
                and     al,sb_default_pic1
                mov     dx,021h
                out     dx,al

                ret

; turnoff_sbirq ------------------------------------------------------
; turn off the sound blaster interrupt handler

turnoff_sbirq:
                mov     ebx,sbirq
                mov     eax,oldsbrirqvect
                call    _rmpmirqfree
                mov     edx,oldsbpirqvect
                call    _setirqvect

                call    reset_dsp

                mov     al,sb_default_pic1
                mov     dx,021h
                out     dx,al

                mov     al,sb_default_pic2
                mov     dx,0A1h
                out     dx,al

                ret

; sound_on -----------------------------------------------------------
; turns on the sound system

sound_on:
                cmp     soundenabled,0
                je      _ret
                call    init_dma_buffer
                mov     eax,offset psgregstack
                mov     psgpointer,eax
                mov     eax,SKIPFACTOR
                mov     irqskip,eax
                mov     waitingsynch,1
                call    turnon_sbirq
                call    play
                ret

; sound_off ----------------------------------------------------------
; turns off the sound system

sound_off:
                cmp     soundenabled,0
                je      _ret
                call    turnoff_sbirq
                ret

; read_master_volume -------------------------------------------------
; read the value of the master volume from the sb pro mixer
; output: al= value read (low nibble)

read_master_volume:
                push    edx
                mov     edx,sbbaseaddr
                add     edx,4
                
                ; read the master volume
                mov     al,22h
                out     dx,al
                inc     dx
                in      al,dx
                and     al,0Fh

                pop     edx
                ret

; write_master_volume ------------------------------------------------
; write a value to the master volume 
; input: al= value write (low nibble)

write_master_volume:
                push    edx eax
                mov     edx,sbbaseaddr
                add     edx,4
                mov     ah,al
                and     ah,0Fh

                ; write the master volume
                mov     al,22h
                out     dx,al
                inc     dx
                mov     al,ah
                shl     ah,4
                or      al,ah
                out     dx,al

                pop     eax edx
                ret

; compose_soundstream ------------------------------------------------
; compose the output sound stream
; based on PSG registers

compose_soundstream:
                
                cmp     soundenabled,0
                je      _ret

                pushad
                
                mov     esi,offset psgreg
                mov     edi,psgpointer
                mov     ecx,16
                rep     movsb
                mov     psgpointer,edi

                dec     irqskip
                jnz     compose_soundstream_exit

                mov     eax,offset psgregstack
                mov     psgpointer,eax
                mov     irqskip,SKIPFACTOR
                
                mov     esi,dmatemp
                mov     ecx,BUFFERSIZE
                mov     edx,757+1

compose_soundstream_outer_loop:
                
                push    ecx esi
                mov     esi,psgpointer
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd
                pop     esi ecx
                
                movzx   ebx,word ptr [offset PSGreg+0]
                shl     ebx,16
                mov     dword ptr [offset start_counter+0],ebx

                movzx   ebx,word ptr [offset PSGreg+2]
                shl     ebx,16
                mov     dword ptr [offset start_counter+4],ebx

                movzx   ebx,word ptr [offset PSGreg+4]
                shl     ebx,16
                mov     dword ptr [offset start_counter+8],ebx

compose_soundstream_loop:

                irp     channel,<0,1,2>

                add     dword ptr [offset PSGcounter+channel*4],CONV_FACTOR
                mov     eax,dword ptr [offset PSGcounter+channel*4]
                cmp     eax,dword ptr [offset start_counter+channel*4]
                jle     compose_soundstream_nextchannel_&channel

                cmp     dword ptr [offset start_counter+channel*4],0
                je      compose_soundstream_zero_&channel

                mov     eax,dword ptr [offset start_counter+channel*4]
                sub     dword ptr [offset PSGcounter+channel*4],eax

                cmp     dword ptr [offset PSGstate+channel*4],0
                je      compose_soundstream_levelzero_&channel

                mov     dword ptr [offset PSGstate+channel*4],0
                jmp     compose_soundstream_nextchannel_&channel

compose_soundstream_levelzero_&channel:

                movzx    eax,byte ptr [offset PSGreg+8+channel]
                test     eax,00010000b
                jnz      compose_soundstream_envelope_&channel
                and      eax,0Fh
                add      eax,eax
                mov      dword ptr [offset PSGstate+channel*4],eax
                jmp      compose_soundstream_nextchannel_&channel

compose_soundstream_zero_&channel:
               
                movzx    eax,byte ptr [offset PSGreg+8+channel]
                and      eax,0Fh
                add      eax,eax
                mov      dword ptr [offset PSGstate+channel*4],eax
                mov      dword ptr [offset PSGcounter+channel*4],0
                jmp      compose_soundstream_nextchannel_&channel

compose_soundstream_envelope_&channel:
                mov      dword ptr [offset PSGstate+channel*4],0
                mov      dword ptr [offset PSGcounter+channel*4],0

compose_soundstream_nextchannel_&channel:

                endm

compose_soundstream_mix:

                mov     eax,0
                
                test    byte ptr [offset PSGreg+7],BIT_0
                jnz     compose_soundstream_mix1
                add     eax,dword ptr [offset PSGstate+0*4]

compose_soundstream_mix1:
                
                test    byte ptr [offset PSGreg+7],BIT_1
                jnz     compose_soundstream_mix2
                add     eax,dword ptr [offset PSGstate+1*4]

compose_soundstream_mix2:
                
                test    byte ptr [offset PSGreg+7],BIT_2
                jnz     compose_soundstream_next       
                add     eax,dword ptr [offset PSGstate+2*4]

compose_soundstream_next:

                mov     [esi],al
                inc     esi
                
                dec     edx
                jz      compose_soundstream_nextint
                
                dec     ecx
                jnz     compose_soundstream_loop

                mov     eax,offset psgregstack
                mov     psgpointer,eax

compose_soundstream_exit:                

                mov     dmaready,1
                
                popad
                ret

compose_soundstream_nextint:
                dec     ecx
                add     psgpointer,16
                mov     edx,757
                jmp     compose_soundstream_outer_loop

; compose_soundstream_MMX --------------------------------------------
; compose the output sound stream (MMX version)
; based on PSG registers

compose_soundstream_MMX:

                pushad
                
                mov     esi,offset psgreg
                mov     edi,psgpointer
                mov     ecx,16
                rep     movsb
                mov     psgpointer,edi

                dec     irqskip
                jnz     compose_soundstream_exit

                mov     eax,offset psgregstack
                mov     psgpointer,eax
                mov     irqskip,SKIPFACTOR
                
                mov     esi,dmatemp
                mov     ecx,BUFFERSIZE
                mov     edx,757+1

compose_soundstream_outer_loop_MMX:
                
                push    ecx esi
                mov     esi,psgpointer
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd
                pop     esi ecx
                
                movzx   ebx,word ptr [offset PSGreg+0]
                shl     ebx,16
                mov     dword ptr [offset start_counter+0],ebx

                movzx   ebx,word ptr [offset PSGreg+2]
                shl     ebx,16
                mov     dword ptr [offset start_counter+4],ebx

                movzx   ebx,word ptr [offset PSGreg+4]
                shl     ebx,16
                mov     dword ptr [offset start_counter+8],ebx

                ; soundinit MMX

                ;movq    mm0,qword ptr [offset PSGcounter+0]
                movq    
                db      00000101b
                dd      offset PSGcounter+0

                ;movq    mm4,qword ptr [offset PSGcounter+8]
                movq    
                db      00100101b
                dd      offset PSGcounter+8

                ;movq    mm1,qword ptr [offset start_counter+0]
                movq    
                db      00001101b
                dd      offset start_counter+0
                
                ;movq    mm5,qword ptr [offset start_counter+8]
                movq    
                db      00101101b
                dd      offset start_counter+8

                ;movq    mm3,qword ptr [offset PSGstate+0]
                movq
                db      00011101b
                dd      offset PSGstate+0

                ;movq    mm7,qword ptr [offset PSGstate+8]
                movq
                db      00111101b
                dd      offset PSGstate+8

                irp     channel,<0,1,2>

                movzx   eax,byte ptr [offset PSGreg+8+channel]
                and     eax,0Fh
                add     eax,eax
                mov     dword ptr [offset PSGvolume+channel*4],eax

                mov     eax,dword ptr [offset start_counter+channel*4]
                cmp     eax,0
                je      compose_soundstream_MMX_zeroflag_&channel
                mov     eax,0FFFFFFFFh
compose_soundstream_MMX_zeroflag_&channel:
                mov     dword ptr [offset PSGzeroflag+channel*4],eax

                cmp     dword ptr [offset PSGstate+channel*4],0
                je      compose_soundstream_MMX_zerocheck_&channel
                mov     eax,dword ptr [offset PSGvolume+channel*4]
                mov     dword ptr [offset PSGstate+channel*4],eax
compose_soundstream_MMX_zerocheck_&channel:

                endm

compose_soundstream_loop_MMX:

                ; mm0=psgcounter
                ; mm0=mm0+conv_factor
                ;paddd   mm0,conv_factor
                paddd
                db      00000101b
                dd      offset conv_factor
                
                ;movq    mm2,mm0
                movq
                db      11010000b
                
                ; mm0>start_counter?
                ;pcmpgtd mm2,mm1
                pcmpgtd
                db      11010001b

                ;pand    mm2,[volume]
                pand
                db      00010101b
                dd      offset PSGvolume

                ; switch psgstate
                ;pxor    mm3,mm2
                pxor
                db      11011010b

                ;movq    mm2,mm0
                movq
                db      11010000b

                ;pcmpgtd mm2,mm1
                pcmpgtd
                db      11010001b

                ;pand    mm2,[conv_factor]
                pand
                db      00010101b
                dd      offset conv_factor
                 
                ;psubd   mm0,mm2
                psubd
                db      11000010b

                ;pandd   mm0,[PSGzeroflag]
                pand
                db      00000101b
                dd      offset PSGzeroflag

                ; soundtranslate MMX

                ;movq    qword ptr [offset PSGstate+0],mm3
                movq_st
                db      00011101b
                dd      offset PSGstate

                ;movq    qword ptr [offset PSGstate+8],mm7
                movq_st
                db      00111101b
                dd      offset PSGstate+8

compose_soundstream_mix_MMX:

                mov     eax,0
                
                test    byte ptr [offset PSGreg+7],BIT_0
                jnz     compose_soundstream_mix1_MMX
                add     eax,dword ptr [offset PSGstate+0*4]

compose_soundstream_mix1_MMX:
                
                test    byte ptr [offset PSGreg+7],BIT_1
                jnz     compose_soundstream_mix2_MMX
                add     eax,dword ptr [offset PSGstate+1*4]

compose_soundstream_mix2_MMX:
                
                test    byte ptr [offset PSGreg+7],BIT_2
                jnz     compose_soundstream_next_MMX
                ;add     eax,dword ptr [offset PSGstate+2*4]

compose_soundstream_next_MMX:

                mov     [esi],al
                inc     esi
                
                dec     edx
                jz      compose_soundstream_nextint_MMX
                
                dec     ecx
                jnz     compose_soundstream_loop_MMX

                mov     eax,offset psgregstack
                mov     psgpointer,eax

compose_soundstream_exit_MMX:
                
                popad
                ret

compose_soundstream_nextint_MMX:
                dec     ecx
                add     psgpointer,16
                mov     edx,757
                jmp     compose_soundstream_outer_loop_MMX

code32          ends
                end


                ; mm0=psgcounter
                ; mm0=mm0+conv_factor
                paddd   mm0,[conv_factor]
                
                movq    mm2,mm0
                
                ; mm0>start_counter?
                pcmpgtd mm2,mm1

                ; mm3=volume
                pand    mm2,[volume]

                ; switch psgstate
                pxor    mm3,mm2

                movq    mm2,mm0

                pcmpgtd mm2,mm1

                pand    mm2,[conv_factor]

                psubd   mm0,mm2

                pandd   mm0,[startcounteris0]


