; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc

extrn msxvram: near
extrn vdpregs: near

public render_screen0
public render_screen1
public render

; DATA ---------------------------------------------------------------

enabled         dd      1
lastscreen      db      0

; render_screen0 -----------------------------------------------------
; render a screen 0 page

render_screen0:
                mov     esi,offset msxvram                
                mov     ebx,offset msxvram+0800h
                mov     edi,0a0000h+40
                mov     ecx,0
                
                mov     ebp,24
                ; draw a screen

render06:
                push    ebp
                mov     ebp,40
                ; draw a line

render05:
                push    ebp
                mov     cl,[esi]
                mov     ebp,8
                ; draw a char
render04:
                push    ebp
                mov     dl,[ebx+ecx*8]
                mov     ebp,6
                ; draw a subline
render03:                
                shl     dl,1                    ; clock 1 U
                mov     al,0                    ; clock 1 V
                rcl     al,1                    ; clock 2
                mov     gs:[edi],al             ; clock 3 U
                inc     edi                     ; clock 3 V
                dec     ebp                     ; clock 4 U
                jnz     render03                ; clock 4 V

                pop     ebp                     
                inc     ebx                     
                add     edi,320-6               
                dec     ebp                     
                jnz     render04                

                sub     ebx,8
                pop     ebp
                inc     esi
                sub     edi,320*8-6
                dec     ebp
                jnz     render05

                pop     ebp
                add     edi,320*7+80
                dec     ebp
                jnz     render06

                ret

; render_screen1 -----------------------------------------------------
; render a screen 1 page

render_screen1:
                mov     esi,offset msxvram+1800h        ; tabela de nomes
                mov     ebx,offset msxvram              ; tabela de chars
                mov     edi,0a0000h+32
                mov     ecx,0
                
                mov     ebp,24
                ; draw a screen

render16:
                push    ebp
                mov     ebp,32
                ; draw a line

render15:
                push    ebp
                mov     cl,[esi]
                mov     ebp,8
                ; draw a char
render14:
                push    ebp
                mov     dl,[ebx+ecx*8]
                mov     ebp,8
                ; draw a subline
render13:                
                shl     dl,1                    ; clock 1 U
                mov     al,0                    ; clock 1 V
                rcl     al,1                    ; clock 2
                mov     gs:[edi],al             ; clock 3 U
                inc     edi                     ; clock 3 V
                dec     ebp                     ; clock 4 U
                jnz     render13                ; clock 4 V

                pop     ebp                     
                inc     ebx                     
                add     edi,320-8
                dec     ebp                     
                jnz     render14                

                sub     ebx,8
                pop     ebp
                inc     esi
                sub     edi,320*8-8
                dec     ebp
                jnz     render15

                pop     ebp
                add     edi,320*7+64
                dec     ebp
                jnz     render16

                ret

; render -------------------------------------------------------------
; render the MSX screen, based on VDP registers and VRAM

render:
                mov     bl,byte ptr [offset vdpregs]                        
                shr     bl,1
                and     bl,1
                mov     bh,byte ptr [offset vdpregs+1]
                ; test for "video enable" flag
                test    bh,01000000b
                jnz     render1
                cmp     enabled,0
                je      render2
                mov     enabled,0
                jmp     clear
render1:
                mov     enabled,1
                shr     bh,2
                and     bh,00000110b
                or      bl,bh
                cmp     bl,lastscreen
                jz      render0
                call    clear
                mov     lastscreen,bl
render0:
                cmp     bl,0
                je      render_screen1
                cmp     bl,4
                je      render_screen0
render2:
                ret

; clear --------------------------------------------------------------
; clear the PC screen
                
clear:
                push    es
                mov     ax,gs
                mov     es,ax
                mov     eax,0
                mov     edi,0a0000h
                mov     ecx,16000
                rep     stosd
                pop     es
                ret

code32          ends
                end


