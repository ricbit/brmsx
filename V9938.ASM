; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: 
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include vdp.inc
include bit.inc
include io.inc
include pmode.inc
include pentium.inc
include blit.inc

extrn msxvram: dword
extrn vdplog: dword
extrn blitbuffer: dword
extrn redbuffer: dword

public outemul98_msx2
public outemul99_msx2
public inemul99_msx2
public inemul98_msx2
public outemul9B_msx2
public outemul9A_msx2
public render_screen0_80
public render_screen5
public render_screen6
public render_screen7
public render_screen8
public sprite_render_msx2
public dirty_palette

; DATA ---------------------------------------------------------------

align 4
include screen0l.inc
include screen6.inc

align 4

all0F           dq      0F0F0F0F0F0F0F0Fh
all10           dq      1010101010101010h

falsesprite     db      32*32*2 dup (0)
falsemask       db      32 dup (0)

dirty_palette   db      16 dup (1)

save_ebp        dd      0
save_esi        dd      0
vdp_page        dd      0

size_hx         dd      0
and_hx          dd      0
and_x           dd      0
max_x           dd      0
max_y           dd      0
and_y           dd      0
pSX             dd      0
pSY             dd      0
pDX             dd      0
pDY             dd      0
pNX             dd      0
pNY             dd      0
shift_mask      dd      0
shift_factor    dd      0
logical_op      dd      0
shift_low_x     db      0
shift_high_y    db      0
pixel_mask      db      0

save_POS        dd      0
save_START      dd      0
save_XSIZE      dd      0
save_XOFFSET    dd      0
save_NX         dd      0
save_NY         dd      0
callback_44     dd      _ret

callback_vdp:
                dd      _ret                    ; STOP
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; POINT
                dd      vdp_command_PSET        ; PSET
                dd      _ret                    ; SEARCH
                dd      vdp_command_LINE        ; LINE
                dd      vdp_command_LMMV        ; LMMV
                dd      vdp_command_LMMM        ; LMMM
                dd      _ret                    ; LMCM
                dd      vdp_command_LMMC        ; LMMC
                dd      vdp_command_HMMV        ; HMMV
                dd      vdp_command_HMMM        ; HMMM
                dd      vdp_command_YMMM        ; YMMM
                dd      vdp_command_HMMC        ; HMMC

callback_logical:
                dd      write_pixel_imp         ; IMP
                dd      write_pixel_and         ; AND
                dd      write_pixel_or          ; OR
                dd      write_pixel_xor         ; XOR
                dd      write_pixel_not         ; NOT
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      write_pixel_timp        ; TIMP
                dd      write_pixel_tand        ; TAND
                dd      write_pixel_tor         ; TOR
                dd      write_pixel_txor        ; TXOR
                dd      write_pixel_tnot        ; TNOT
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED

paletteflag     db      0
vdpindirect     db      0
vdpindirectmode db      0

; --------------------------------------------------------------------
; VDP write value
; MSX2 version

outemul98_msx2:
                mov     eax,vdpaddresse
                mov     vdpcond,0
                mov     ecx,eax
                mov     esi,msxvram
                inc     eax
                and     eax,03FFFh
                mov     vdpaddresse,eax
                
                ; select page
                add     esi,vdp_page
                mov     [ecx+esi],bl

                cmp     eax,0
                jne     outemul98_msx2_exit
                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax

outemul98_msx2_exit:
                mov     eax,0
                ret

; --------------------------------------------------------------------
; VDP register select
; MSX2 version

outemul99_msx2:      
                cmp     vdpcond,0
                jne     outemul99a_msx2
                mov     vdpcond,1
                mov     vdptemp,bl
                ret

outemul99a_msx2:     
                mov     vdpcond,0
                test    bl,10000000b
                jnz     outemul99b_msx2
                cmp     bl,01000000b
                jb      outemul99_read_msx2
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     vdpaccess,1
                ret

outemul99_read_msx2:
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     esi,msxvram
                mov     ecx,vdpaddresse

                ; select page
                add     esi,vdp_page

                mov     bl,[esi+ecx]
                mov     vdplookahead,bl
                inc     ecx
                and     ecx,03FFFh
                mov     vdpaddresse,ecx
                mov     eax,0
                mov     vdpaccess,eax

                cmp     ecx,0
                jne     _ret

                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

outemul99b_msx2:     
                ; write directly to a VDP register
                and     ebx,00111111b
                mov     al,vdptemp
                mov     cl,byte ptr [offset vdpregs+ebx]
                mov     byte ptr [offset vdpregs+ebx],al

register_action:
                cmp     bl,7
                je      change_border_color
                cmp     bl,9
                je      change_total_lines
                cmp     bl,1
                je      outemul99_checkirq_msx2
                cmp     bl,17
                je      outemul99_indirect_msx2
                cmp     bl,16
                je      outemul99_palette_msx2
                cmp     bl,14
                je      outemul99_page_msx2
                cmp     bl,44
                je      check_cpu_move 
                cmp     bl,46
                je      execute_vdp_command 
outemul99_update_msx2:
                mov     firstscreen,1
                jmp     eval_base_address_msx2

outemul99_checkirq_msx2:
                cmp     iline,0
                je      outemul99_turnedoff_msx2

                ; at this point iline=1
                ; if bit 5 goes to zero, then iline must drop to zero also
                test    al,BIT_5
                jnz     outemul99_irqexit_msx2
                
                mov     iline,0
                jmp     outemul99_irqexit_msx2

outemul99_turnedoff_msx2:
                ; at this point iline=0
                ; if bit 5 goes to 1, and bit 7 is also 1
                ; this irq will happen NOW, unless iff1=0
                test    al,BIT_5
                jz      outemul99_irqexit_msx2

                test    vdpstatus,BIT_7
                jz      outemul99_irqexit_msx2

                mov     iline,1
                cmp     iff1,1
                jne     outemul99_irqexit_msx2

                mov     clocksleft,ebp
                mov     fakeirq,1
                mov     ebp,0

outemul99_irqexit_msx2:
                xor     cl,al
                cmp     cl,BIT_5
                jne     outemul99_update_msx2

                xor     eax,eax
                ret

check_cpu_move:
                jmp     dword ptr [offset callback_44]

outemul99_page_msx2:
                ; select page
                movzx   eax,byte ptr [offset vdpregs+14]
                and     eax,7
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

change_border_color:
                mov     byte ptr [offset dirty_palette+0],1
                ret

outemul99_indirect_msx2:                
                mov     bl,al
                shr     bl,7
                mov     vdpindirectmode,bl
                and     al,03Fh
                mov     vdpindirect,al
                ret

outemul99_palette_msx2:
                mov     paletteflag,0
                ret

change_total_lines:
                mov     total_lines,212
                test    al,BIT_7
                jnz     _ret

                mov     total_lines,192
                xor     cl,al
                and     cl,al
                and     cl,BIT_7
                jz      _ret

                mov     clear_bottom_field,1
                ret

; --------------------------------------------------------------------
; VDP palette register write
; MSX2 version

outemul9A_msx2:
                cmp     paletteflag,1
                je      outemul9A_msx2_set

                movzx   eax,byte ptr [offset vdpregs+16]
                mov     byte ptr [offset msx2palette+eax*2],bl
                mov     paletteflag,1
                ret

outemul9A_msx2_set:
                movzx   eax,byte ptr [offset vdpregs+16]
                mov     byte ptr [offset msx2palette+eax*2+1],bl
                mov     byte ptr [offset dirty_palette+eax],1
                inc     byte ptr [offset vdpregs+16]
                mov     paletteflag,0
                ;jmp     set_palette_color
                ret

; --------------------------------------------------------------------
; VDP indirect register write
; MSX2 version

outemul9B_msx2:
                cmp     vdpindirectmode,0
                jnz     outemul9B_single
                
                ; auto increment
                movzx   eax,vdpindirect
                mov     byte ptr [offset vdpregs+eax],bl
                push    eax
                xchg    eax,ebx
                and     eax,0FFh
                and     ebx,03Fh
                call    register_action
                pop     eax
                inc     eax
                mov     vdpindirect,al
                ret

outemul9B_single:
                movzx   eax,vdpindirect
                mov     byte ptr [offset vdpregs+eax],bl
                push    eax
                xchg    eax,ebx
                and     eax,03Fh
                call    register_action
                pop     eax
                ret

; --------------------------------------------------------------------
; VDP read VRAM
; MSX2 version

inemul98_msx2:       
                mov     ecx,msxvram
                mov     bl,vdplookahead
                
                ; select page
                mov     esi,vdp_page

                add     esi,vdpaddresse

                mov     bh,[ecx+esi]
                and     esi,03FFFh
                inc     esi
                and     esi,03FFFh
                mov     vdpaddresse,esi
                mov     vdplookahead,bh
                mov     vdpcond,0

                cmp     esi,0                
                jne     _ret

                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

; --------------------------------------------------------------------
; VDP read status register
; MSX2 version

inemul99_msx2:       
                cmp     byte ptr [offset vdpregs+15],2
                je      inemul99_msx2_reg2

                cmp     byte ptr [offset vdpregs+15],0
                jne     inemul99_msx2_generic

                mov     bl,vdpstatus
                and     vdpstatus,00111111b
                mov     vdpcond,0
                mov     iline,0
                ret

inemul99_msx2_reg2:
                mov     bl,byte ptr [offset vdpstatus+2]
                xor     bl,020h 
                mov     cl,bl
                and     cl,NBIT_6
                mov     byte ptr [offset vdpstatus+2],cl
                ret

inemul99_msx2_generic:
                movzx   ecx,byte ptr [offset vdpregs+15]
                add     ecx,offset vdpregs
                mov     bl,byte ptr [ecx]
                ret

; eval_screen_mask ---------------------------------------------------
; prepare the masks used in VDP command 

eval_screen_mask:
                mov     callback_44,offset _ret

                cmp     actualscreen,5
                je      eval_screen_mask_5

                cmp     actualscreen,6
                je      eval_screen_mask_6

                cmp     actualscreen,7
                je      eval_screen_mask_7

                cmp     actualscreen,8
                je      eval_screen_mask_8

                ret

eval_screen_mask_5:
                mov     size_hx,080h
                mov     and_hx,0FEh
                mov     and_x,0FFh
                mov     max_x,0100h
                mov     shift_low_x,1
                mov     and_y,03FFh
                mov     max_y,0400h
                mov     shift_high_y,7
                mov     pixel_mask,0Fh
                mov     shift_mask,1
                mov     shift_factor,2
                ret

eval_screen_mask_6:
                mov     size_hx,080h
                mov     and_hx,01FCh
                mov     and_x,01FFh
                mov     max_x,0200h
                mov     shift_low_x,2
                mov     and_y,03FFh
                mov     max_y,0400h
                mov     shift_high_y,7
                mov     pixel_mask,03h
                mov     shift_mask,3
                mov     shift_factor,1
                ret

eval_screen_mask_7:
                mov     size_hx,0100h
                mov     and_hx,01FEh
                mov     and_x,01FFh
                mov     max_x,0200h
                mov     shift_low_x,1
                mov     and_y,01FFh
                mov     max_y,0200h
                mov     shift_high_y,8
                mov     pixel_mask,0Fh
                mov     shift_mask,1
                mov     shift_factor,2
                ret

eval_screen_mask_8:
                mov     size_hx,0100h
                mov     and_hx,0FFh
                mov     and_x,0FFh
                mov     max_x,0100h
                mov     shift_low_x,0
                mov     and_y,01FFh
                mov     max_y,0200h
                mov     shift_high_y,8
                mov     pixel_mask,0FFh
                mov     shift_mask,0
                mov     shift_factor,0
                ret

; write_vdplog -------------------------------------------------------
; write the vdp commands to stdout

write_vdplog:
                cmp     vdplog,1
                jne     _ret

                cmp     vdplog_now,1
                jne     _ret

                pushad
                and     eax,0FFh
                call    crlf
                call    crlf
                call    printhex2
                mov     al,byte ptr [offset vdpregs+32]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+33]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+34]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+35]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+36]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+37]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+38]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+39]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+40]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+41]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+42]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+43]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+44]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+45]
                call    printhex2

                popad

                ret

; execute_vdp_command ------------------------------------------------
; execute a vdp command
; enter: al = command
; this routine is called in HOT STATE 
; (shouldn't touch edi, ebp, edx, and leave high eax=0)

execute_vdp_command:
                call    write_vdplog
                call    eval_screen_mask

                movzx   ebx,al
                mov     ecx,ebx
                and     ebx,0Fh
                shr     ecx,4
                mov     logical_op,ebx
                jmp     dword ptr [offset callback_vdp+ecx*4]

; vdp_command_HMMM ---------------------------------------------------

vdp_command_HMMM:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load SX
                movzx   eax,word ptr [offset vdpregs+32]
                and     eax,and_hx
                mov     pSX,eax

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     HMMM_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

HMMM_NX_consistent:

                ; check SX consistency
                mov     eax,pSX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     HMMM_SX_consistent

                mov     eax,max_x
                sub     eax,pSX
                mov     pNX,eax

HMMM_SX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     HMMM_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

HMMM_DX_consistent:

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check SY consistency
                mov     eax,pSY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     HMMM_SY_consistent

                mov     eax,max_y
                sub     eax,pSY
                mov     pNY,eax

HMMM_SY_consistent:

                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     HMMM_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

HMMM_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_HMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl
                
                mov     ebp,size_hx
                sub     ebp,edx

                ; begin the transfer
                mov     ebx,pNY
vdp_command_HMMM_outer:

                mov     ecx,edx
                rep     movsb

                add     esi,ebp
                add     edi,ebp

                dec     ebx
                jnz     vdp_command_HMMM_outer

vdp_command_HMMM_exit:
                popad
                ret

; vdp_command_YMMM ---------------------------------------------------

vdp_command_YMMM:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX=SX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                mov     pSX,eax
                        
                ; set NX = max_x - DX
                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check SY consistency
                mov     eax,pSY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     YMMM_SY_consistent

                mov     eax,max_y
                sub     eax,pSY
                mov     pNY,eax

YMMM_SY_consistent:

                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     YMMM_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

YMMM_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_YMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                mov     ebp,size_hx
                sub     ebp,edx

                ; begin the transfer
                mov     ebx,pNY
vdp_command_YMMM_outer:

                mov     ecx,edx
                rep     movsb

                ;sub     esi,edx
                ;sub     edi,edx
                ;add     esi,size_hx
                ;add     edi,size_hx
                add     esi,ebp
                add     edi,ebp

                dec     ebx
                jnz     vdp_command_YMMM_outer

vdp_command_YMMM_exit:
                popad
                ret

; vdp_command_HMMV ---------------------------------------------------

vdp_command_HMMV:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     HMMV_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

HMMV_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     HMMV_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

HMMV_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     HMMV_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

HMMV_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                jne     HMMV_NY_consistent

                mov     eax,max_y
                mov     pNY,eax
                mov     pDY,0

HMMV_NY_consistent:

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                mov     ebp,size_hx
                sub     ebp,edx

                ; load the filling byte
                mov     al,byte ptr [offset vdpregs+44]

                ; begin the transfer
                mov     ebx,pNY
vdp_command_HMMV_outer:

                mov     ecx,edx
                rep     stosb

                ;sub     esi,edx
                ;sub     edi,edx
                ;add     esi,size_hx
                ;add     edi,size_hx
                add     edi,ebp

                dec     ebx
                jnz     vdp_command_HMMV_outer

vdp_command_HMMV_exit:
                popad
                ret

; vdp_command_HMMC ---------------------------------------------------

vdp_command_HMMC:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     HMMC_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

HMMC_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     HMMC_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

HMMC_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     HMMC_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

HMMC_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                jne     HMMC_NY_consistent

                mov     eax,max_y
                mov     pNY,eax
                mov     pDY,0

HMMC_NY_consistent:

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                ; prepare the transfer
                mov     save_POS,edi

                mov     eax,pNY
                mov     save_NY,eax

                mov     save_XSIZE,edx
                mov     save_NX,edx

                mov     eax,size_hx
                sub     eax,edx
                mov     save_XOFFSET,eax

                or      byte ptr [offset vdpstatus+2],081h

                mov     callback_44,offset callback_HMMC
                call    dword ptr [offset callback_44]

vdp_command_HMMC_exit:
                popad
                ret

callback_HMMC:
                mov     al,byte ptr [offset vdpregs+44]
                mov     ecx,save_POS
                mov     [ecx],al
                inc     ecx
                mov     save_POS,ecx

                dec     save_NX
                jnz     _ret

                add     ecx,save_XOFFSET
                mov     save_POS,ecx

                mov     ecx,save_XSIZE
                mov     save_NX,ecx

                dec     save_NY
                jnz     _ret

                mov     callback_44,offset _ret
                and     byte ptr [offset vdpstatus+2],07Eh

                ret

; READ_PIXEL ---------------------------------------------------------
; read one pixel from VRAM
; enter: edi = vram byte
;        edx = select pixel
; exit:  al = pixel
; destroy edx

READ_PIXEL      macro

                push    ecx
                mov     ecx,shift_factor
                xor     edx,0FFFFFFFFh
                and     edx,shift_mask
                shl     edx,cl
                mov     ecx,edx
                mov     al,[esi]
                shr     al,cl
                pop     ecx

                endm

; WRITE_PIXEL --------------------------------------------------------
; write one pixel to VRAM
; enter: edi = vram byte
;        edx = select pixel
;        al = pixel
; destroy edx,ah

WRITE_PIXEL     macro

                push    ecx
                mov     ah,pixel_mask
                and     al,ah
                mov     ecx,shift_factor
                xor     edx,0FFFFFFFFh
                and     edx,shift_mask
                shl     edx,cl
                mov     ecx,edx
                shl     ah,cl
                xor     ah,255
                shl     al,cl
                mov     ecx,logical_op
                call    dword ptr [offset callback_logical+ecx*4]
                pop     ecx
                endm

; vdp_command_PSET ---------------------------------------------------

vdp_command_PSET:
                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                        
                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; load the filling byte
                mov     al,byte ptr [offset vdpregs+44]
                mov     edx,pDX
                
                WRITE_PIXEL 

                popad
                ret

; --------------------------------------------------------------------
; logical operations used in write_pixel

write_pixel_timp:
                or      al,al
                jz      _ret
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_imp:
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_and:
                or      al,ah
                and     [edi],al
                ret

write_pixel_or:
                or      [edi],al
                ret

write_pixel_xor:
                xor     [edi],al
                ret

write_pixel_not:
                xor     ah,255
                xor     al,ah
                xor     ah,255
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_tand:
                or      al,al
                jz      _ret 
                or      al,ah
                and     [edi],al
                ret

write_pixel_tor:
                or      al,al
                jz      _ret 
                or      [edi],al
                ret

write_pixel_txor:
                or      al,al
                jz      _ret 
                xor     [edi],al
                ret

write_pixel_tnot:
                or      al,al
                jz      _ret 
                xor     ah,255
                xor     al,ah
                xor     ah,255
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

; vdp_command_LMMM ---------------------------------------------------

vdp_command_LMMM:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load SX
                movzx   eax,word ptr [offset vdpregs+32]
                and     eax,and_x
                mov     pSX,eax

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     LMMM_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

LMMM_NX_consistent:

                ; check SX consistency
                mov     eax,pSX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     LMMM_SX_consistent

                mov     eax,max_x
                sub     eax,pSX
                mov     pNX,eax

LMMM_SX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     LMMM_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

LMMM_DX_consistent:

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check SY consistency
                mov     eax,pSY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     LMMM_SY_consistent

                mov     eax,max_y
                sub     eax,pSY
                mov     pNY,eax

LMMM_SY_consistent:

                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     LMMM_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

LMMM_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     eax,pSX
                mov     ebp,pDX

                ; begin the transfer
                mov     ebx,pNY
vdp_command_LMMM_outer:

                mov     ecx,pNX
                push    esi edi
vdp_command_LMMM_inner:

                push    eax
                mov     edx,eax
                READ_PIXEL 
                mov     edx,ebp
                WRITE_PIXEL
                pop     eax

                inc     eax
                inc     ebp
                xor     edx,edx
                test    eax,shift_mask
                setz    dl
                add     esi,edx
                xor     edx,edx
                test    ebp,shift_mask
                setz    dl
                add     edi,edx

                dec     ecx
                jnz     vdp_command_LMMM_inner

                pop     edi esi

                mov     eax,pSX
                mov     ebp,pDX
                add     esi,size_hx
                add     edi,size_hx

                dec     ebx
                jnz     vdp_command_LMMM_outer

vdp_command_LMMM_exit:
                popad
                ret

; vdp_command_LMMV ---------------------------------------------------

vdp_command_LMMV:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     LMMV_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

LMMV_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     LMMV_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

LMMV_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     LMMV_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

LMMV_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMV_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                ; begin the transfer
                mov     ebx,pNY
vdp_command_LMMV_outer:

                mov     ecx,pNX
                push    esi edi
vdp_command_LMMV_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL 
                pop     eax

                inc     ebp
                test    ebp,shift_mask
                jnz     vdp_command_LMMV_ebp
                inc     edi
vdp_command_LMMV_ebp:
                dec     ecx
                jnz     vdp_command_LMMV_inner

                pop     edi esi

                mov     ebp,pDX
                add     esi,size_hx
                add     edi,size_hx

                dec     ebx
                jnz     vdp_command_LMMV_outer

vdp_command_LMMV_exit:
                popad
                ret

; vdp_command_LMMC ---------------------------------------------------

vdp_command_LMMC:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     LMMC_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

LMMC_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     LMMC_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

LMMC_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     LMMC_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

LMMC_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMV_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                ; prepare the transfer
                mov     save_POS,edi
                mov     save_START,edi

                mov     eax,pNY
                mov     save_NY,eax

                mov     ecx,pNX
                mov     save_XSIZE,ecx
                mov     save_NX,ecx

                mov     eax,pDX
                mov     save_XOFFSET,eax

                or      byte ptr [offset vdpstatus+2],081h

                mov     callback_44,offset callback_LMMC
                call    dword ptr [offset callback_44]

vdp_command_LMMC_exit:
                popad
                ret

callback_LMMC:
                mov     al,byte ptr [offset vdpregs+44]
                push    edi edx
                mov     edi,save_POS
                mov     edx,save_XOFFSET
                WRITE_PIXEL
                mov     edx,save_XOFFSET
                inc     edx
                mov     save_XOFFSET,edx
                test    edx,shift_mask
                jnz     callback_LMMC_edx
                inc     edi
                mov     save_POS,edi
callback_LMMC_edx:
                pop     edx edi

                mov     eax,0

                dec     save_NX
                jnz     _ret

                mov     ecx,save_START
                add     ecx,size_hx
                mov     save_START,ecx
                mov     save_POS,ecx

                mov     ecx,save_XSIZE
                mov     save_NX,ecx

                dec     save_NY
                jnz     _ret

                mov     callback_44,offset _ret
                and     byte ptr [offset vdpstatus+2],07Eh
                
                ret

; vdp_command_LINE ---------------------------------------------------

vdp_command_LINE:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load NY (min)
                movzx   eax,word ptr [offset vdpregs+42]
                mov     pNY,eax
                
                ; only vertical and horizontal lines are supported
                cmp     eax,0
                jne     vdp_command_LINE_exit

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NX (max)
                movzx   eax,word ptr [offset vdpregs+40]
                mov     pNX,eax

                ; only horizontal lines by now
                test    byte ptr [offset vdpregs+45],BIT_0
                jnz     vdp_command_vLINE

vdp_command_hLINE:
                ; check NX consistency
                cmp     pNX,0
                je      vdp_command_LINE_exit

                ; bugfix
                inc     pNX

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     hLINE_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

hLINE_DX_consistent:

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                mov     ecx,pNX
vdp_command_hLINE_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL
                pop     eax

                inc     ebp
                test    ebp,shift_mask
                jnz     vdp_command_hLINE_ebp
                inc     edi
vdp_command_hLINE_ebp:
                dec     ecx
                jnz     vdp_command_hLINE_inner

vdp_command_LINE_exit:
                popad
                ret

vdp_command_vLINE:
                ; check NX consistency
                cmp     pNX,0
                je      vdp_command_LINE_exit

                ; bugfix
                inc     pNX

                ; check DY consistency
                mov     eax,pDY
                add     eax,pNX                        
                cmp     eax,max_y
                jbe     vLINE_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNX,eax

vLINE_DY_consistent:

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                mov     ecx,pNX
vdp_command_vLINE_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL 
                pop     eax

                add     edi,size_hx

                dec     ecx
                jnz     vdp_command_vLINE_inner

                jmp     vdp_command_LINE_exit

; render_screen0_80 --------------------------------------------------
; render a screen 0 page
; MSX2 version: 80 columns

render_screen0_80:                
                mov     esi,msxvram                
                add     esi,nametable
                
                mov     ebx,msxvram
                add     ebx,patterntable
                
                mov     edi,blitbuffer
                add     edi,16

                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06_80:
                push    ebp
                mov     ebp,80
                ; draw a line

render05_80:
                ; draw two chars

                mov     cl,[esi]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table1_msx2+edx*8]
                mov     [edi+i*512],eax
                mov     eax,[offset screen0_table1_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+4+i*512],eax

                endm

                mov     cl,[esi+1]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table2_msx2+edx*8]
                mov     [edi+6+i*512],ax
                mov     eax,[offset screen0_table2_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+8+i*512],eax

                endm

                add     esi,2
                add     edi,12
                sub     ebp,2
                jnz     render05_80

                pop     ebp
                add     edi,512*7+32
                dec     ebp
                jnz     render06_80

                mov     spriteenable,0

                ret

; render_screen5 -----------------------------------------------------
; render the SCREEN 5

render_screen5:
                cmp     enginetype,0
                jne     render_screen5_mmx

                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen5_outer:
                push    ecx
                mov     edx,32

render_screen5_inner:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen5_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen5_outer

                mov     spriteenable,2

                ret

; render_screen5_mmx -------------------------------------------------
; render the SCREEN 5 using MMX

render_screen5_mmx:
                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10

render_screen5_mmx_outer:
                push    ecx
                mov     edx,16

render_screen5_mmx_inner:
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                ; movq     mm1,mm0
                movq
                db      11001000b

                ; pand    mm0,mm4
                pand
                db      11000100b

                ; psrlq    mm1,4
                psrlq   
                db      11010001b
                db      4
                
                ; por      mm0,mm5
                por
                db      11000101b

                ; pand    mm1,mm4
                pand
                db      11001100b

                ; movq    mm2,mm0
                movq
                db      11010000b
                
                ; por      mm1,mm5
                por
                db      11001101b

                ; movq     mm3,mm1
                movq
                db      11011001b
                
                add     esi,8

                ; punpckhbw mm1,mm0
                punpckhbw
                db      11001000b

                add     edi,16
                
                ; punpcklbw mm3,mm2
                punpcklbw
                db      11011010b

                ; movq_st [edi-8],mm1
                movq_st
                db      10001111b
                dd      -8

                dec     edx

                ; movq_st [edi-16],mm3
                movq_st
                db      10011111b
                dd      -16

                jnz     render_screen5_mmx_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen5_mmx_outer

                mov     spriteenable,2

                ret

; render_screen6 -----------------------------------------------------
; render the SCREEN 6

render_screen6:
                cmp     videomode,7
                je      render_screen6_sizedown

                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                add     esi,eax
                add     esi,msxvram
                mov     ecx,212
                mov     eax,0

render_screen6_outer:
                mov     edx,128/4

render_screen6_inner:
                mov     ebx,dword ptr [esi]
                add     esi,4

                mov     al,bh
                mov     ebp,dword ptr [offset screen6_table+eax*4]
                mov     [edi+4],ebp
                mov     al,bl
                mov     ebp,dword ptr [offset screen6_table+eax*4]
                mov     [edi+0],ebp
                shr     ebx,16
                mov     al,bh
                mov     ebp,dword ptr [offset screen6_table+eax*4]
                mov     [edi+12],ebp
                mov     al,bl
                mov     ebp,dword ptr [offset screen6_table+eax*4]
                mov     [edi+8],ebp
                add     edi,16

                dec     edx
                jnz     render_screen6_inner

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen6_outer

                mov     spriteenable,0

                ret

render_screen6_sizedown:
                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen6_outer_sizedown:
                push    ecx
                mov     edx,32

render_screen6_inner_sizedown:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen6_inner_sizedown

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen6_outer_sizedown

                mov     spriteenable,0

                ret

; render_screen7 -----------------------------------------------------
; render the SCREEN 7

render_screen7:
                cmp     videomode,7
                je      render_screen7_sizedown
                
                cmp     enginetype,0
                jne     render_screen7_mmx

                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen7_outer:
                push    ecx
                mov     edx,64 

render_screen7_inner:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen7_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer

                mov     spriteenable,0

                ret

; render_screen7_mmx -------------------------------------------------
; render the SCREEN 7 using MMX

render_screen7_mmx:
                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10

render_screen7_mmx_outer:
                push    ecx
                mov     edx,32 ;16

render_screen7_mmx_inner:
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                ; movq     mm1,mm0
                movq
                db      11001000b

                ; pand    mm0,mm4
                pand
                db      11000100b

                ; psrlq    mm1,4
                psrlq   
                db      11010001b
                db      4
                
                ; por      mm0,mm5
                por
                db      11000101b

                ; pand    mm1,mm4
                pand
                db      11001100b

                ; movq    mm2,mm0
                movq
                db      11010000b
                
                ; por      mm1,mm5
                por
                db      11001101b

                ; movq     mm3,mm1
                movq
                db      11011001b
                
                add     esi,8

                ; punpckhbw mm1,mm0
                punpckhbw
                db      11001000b

                add     edi,16
                
                ; punpcklbw mm3,mm2
                punpcklbw
                db      11011010b

                ; movq_st [edi-8],mm1
                movq_st
                db      10001111b
                dd      -8

                dec     edx

                ; movq_st [edi-16],mm3
                movq_st
                db      10011111b
                dd      -16

                jnz     render_screen7_mmx_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_mmx_outer

                mov     spriteenable,0

                ret

; render_screen7_sizedown --------------------------------------------
; render the SCREEN 7 in "-res 7"

render_screen7_sizedown:
                cmp     enginetype,0
                jne     render_screen7_sizedown_mmx

                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen7_outer_sizedown:
                push    ecx
                mov     edx,64 

render_screen7_inner_sizedown:
                mov     eax,dword ptr [esi+ebp]
                and     eax,0F0F0F0Fh
                or      eax,10101010h
                add     esi,4
                mov     dword ptr [edi],eax
                add     edi,4
                dec     edx
                jnz     render_screen7_inner_sizedown

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer_sizedown

                mov     spriteenable,2

                ret

; render_screen7_sizedown_mmx ----------------------------------------
; render the SCREEN 7 in "-res 7" using MMX

render_screen7_sizedown_mmx:
                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212
                
                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10


render_screen7_outer_sizedown_mmx:
                push    ecx
                mov     edx,64/2

render_screen7_inner_sizedown_mmx:
                ;mov     eax,dword ptr [esi+ebp]
                ;and     eax,0F0F0F0Fh
                ;or      eax,10101010h
                ;add     esi,4
                ;mov     dword ptr [edi],eax
                ;add     edi,4
                
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                add     esi,8
                
                ; pand    MM0,MM4
                pand    
                db      11000100b

                add     edi,8

                ; por     MM0,MM5
                por
                db      11000101b

                dec     edx

                ; movq_st [edi-8],mm0
                movq_st
                db      10000111b
                dd      -8

                jnz     render_screen7_inner_sizedown_mmx

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer_sizedown_mmx

                mov     spriteenable,2

                ret

; render_screen8 -----------------------------------------------------
; render the SCREEN 8

render_screen8:
                ;cmp     enginetype,0
                ;jne     render_screen7_mmx

                mov     edi,blitbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ebx,212

render_screen8_outer:
                mov     ecx,64

render_screen8_inner:
                mov     eax,dword ptr [esi+ebp]
                add     esi,4
                mov     dword ptr [edi],eax
                add     edi,4
                dec     ecx
                jnz     render_screen8_inner

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ebx
                jnz     render_screen8_outer

                mov     spriteenable,0

                ret

; sprite_render_msx2 -------------------------------------------------
; draw the sprites directly on the blit buffer
; MSX2 version - sprites mode 2

align 4

sprite_render_msx2:
                ; check for screen enabled
                test    byte ptr [offset vdpregs+1],BIT_6
                jz      _ret

                ; check for sprites enabled
                test    byte ptr [offset vdpregs+8],BIT_1
                jnz     _ret

                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
sprite_render_find_loop_msx2:
                mov     ah,[esi]
                cmp     ah,0D8h
                je      sprite_render_found_msx2

                add     esi,4
                dec     ebp
                jnz     sprite_render_find_loop_msx2
sprite_render_found_msx2:
                sub     esi,4
                mov     eax,32
                sub     eax,ebp
                mov     ebp,eax
                jz      _ret

                mov     save_ebp,ebp
                mov     save_esi,esi

                ; at this point
                ; esi = pointer to last sprite's attribute table
                ; ebp = number of sprites

sprite_render_outer_msx2:
                push    ebp

                ; draw sprite image in false sprite buffer
                call    draw_sprite_image_msx2

                ; eval sprite coordinates
                call    eval_sprite_coords_msx2

                mov     edi,eax
                movzx   eax,byte ptr [offset vdpregs+23]
                sub     edi,eax
                jns     sprite_positive
                add     edi,256
sprite_positive:
                jns     sprite_positive_2
                add     edi,256
sprite_positive_2:
                cmp     edi,212-16
                jg      sprite_render_next_msx2
                sal     edi,8
                add     edi,ecx
                mov     ebp,edi
                add     edi,blitbuffer
                add     ebp,redbuffer

                ; check for unusual size
                cmp     edx,16
                jne     sprite_render_next_msx2
                
                ; check for crop
                cmp     ecx,0
                jl      sprite_render_next_msx2
                cmp     ecx,256-16
                jge     sprite_render_next_msx2
                
                ; draw the sprite in blitbuffer
                
                mov     ecx,offset falsesprite
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shr     esi,2
                xchg    eax,esi
                mov     edx,0

sprite_render_line_msx2:
                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     sprite_render_line_msx2_go

                test    byte ptr [offset falsemask+edx],0Fh
                jz      sprite_render_next_line_msx2

sprite_render_line_msx2_go:
                mov     eax,0
                test    byte ptr [offset falsemask+edx],BIT_6
                jz      sprite_render_line_msx2_normal
                mov     eax,0FFFFFFFFh

sprite_render_line_msx2_normal:
                ;cmp     al,byte ptr [offset spritemask+esi]
                ;ja      sprite_render_next_line_msx2

                push    esi edx
                irp     i,<0,4,8,12>
                mov     esi,[ebp+i]
                mov     edx,[ecx+i]
                mov     ebx,[edi+i]
                or      esi,edx
                xor     edx,0FFFFFFFFh
                and     ebx,esi
                or      ebx,[ecx+32+i]
                and     edx,eax
                or      ebx,10101010h
                mov     [edi+i],ebx
                mov     [ebp+i],edx
                endm
                pop     edx esi

sprite_render_next_line_msx2:
                inc     esi
                inc     edx
                add     ecx,64
                add     edi,256
                add     ebp,256
                cmp     edx,16
                jne     sprite_render_line_msx2

                pop     esi

sprite_render_next_msx2:
                pop     ebp
                sub     esi,4
                dec     ebp   
                jnz     sprite_render_outer_msx2

                ; now we must clear the redbuffer
                
                mov     ebp,save_ebp
                mov     esi,save_esi


                ; at this point
                ; esi = pointer to last sprite's attribute table
                ; ebp = number of sprites

sprite_render_outer_clear:
                push    ebp

                ; eval sprite coordinates
                call    eval_sprite_coords_msx2

                mov     edi,eax
                movzx   eax,byte ptr [offset vdpregs+23]
                sub     edi,eax
                jns     sprite_positive_clear
                add     edi,256
sprite_positive_clear:
                jns     sprite_positive_2_clear
                add     edi,256
sprite_positive_2_clear:
                cmp     edi,212-16
                jg      sprite_render_next_clear
                sal     edi,8
                add     edi,ecx
                mov     ebp,edi
                add     edi,blitbuffer
                add     ebp,redbuffer

                ; check for crop
                cmp     ecx,0
                jl      sprite_render_next_clear
                cmp     ecx,256-16
                jge     sprite_render_next_clear
                
                ; draw the sprite in blitbuffer
                
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shr     esi,2
                xchg    eax,esi
                mov     edx,0

sprite_render_line_clear:
                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     sprite_render_line_clear_go

                test    byte ptr [offset falsemask+edx],0Fh
                jz      sprite_render_next_line_clear

sprite_render_line_clear_go:
                ;mov     ah,0
                mov     eax,0
                test    byte ptr [offset falsemask+edx],BIT_6
                jz      sprite_render_line_clear_normal
                ;mov     ah,0FFh
                mov     eax,0FFFFFFFFh

sprite_render_line_clear_normal:
                ;cmp     al,byte ptr [offset spritemask+esi]
                ;ja      sprite_render_next_line_msx2

                irp     i,<0,4,8,12>
                mov     dword ptr [ebp+i],0
                endm

sprite_render_next_line_clear:
                inc     esi
                inc     edx
                add     ecx,64
                add     edi,256
                add     ebp,256
                cmp     edx,16
                jne     sprite_render_line_clear

                pop     esi

sprite_render_next_clear:
                pop     ebp
                sub     esi,4
                dec     ebp   
                jnz     sprite_render_outer_clear


                ret

; draw_sprite_image_msx2 ---------------------------------------------
; draw a sprite image in the false buffer
; MSX2 version
; enter: esi = start of sprite attribute in vram
; exit: false sprite buffer filled with sprite image
;       edx = number of lines/rows of sprite

draw_sprite_image_msx2:
                test    byte ptr [offset vdpregs+1],BIT_1
                jz      _ret

draw_sprite_image_16_msx2:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     _ret
                
                ; only 16x16N is supported
                
                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                and     eax,11111100b
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                ; eval color mask of sprite
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,0
                mov     edi,offset falsesprite
                mov     ebx,0

draw_sprite_image_16N_loop_msx2:                     
                push    esi

                mov     eax,esi
                sub     eax,sprattrtable
                sub     eax,msxvram
                shr     eax,2
                shl     eax,4
                add     eax,sprattrtable
                add     eax,msxvram
                sub     eax,512
                mov     al,[eax+edx]

                mov     byte ptr [offset falsemask+edx],al
                and     eax,0Fh
                mov     eax,[offset backgroundcolor+eax*4]
                
                ; fetch the image for the subline
                mov     bl,[ecx]

                ; get the sprite mask
                mov     esi,[offset backgroundmask+ebx*8]

                ; get the sprite color
                mov     ebp,eax

                ; blend with the sprite image
                and     ebp,[offset foregroundmask+ebx*8]

                ; put back to screen
                mov     [edi],esi
                mov     [edi+32],ebp

                ; do it again for the next four pixels
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+4],esi
                mov     [edi+4+32],ebp
                
                ; do it again for the next eight pixels
                
                mov     bl,[ecx+16]
                
                mov     esi,[offset backgroundmask+ebx*8]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8]
                mov     [edi+8],esi
                mov     [edi+8+32],ebp
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+12],esi
                mov     [edi+12+32],ebp

                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,16
                jne     draw_sprite_image_16N_loop_msx2

                mov     edx,16
                ret

draw_sprite_image_16N_loop_msx2_or:
                and     eax,0Fh
                mov     eax,[offset backgroundcolor+eax*4]
                
                ; fetch the image for the subline
                mov     bl,[ecx]

                ; get the sprite mask
                mov     esi,[offset backgroundmask+ebx*8]

                ; get the sprite color
                mov     ebp,eax

                ; blend with the sprite image
                and     ebp,[offset foregroundmask+ebx*8]

                ; put back to screen
                or      [edi],esi
                or      [edi+32],ebp

                ; do it again for the next four pixels
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                or      [edi+4],esi
                or      [edi+4+32],ebp
                
                ; do it again for the next eight pixels
                
                mov     bl,[ecx+16]
                
                mov     esi,[offset backgroundmask+ebx*8]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8]
                or      [edi+8],esi
                or      [edi+8+32],ebp
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                or      [edi+12],esi
                or      [edi+12+32],ebp

                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,16
                jne     draw_sprite_image_16N_loop_msx2

                mov     edx,16
                ret

; eval_sprite_coords_msx2 --------------------------------------------
; evaluate sprite coordinates
; MSX2 version
; enter: esi = start of sprite attribute in vram
; exit: eax = offset y ; ecx = offset x (both are signed numbers)

eval_sprite_coords_msx2:
                movzx   eax,byte ptr [esi]        ; y coordinate
                cmp     eax,0D8h                  ; 0BEh ; 0F0h ??
                jbe     eval_sprite_coords1_msx2
                movsx   eax,al

eval_sprite_coords1_msx2:
                inc     eax
                
                xor     ecx,ecx
                mov     cl,[esi+1]      ; x coordinate

                ret
                

code32          ends
                end
