; BrMSX 1.0        
; by Ricardo Bittencourt
; start: 25/1/97

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc

extrn msxvram: near

public render_screen0

; DATA ---------------------------------------------------------------


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

code32          ends
                end


