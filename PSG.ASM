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
include gui.inc
include pmode.inc
include pentium.inc

extrn dmabuffer: dword
extrn dmatemp: dword
extrn timebuffer: dword
extrn soundbuffer: dword
extrn sccram: dword

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
public dmastart
public compose_speaker
public speaker_shutup
public noise_table
public sb_flushed

; DATA ---------------------------------------------------------------

align 4

include noise.inc
include scc.inc

SKIPFACTOR              equ     6
CONV_FACTOR             equ     336975
BUFFERSIZE              equ     757*SKIPFACTOR

noisestream             db      BUFFERSIZE dup (0)

align 4

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
sb_flushed              dd      0

PSGcounter              db      4*4 dup (0)
PSGstate                db      4*4 dup (0)
actual_channel          dd      0
localpos                dd      0
dmastart                dd      0
noise_counter           dd      0
noise_counter2          dd      0
danger_flag             dd      0

SCCcounter              db      5*4 dup (0)
SCCstate                db      5*4 dup (0)
scc_conv_table          dd      0

ppiclick                db      0
ppicassete              db      0

psgregstack             db      (16*(SKIPFACTOR+1)) dup (0)
PSGreg                  db      16 dup (0)
psgpointer              dd      0

sccregstack             db      (16*(SKIPFACTOR+1)) dup (0)
SCCregs                 db      16 dup (0)
sccpointer              dd      0

sb_default_pic1         db      0
sb_default_pic2         db      0

noisebit                db      0
musicbit                db      0

align 4
speakerchannel          dd      0
speakerfreq             dd      0
speakersilence          dd      0
speakervolume           db      0
                        db      0
                        db      0
                        db      0

fakescc                 db      8 dup (080h)
                        db      8 dup (07Fh)

align 4

PSG_table               dd      offset PSG_full
                        dd      offset PSG_only_noise
                        dd      offset PSG_only_music
                        dd      offset PSG_nothing

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

                mov     sb_flushed,1

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
                and     ah,sb_default_pic2
                mov     dx,0A1h
                mov     al,ah
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
                cmp     emulatemode,1
                je      _ret

                call    init_dma_buffer

                mov     eax,offset psgregstack
                mov     psgpointer,eax

                mov     eax,offset sccregstack
                mov     sccpointer,eax

                mov     eax,dmatemp
                mov     dmastart,eax

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
                je      compose_soundstream_off

                cmp     turnoff_flag,1
                je      compose_purenoise

                pushad

                mov     esi,offset psgreg
                mov     edi,psgpointer
                mov     ecx,16
                rep     movsb
                mov     psgpointer,edi

                mov     esi,offset sccregs
                mov     edi,sccpointer
                mov     ecx,16
                rep     movsb
                mov     sccpointer,edi

                add     dmastart,757

                dec     irqskip
                jnz     compose_soundstream_exit

                mov     eax,dmatemp
                mov     dmastart,eax

                mov     irqskip,SKIPFACTOR

                mov     esi,timebuffer
                mov     ecx,psgpos
                mov     [esi+ecx*4],0FFFFFFFFh

                mov     localpos,0
                mov     actual_channel,3
                call    compose_noise

                mov     localpos,0
                call    compose_click

                ;mov     localpos,0
                ;call    compose_cassete

                mov     localpos,0
                mov     actual_channel,0
                call    compose_channel
                
                mov     localpos,0
                mov     actual_channel,1
                call    compose_channel
                
                mov     localpos,0
                mov     actual_channel,2
                call    compose_channel
                
                cmp     sccenabled,0
                je      compose_soundstream_noscc

                cmp     sccdetected,0
                je      compose_soundstream_noscc

                mov     localpos,0
                mov     actual_channel,0
                ;mov     esi,sccram
                ;add     esi,1800h
                mov     esi,offset fakescc
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,1
                ;mov     esi,sccram
                ;add     esi,32
                ;add     esi,1800h
                mov     esi,offset fakescc
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,2
                ;mov     esi,sccram
                ;add     esi,32*2
                ;add     esi,1800h
                mov     esi,offset fakescc
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,3
                ;mov     esi,sccram
                ;add     esi,32*3
                ;add     esi,1800h
                mov     esi,offset fakescc
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,4
                ;mov     esi,sccram
                ;add     esi,32*3
                ;add     esi,1800h
                mov     esi,offset fakescc
                call    compose_scc

compose_soundstream_noscc:
                
                mov     eax,offset psgregstack
                mov     psgpointer,eax

                mov     eax,offset sccregstack
                mov     sccpointer,eax

                mov     psgclear,1
                mov     psgpos,0

compose_soundstream_exit:

                mov     dmaready,1
                popad
                ret

compose_soundstream_off:
                mov     psgpos,0
                ret

; compose_click ------------------------------------------------------
; compose and mix the keyboard click

compose_click:

                mov     ecx,0
                mov     edi,BUFFERSIZE
                mov     esi,dmatemp
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8
                mov     al,ppiclick

compose_click_loop:
                mov     [esi],al
                inc     esi                

                add     ecx,20159
                cmp     ecx,ebp
                jb      compose_click_nextsample

                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     al,byte ptr [ebp]
                mov     dl,byte ptr [ebp+1]
                cmp     al,16
                jne     compose_channel_notclick
                mov     ppiclick,dl
compose_channel_notclick:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                mov     al,ppiclick

compose_click_nextsample:
                dec     edi
                jnz     compose_click_loop

                ret

; compose_cassete ----------------------------------------------------
; compose and mix the cassete output

compose_cassete:

                mov     ecx,0
                mov     edi,BUFFERSIZE
                mov     esi,dmatemp
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8
                mov     al,ppicassete

compose_cassete_loop:
                add     [esi],al
                inc     esi                

                add     ecx,20159
                cmp     ecx,ebp
                jb      compose_cassete_nextsample

                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     al,byte ptr [ebp]
                mov     dl,byte ptr [ebp+1]
                cmp     al,17
                jne     compose_channel_notcassete
                mov     ppicassete,dl
compose_channel_notcassete:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                mov     al,ppicassete

compose_cassete_nextsample:
                dec     edi
                jnz     compose_cassete_loop

                ret


; compose_channel ----------------------------------------------------
; compose and mix a PSG square channel
; enter: actual_channel

compose_channel:
                
                mov     eax,offset psgregstack
                mov     psgpointer,eax

                mov     esi,psgpointer                     
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     esi,dword ptr [offset PSGcounter+edi*4]
                mov     eax,dword ptr [offset PSGstate+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                ; make the patches
                mov     edi,dmatemp
                mov     dword ptr [offset patch2+2],edi
                mov     dword ptr [offset patch3+2],edi
                mov     dword ptr [offset patch4+2],edi
                mov     dword ptr [offset patch6+2],edi

                ; play from position 0
                mov     edi,0
                call    modify_parameters

compose_channel_long_loop:
                jmp     edx

; --------------------------------------------------------------------

PSG_full:
                cmp     ah,0
                je      PSG_really_nothing

PSG_full_loop:                
                add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_full_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_full_mix:
                mov     dl,[edi+offset noisestream]
                and     dl,ah
                and     dl,al
                add     ecx,20159
patch2:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     PSG_full_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_only_noise:
                cmp     ah,0
                je      PSG_really_nothing

PSG_only_noise_loop:                
                mov     dl,[edi+offset noisestream]
                and     dl,ah
                add     ecx,20159
patch6:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     PSG_only_noise_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_only_music:
                cmp     ah,0
                je      PSG_really_nothing

PSG_only_music_loop:                
                add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_only_music_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_only_music_mix:
                mov     dl,al
                and     dl,ah
                add     ecx,20159
patch4:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     PSG_only_music_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_nothing:
                cmp     ah,0
                je      PSG_really_nothing

PSG_nothing_loop:
patch3:         add     [edi+12345678h],ah
                add     ecx,20159
                cmp     ecx,ebp
                jae     compose_channel_check
                
                inc     edi
                cmp     edi,BUFFERSIZE
                jne     PSG_nothing_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_really_nothing:
                add     ecx,20159
                cmp     ecx,ebp
                jae     compose_channel_check
                
                inc     edi
                cmp     edi,BUFFERSIZE
                jne     PSG_really_nothing

                jmp     PSG_exit

; --------------------------------------------------------------------
                
compose_channel_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     dh,byte ptr [ebp+1]
                movzx   ebp,byte ptr [ebp]
                cmp     ebp,15
                ja      compose_channel_notpsg
                mov     [offset PSGreg+ebp],dh
                
compose_channel_notpsg:

                mov     ebp,localpos
                inc     ebp
                mov     localpos,ebp

                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                call    modify_parameters

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     compose_channel_long_loop

; --------------------------------------------------------------------
                
PSG_exit:
                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],esi
                mov     dword ptr [offset PSGstate+edi*4],eax
                
                ret
                
; --------------------------------------------------------------------
                
modify_parameters:
                mov     edx,actual_channel
                mov     dword ptr [offset PSGcounter+edx*4],esi
                mov     dword ptr [offset PSGstate+edx*4],eax
                
                mov     eax,actual_channel
                
                ; ebx = start_counter
                movzx   ebx,word ptr [offset PSGreg+eax*2]
                shl     ebx,16

                ; esi = psg_counter
                mov     esi,dword ptr [offset PSGcounter+eax*4]

                ; dl = volume
                mov     dl,byte ptr [offset PSGreg+8+eax]
                and     dl,01Fh
                
                push    ecx

                ; noisebit
                mov     dh,byte ptr [offset PSGreg+7]
                mov     cl,al
                add     cl,3+1
                shr     dh,cl
                sbb     dh,dh
                mov     noisebit,dh

                cmp     dh,0
                jne     modify_parameters_puremusic

                cmp     byte ptr [offset PSGreg+6],4
                ja      modify_parameters_puremusic

                mov     dh,dl
                add     dh,byte ptr [offset PSGreg+6]
                sub     dh,5
                jc      modify_parameters_puremusic

                mov     dl,dh

modify_parameters_puremusic:
                mov     cl,al
                mov     dh,byte ptr [offset PSGreg+7]
                inc     cl
                shr     dh,cl
                sbb     dh,dh
                mov     musicbit,dh

                ; check for frequency equal to zero -> PCM output
                ; warning: affect only the last bit
                cmp     ebx,0
                sete    ch
                or      musicbit,ch

                ; al = psg_state
                mov     eax,dword ptr [offset PSGstate+eax*4]

                ; turn off envelope
                mov     ch,dl
                shr     ch,4
                xor     ch,1
                shl     ch,7
                sar     ch,3
                shr     ch,4
                and     dl,ch

                ; now ah has the volume and dl will be discarded
                mov     ah,dl

                pop     ecx
                
                mov     dl,01h
                and     dl,musicbit
                mov     dh,02h
                and     dh,noisebit
                or      dl,dh
                and     edx,3
                mov     edx,dword ptr [offset PSG_table+edx*4]

                ret

; compose_scc --------------------------------------------------------
; compose and mix a SCC channel
; enter: actual_channel

compose_scc:
                
                mov     eax,offset sccregstack
                mov     sccpointer,eax

                mov     esi,sccpointer                     
                mov     edi,offset SCCregs
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     edx,dword ptr [offset SCCcounter+edi*4]
                mov     eax,dword ptr [offset SCCstate+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                mov     edi,BUFFERSIZE
                mov     esi,dmatemp

compose_scc_outer:

                call    modify_parameters_scc

compose_scc_loop:                
                add     edx,CONV_FACTOR
                cmp     edx,ebx
                jle     compose_scc_mix

                or      ebx,ebx
                jz      compose_scc_start0

                sub     edx,ebx

                or      al,al
                jz      compose_scc_level

                mov     al,0
                jmp     compose_scc_mix

compose_scc_level:
                mov     al,ah
                jmp     compose_scc_mix

compose_scc_start0:

                mov     al,ah
                mov     edx,0
                jmp     compose_scc_mix

compose_scc_mix:
                add     [esi],al
                inc     esi

                add     ecx,20159
                cmp     ecx,ebp
                jb      compose_scc_nextsample

                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer
                push    eax ecx

                movzx   eax,byte ptr [ebp]
                mov     cl,byte ptr [ebp+1]
                cmp     al,80h
                jb      compose_channel_notscc
                mov     [offset SCCregs+eax-080h],cl
compose_channel_notscc:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                pop     ecx eax

                call    modify_parameters_scc

compose_scc_nextsample:
                dec     edi
                jnz     compose_scc_loop

                mov     edi,actual_channel
                mov     dword ptr [offset SCCcounter+edi*4],edx
                mov     dword ptr [offset SCCstate+edi*4],eax
                
                ret

; --------------------------------------------------------------------
                
modify_parameters_scc:
                
                push    edi
                mov     edi,actual_channel
                mov     dword ptr [offset SCCcounter+edi*4],edx
                mov     dword ptr [offset SCCstate+edi*4],eax
                pop     edi
                
                mov     eax,actual_channel
                
                ; ebx = start_counter
                movzx   ebx,word ptr [offset SCCregs+eax*2]
                shl     ebx,16

                ; edx = psg_counter
                mov     edx,dword ptr [offset SCCcounter+eax*4]

                ; cl = volume
                push    ecx
                mov     cl,byte ptr [offset SCCregs+10+eax]
                and     cl,01Fh
                
                ; al = psg_state
                mov     eax,dword ptr [offset SCCstate+eax*4]

                ; turn off oscillator if the channel is off
                mov     ch,byte ptr [offset SCCregs+15]
                xor     ch,255

                push    ecx
                mov     ah,ch
                mov     ecx,actual_channel
                shr     ah,cl
                pop     ecx

                mov     ch,ah

                mov     ah,cl

                shl     ecx,16+7
                sar     ecx,31

                xor     ecx,0FFFFFFFFh
                and     ebx,ecx

                pop     ecx

                ret
; compose_noise ------------------------------------------------------
; compose the PSG noise stream
; enter: actual_channel=3

compose_noise:
                
                mov     eax,offset psgregstack
                mov     psgpointer,eax

                mov     esi,psgpointer                     
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     esi,dword ptr [offset PSGcounter+edi*4]
                mov     eax,dword ptr [offset PSGstate+edi*4]
                mov     edx,noise_counter

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                mov     edi,0
                call    modify_parameters_noise

compose_noise_long_loop:
                cmp     danger_flag,1
                je      compose_noise_danger

; --------------------------------------------------------------------
                
compose_noise_loop:
                add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     compose_noise_mix

                mov     edx,noise_counter
                mov     al,byte ptr [offset noise_table+edx]
                inc     edx
                and     edx,16383
                mov     noise_counter,edx

                cmp     edx,noise_counter2
                je      compose_noise_one

                mov     edx,noise_counter2
                xor     al,byte ptr [offset noise_table+edx]
                inc     edx
                cmp     edx,16383
                jne     compose_noise_skip
                mov     edx,0
compose_noise_skip:
                mov     noise_counter2,edx

compose_noise_one:
                sub     esi,ebx

compose_noise_mix:
                mov     [edi+offset noisestream],al

                add     ecx,20159
                cmp     ecx,ebp
                jae     compose_noise_check

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     compose_noise_loop

                jmp     noise_exit

; --------------------------------------------------------------------
                
compose_noise_danger:
                push    esi
                mov     ebx,noise_counter2

compose_noise_danger_loop:
                cmp     ebx,edx
                jne     compose_noise_danger_loop_go
                inc     edx
                and     edx,16384
compose_noise_danger_loop_go:
                mov     al,byte ptr [offset noise_table+edx]
                xor     al,byte ptr [offset noise_table+ebx]
                inc     edx
                inc     ebx
                mov     [edi+offset noisestream],al
                and     edx,16383
                cmp     ebx,16383
                sbb     esi,esi
                and     ebx,esi

                add     ecx,20159
                cmp     ecx,ebp
                jae     compose_noise_check_now

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     compose_noise_danger_loop

                pop     esi
                mov     noise_counter,edx
                mov     noise_counter2,ebx
                jmp     noise_exit

compose_noise_check_now:
                pop     esi
                mov     noise_counter,edx
                mov     noise_counter2,ebx
                jmp     compose_noise_check

; --------------------------------------------------------------------
                
compose_noise_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     ah,byte ptr [ebp+1]
                movzx   ebp,byte ptr [ebp]
                cmp     ebp,15
                ja      compose_noise_notpsg
                mov     [offset PSGreg+ebp],ah
compose_noise_notpsg:

                mov     ebp,localpos
                inc     ebp
                mov     localpos,ebp

                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                call    modify_parameters_noise

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     compose_noise_long_loop

noise_exit:
                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],esi
                mov     dword ptr [offset PSGstate+edi*4],eax
                ;mov     noise_counter,edx
                
                ret

; --------------------------------------------------------------------
                
modify_parameters_noise:
                
                ; ebx = start_counter
                mov     danger_flag,1
                movzx   ebx,byte ptr [offset PSGreg+6]
                and     ebx,11111b
                cmp     ebx,3
                jb      _ret
                mov     danger_flag,0
                shl     ebx,16+1

                ret

; compose_speaker ----------------------------------------------------
; compose a simple PSG sound through the PC speaker
; the method used is temporal MUX with masking
; warning: this routine is called inside the emulation
; ie must preserve edx, edi, ebp, eax=0
                
compose_speaker:
                ; evaluate all the volumes, 
                ; taking into account the mixer

                mov     al,byte ptr [offset psgreg+7]
                xor     al,255
                ; channel 1
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+8]
                mov     byte ptr [offset speakervolume+0],ah
                ; channel 2
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+9]
                mov     byte ptr [offset speakervolume+1],ah
                ; channel 3
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+10]
                mov     byte ptr [offset speakervolume+2],ah

                ; find the volume with maximum amplitude
                mov     al,byte ptr [offset speakervolume+0]
                cmp     al,byte ptr [offset speakervolume+1]
                ja      compose_speaker_skip1
                mov     al,byte ptr [offset speakervolume+1]
compose_speaker_skip1:
                cmp     al,byte ptr [offset speakervolume+2]
                ja      compose_speaker_skip2
                mov     al,byte ptr [offset speakervolume+2]
compose_speaker_skip2:

                cmp     al,0
                je      speaker_shutup

                ; evaluate the threshold volume
                shr     al,1

                mov     esi,speakerchannel
                inc     esi
                cmp     esi,3
                jne     compose_speaker_continue
                mov     esi,0
compose_speaker_continue:
                mov     speakerchannel,esi
                cmp     byte ptr [offset speakervolume+esi],al
                jb      compose_speaker_ret

                movzx   ebx,word ptr [offset psgreg+esi*2]

                ; at this point ebx must contain the desired freq
                cmp     speakersilence,0
                je      compose_speaker_go
                cmp     ebx,speakerfreq
                je      compose_speaker_ret

compose_speaker_go:
                mov     speakersilence,1
                mov     speakerfreq,ebx
                push    edx
                mov     eax,700919
                mul     ebx
                shrd    eax,edx,16
                push    eax
                mov     edx,043h
                mov     al,0B6h
                out     dx,al
                dec     edx
                pop     eax
                out     dx,al
                mov     al,ah
                out     dx,al
                mov     edx,061h
                in      al,dx
                or      al,3
                out     dx,al
                pop     edx

compose_speaker_ret:
                mov     eax,0
                ret

; speaker_shutup -----------------------------------------------------
; shut up the speaker                

speaker_shutup:
                push    edx
                mov     edx,061h
                in      al,dx
                and     al,0FCh
                out     dx,al
                pop     edx
                mov     eax,0
                mov     speakersilence,eax
                ret

; compose_purenoise --------------------------------------------------
; compose a pure white noise
; used in the TURN OFF option of the GUI

compose_purenoise:
                mov     edx,noise_counter
                mov     ebp,noise_counter2
                mov     edi,0
                mov     ebx,dmatemp
                
compose_purenoise_loop:
                mov     al,byte ptr [offset noise_table+edx]
                xor     al,byte ptr [offset noise_table+ebp]
                inc     edx
                inc     ebp
                and     al,15
                mov     [ebx+edi],al
                and     edx,16383
                cmp     ebp,16383
                sbb     ecx,ecx
                and     ebp,ecx

                inc     edi
                cmp     edi,BUFFERSIZE
                jne     compose_purenoise_loop

                mov     noise_counter,edx
                mov     noise_counter2,ebp
                
                ret
                
; --------------------------------------------------------------------

code32          ends
                end

