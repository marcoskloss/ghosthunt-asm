.model small     
      
.stack 100H

.data
     game_title db '    ______  _                        ',10,13
                db '   / _____)| |                  _    ',10,13
                db '  | /  ___ | | _    ___    ___ | |_  ',10,13
                db '  | | (___)| || \  / _ \  /___)|  _) ',10,13
                db '  | \____/|| | | || |_| ||___ || |__ ',10,13
                db '   \_____/ |_| |_| \___/ (___/  \___)',10,13
                db '                                     ',10,13
                db '       _     _                       ',10,13
                db '      | |   | |               _      ',10,13
                db '      | |__ | | _   _  ____  | |_    ',10,13
                db '      |  __)| || | | ||  _ \ |  _)   ',10,13
                db '      | |   | || |_| || | | || |__   ',10,13
                db '      |_|   |_| \____||_| |_| \___)  ',10,13                  
    title_len  equ $-game_title
    options  db '                  Jogar              ',10,13,10,13
             db '                  Sair               '
    options_len equ $-options
    current_screen db 1 ; 0 - Menu, 1 - Jogo, 2 - Fim de jogo
    screen_width dw 13FH
    screen_height dw 0C7H
    
    hunter dw 099H,0BBH,0AH,0CH ;x,y,width,height
    hunter_mask db 0,0,0,1,1,1,1,0,0,0
                db 0,0,1,1,1,1,1,1,1,0
                db 0,0,1,1,1,1,1,1,1,1
                db 0,1,1,0,0,1,1,1,1,1
                db 1,1,1,1,1,1,1,1,0,0
                db 1,1,1,1,1,1,1,0,0,0
                db 1,1,1,1,1,0,0,0,0,0
                db 1,1,1,1,1,1,0,0,0,0
                db 1,1,1,1,1,1,1,0,0,0
                db 0,1,1,1,1,1,1,1,1,1
                db 0,0,1,1,1,1,1,1,1,0
                db 0,0,0,1,1,1,1,0,0,0
.code
    PUSH_CONTEXT macro
        push AX
        push BX
        push CX
        push DX
        push DI
        push SI
        push BP
    endm
    POP_CONTEXT macro
        pop BP
        pop SI
        pop DI
        pop DX
        pop CX
        pop BX
        pop AX
    endm
    SET_VIDEO_MODE macro
        ;https://stanislavs.org/helppc/int_10.html
        mov AH, 00H
        mov AL, 13H
        int 10h
    endm
    HIDE_CURSOR macro
        mov cx, 2507h
        mov ah, 01
        int 10h
    endm
    END_PROGRAM macro
        mov AH, 4CH
        mov AL, 0
        int 21H
    endm
    RENDER_TITLE macro
        PUSH_CONTEXT
        mov BL, 0AH
        mov CX, title_len
        mov DH, 0
        mov DL, 0
        mov ES:BP, offset game_title
        call PRINT_STRING
        POP_CONTEXT
    endm
    RENDER_OPTIONS macro
        PUSH_CONTEXT
        mov BL, 0FH
        mov CX, options_len
        mov DH, 19
        mov DL, 0
        mov ES:BP, offset options
        call PRINT_STRING
        POP_CONTEXT
    endm
    MARK_PLAY_OPTION macro
        push DI
        mov DI, offset options
        add DI, 16
        mov [DI], '['
        add DI, 8
        mov [DI], ']'
        pop DI
    endm
    UNMARK_PLAY_OPTION macro
        push DI
        mov DI, offset options
        add DI, 16
        mov [DI], ' '
        add DI, 8
        mov [DI], ' '
        pop DI
    endm
    MARK_QUIT_OPTION macro
        push DI
        mov DI, offset options
        add DI, 57
        mov [DI], '['
        add DI, 8
        mov [DI], ']'
        pop DI
    endm
    UNMARK_QUIT_OPTION macro
        push DI
        mov DI, offset options
        add DI, 57
        mov [DI], ' '
        add DI, 8
        mov [DI], ' '
        pop DI
    endm

    ; CX - x
    ; DX - y
    ; BX - color
    WRITE_PIXEL proc
        PUSH_CONTEXT
        push BX
        
        mov BX, 0A000H
        mov ES, BX
        
        ; row + col * 320
        mov AX, DX ; AX = Y
        mov BX, 320
        mul BX ; AX = AX * 320
        add AX, CX ; AX += X
        
        pop BX ; to get color value
        
        mov DI, AX
        mov ES:[DI], BL
        POP_CONTEXT
        ret
    endp
    
    ; BL cor
    ; CX qtd chars da string
    ; DH linha
    ; DL coluna
    ; ES:BP offset da string
    PRINT_STRING proc
        push AX
        mov AH, 13H ; set write string
        mov AL, 0 ; set write mode (https://stanislavs.org/helppc/int_10-13.html)
        mov BH, 0H ; set page number
        int 10H
        pop AX
        ret
    endp
    
    CLEAR_SCREEN proc
        PUSH_CONTEXT
        SET_VIDEO_MODE
        POP_CONTEXT
        ret
    endp

    ; a proc atualiza o BL e BH conforme a opcao selecionada 
    CHECK_KEYPRESS proc
        push AX
        xor AH, AH
        
        ; https://stanislavs.org/helppc/int_16.html
        mov AH, 01H ; Get keystroke status      
        int 16H ; AH = scan code            
           
        ; comparando somente a parte alta
        cmp AH, 1CH ; Enter
        je enter_key
        
        cmp AH, 48H ; Up Arrow
        je arrow_up_key
        
        cmp AH, 50H ; Down Arrow
        je arrow_down_key
        
        jmp end_check_kreypress
            
        enter_key:
            mov BH, 1H
            jmp end_check_kreypress
            
        arrow_up_key:
            mov BL, 0
            MARK_PLAY_OPTION
            UNMARK_QUIT_OPTION
            jmp end_check_kreypress
            
        arrow_down_key:
            mov BL, 1
            MARK_QUIT_OPTION
            UNMARK_PLAY_OPTION
            
        end_check_kreypress:
            ; clearing keyboard buffer
            mov AH,0CH
            mov AL,0
            int 21h
            pop AX
        ret
    endp
    
    ; essa proc altera o valor de BX
    RENDER_MENU proc
        RENDER_TITLE
        
        ; BL = 0 - Jogar, 1 - Sair
        ; BH = 0 - Enter nao selecionado, 1 - Enter selecionado
        
        RENDER_OPTIONS
        call CHECK_KEYPRESS
        
        cmp BH, 0
        je end_render_menu
        
        cmp BL, 0
        je play_opt_selected
        
        ; Sair foi selecionado
        call CLEAR_SCREEN
        END_PROGRAM
        
        play_opt_selected:
            mov current_screen, 1H
            
        end_render_menu:
        ret
    endp
    
    ; DI - object offset
    APPLY_HUNTER_MASK proc
        mov BX, 0H ; color
        mov CX, [DI]
        mov DX, [DI+2] ; offset to get Y
        
        call WRITE_PIXEL ; line 1
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        add CX, 5
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 2
        mov CX, [DI]
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        add CX, 8
        call WRITE_PIXEL
        
        inc DX ; line 3
        mov CX, [DI]
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 4
        mov CX, [DI]
        call WRITE_PIXEL
        add CX, 3
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 5
        mov CX, [DI]
        add CX, 9
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 6
        mov CX, [DI]
        add CX, 8
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 7
        mov CX, [DI]
        add CX, 6
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 8
        mov CX, [DI]
        add CX, 7
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 9
        mov CX, [DI]
        add CX, 8
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        
        inc DX ; line 10
        mov CX, [DI]
        call WRITE_PIXEL
        
        inc DX ; line 11
        mov CX, [DI]
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        add CX, 9
        call WRITE_PIXEL
        
        inc DX ; line 12
        mov CX, [DI]
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        add CX, 6
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        inc CX
        call WRITE_PIXEL
        ret
    endp
    
    ; DI - object offset
    ; SI - object mask offset
    ; BX - color
    DRAW_CHARACTER proc
        PUSH_CONTEXT
        
        mov CX, [DI]
        mov DX, [DI+2] ; offset to get Y
        
        draw_character_row:
            push BX ;(X - X0) + (Y - Y0) * 10
            mov AX, DX ; AX = Y
            sub AX, [DI+2] ; AX = Y - Y0
            mov BL, [DI+4] ; BL = width = 10
            mul BL ; AX = (Y - Y0) * 10
            mov BX, CX ; BX = X
            sub BX, [DI] ; BX = X - X0
            add AX, BX ; AX = (Y - Y0) * 10 + (X - X0) 
            pop BX ; restore BX
            add SI, AX ; apply offset
            cmp [SI], 1
            je should_write_pixel
            sub SI, AX ; undo add SI,AX
            jmp next_pixel
            
            should_write_pixel:
                sub SI, AX ; undo add SI,AX
                call WRITE_PIXEL
                
            next_pixel:
            inc CX ; if CX - x > width then next_row else next_col
            mov AX, CX
            sub AX, [DI]
            cmp AX, [DI+4] ; offset to get width
            jng draw_character_row ; jump not greater (else)
            
            inc DX ; next row
            mov CX, [DI] ; reset to 1st col
            
            mov AX, DX ; if DX - y > y_size then end_proc else next_row
            sub AX, [DI+2]
            cmp AX, [DI+6]
            jng draw_character_row
        POP_CONTEXT
        ret
    endp
    
    RENDER_GAME proc
        PUSH_CONTEXT
        
        mov DI, offset hunter
        mov SI, offset hunter_mask
        mov BX, 0EH ; color
        call DRAW_CHARACTER
        ;call APPLY_HUNTER_MASK
        
        POP_CONTEXT
        ret
    endp
    
    main:       
        mov AX, @DATA 
        mov DS, AX  
        mov AX,@DATA 
        mov ES, AX
      
        SET_VIDEO_MODE
        HIDE_CURSOR
        
        MARK_PLAY_OPTION ; menu inicia com a opcao Jogar selecionada
        xor BX, BX ; inicializar valor de BX para a proc do render_menu
        
        game_loop:
            cmp current_screen, 0H
            je menu
            
            cmp current_screen, 1H
            je game
            
            ; call RENDER_END_GAME
            ;jmp game_loop
            jmp end_prog
            
            menu:
                call RENDER_MENU
                jmp game_loop
                
           game:
                call RENDER_GAME
                jmp game_loop

            end_prog:
        END_PROGRAM
end main
