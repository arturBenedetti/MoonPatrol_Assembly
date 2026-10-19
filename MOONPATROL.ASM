; ============================================================
; MOON PATROL - TDE B
; Etapa 2: Menu inicial com cores e acesso direto a VRAM (A000h)
; Ambiente: GUI Turbo Assembler / TASM 4.1
; Arquitetura: Intel 8086
; Modo de Video: 13h (320x200 pixels, 256 cores)
; ============================================================

.MODEL SMALL
.STACK 100h

.DATA

; Titulos sem espacos desnecessarios nas pontas (Carregamento ultra-rapido)
titulo1  DB '__  __', '$'
titulo2  DB '|  \/  |', '$'
titulo3  DB '| \  / | ___   ___  _ __', '$'
titulo4  DB '| |\/| |/ _ \ / _ \|  _ \', '$'
titulo5  DB '| |  | | (_) | (_) | | | |', '$'
titulo6  DB '|_|__|_|\___/ \___/|_| |_|_', '$'
titulo7  DB '|  __ \    | |           | |', '$'
titulo8  DB '| |__) |_ _| |_ _ __ ___ | |', '$'
titulo9  DB '|  ___/ _` | __| __//_  \| |', '$'
titulo10 DB '| |  | (_| | |_| | | (_) | |', '$'
titulo11 DB '|_|   \__,_|\__|_|  \___/|_|', '$'

jogarTxt  DB 'JOGAR', '$'
sairTxt   DB 'SAIR', '$'
msgJogo   DB 'INICIANDO MOON PATROL...', '$'
msgVolta  DB 'Pressione qualquer tecla para voltar.', '$'
msgSair   DB 'Obrigado por jogar!', '$'

selecao DB 0
animX   DW 10    ; Posicao X em pixels (0..319)

.CODE

; ============================================================
; Programa principal
; ============================================================

MAIN PROC NEAR

    MOV AX, @DATA
    MOV DS, AX

MENU_PRINCIPAL:

    ; Ativa Modo Grafico VGA 320x200 (Modo 13h)
    MOV AX, 0013h
    INT 10h

    ; Desenha o titulo FIXO uma unica vez
    CALL DESENHAR_TITULO
    CALL DESENHAR_OPCOES

CICLO_MENU:

    CALL ANIMAR_ELEMENTOS

    ; Verifica se existe tecla disponivel sem bloquear a animacao
    MOV AH, 01h
    INT 16h
    JZ CICLO_MENU       ; Se nao houver tecla, continua a animacao

    ; Le a tecla do buffer (AH = Scan Code, AL = ASCII)
    XOR AH, AH
    INT 16h

    ; Seta para cima (Scan code 48h)
    CMP AH, 48h
    JE TECLA_CIMA

    ; Seta para baixo (Scan code 50h)
    CMP AH, 50h
    JE TECLA_BAIXO

    ; ENTER (ASCII 13)
    CMP AL, 13
    JE TECLA_ENTER

    ; ESC (ASCII 27)
    CMP AL, 27
    JE ENCERRAR

    JMP CICLO_MENU

TECLA_CIMA:
    MOV selecao, 0
    CALL DESENHAR_OPCOES
    JMP ESPERA_LIBERAR_TECLA

TECLA_BAIXO:
    MOV selecao, 1
    CALL DESENHAR_OPCOES
    JMP ESPERA_LIBERAR_TECLA

ESPERA_LIBERAR_TECLA:
    ; Pequena pausa para evitar leitura repetida da mesma tecla em milissegundos
    MOV CX, 2000
PAUSA_TECLA:
    LOOP PAUSA_TECLA
    JMP CICLO_MENU

TECLA_ENTER:
    CMP selecao, 0
    JE ABRIR_JOGO
    JMP ENCERRAR

; ============================================================
; Tela provisoria do jogo
; ============================================================

ABRIR_JOGO:

    MOV AX, 0013h
    INT 10h

    MOV DH, 10
    MOV DL, 8
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET msgJogo
    MOV AH, 09h
    INT 21h

    MOV DH, 12
    MOV DL, 2
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET msgVolta
    MOV AH, 09h
    INT 21h

    ; Aguarda uma tecla para retornar
    XOR AH, AH
    INT 16h

    JMP MENU_PRINCIPAL

; ============================================================
; Encerramento
; ============================================================

ENCERRAR:

    ; Retorna ao modo texto padrao ao sair
    MOV AX, 0003h
    INT 10h

    MOV DX, OFFSET msgSair
    MOV AH, 09h
    INT 21h

    MOV AX, 4C00h
    INT 21h

MAIN ENDP


; ============================================================
; Rotina: PLOT_PIXEL
; Entrada: CX = X (0..319), DX = Y (0..199), AL = Cor
; Escreve diretamente no segmento A000h
; ============================================================

PLOT_PIXEL PROC NEAR

    PUSH AX
    PUSH BX
    PUSH ES
    PUSH DI

    MOV BX, 0A000h
    MOV ES, BX

    MOV AX, DX          ; Y
    MOV BX, 320
    MUL BX              ; Y * 320
    MOV DI, AX
    ADD DI, CX          ; (Y * 320) + X

    MOV ES:[DI], AL

    POP DI
    POP ES
    POP BX
    POP AX

    RET

PLOT_PIXEL ENDP


; ============================================================
; Rotina: DESENHAR_RETANGULO
; Entrada: CX = X, DX = Y, BX = Largura, SI = Altura, AL = Cor
; ============================================================

DESENHAR_RETANGULO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV DI, SI

LINHA_Y:
    PUSH CX
    PUSH BX

COLUNA_X:
    CALL PLOT_PIXEL
    INC CX
    DEC BX
    JNZ COLUNA_X

    POP BX
    POP CX
    INC DX
    DEC DI
    JNZ LINHA_Y

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

DESENHAR_RETANGULO ENDP


; ============================================================
; Rotina: POSICIONAR_CURSOR
; Entrada: DH = linha, DL = coluna
; ============================================================

POSICIONAR_CURSOR PROC NEAR

    PUSH AX
    PUSH BX

    MOV AH, 02h
    MOV BH, 0
    INT 10h

    POP BX
    POP AX

    RET

POSICIONAR_CURSOR ENDP


; ============================================================
; Rotina: DESENHAR_CARACTERE_COR
; Entrada: DH = linha, DL = coluna, AL = caractere, BL = cor
; ============================================================

DESENHAR_CARACTERE_COR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX

    CALL POSICIONAR_CURSOR

    MOV AH, 09h
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP CX
    POP BX
    POP AX

    RET

DESENHAR_CARACTERE_COR ENDP


; ============================================================
; Rotina: DESENHAR_LINHA_HORIZ_COR
; Entrada: DH = linha, DL = coluna, AL = caractere, BL = cor, CX = qtd
; ============================================================

DESENHAR_LINHA_HORIZ_COR PROC NEAR

    PUSH AX
    PUSH BX

    CALL POSICIONAR_CURSOR

    MOV AH, 09h
    MOV BH, 0
    INT 10h

    POP BX
    POP AX

    RET

DESENHAR_LINHA_HORIZ_COR ENDP   


; ============================================================
; Rotina: IMPRIMIR_TEXTO_COR
; Entrada: DH = linha, DL = coluna, SI = string ($), BL = cor
; ============================================================

IMPRIMIR_TEXTO_COR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

PROXIMO_CHAR:
    MOV AL, [SI]
    CMP AL, '$'
    JE FIM_TEXTO

    CALL DESENHAR_CARACTERE_COR
    INC DL              ; Avanca coluna
    INC SI              ; Proximo caractere
    JMP PROXIMO_CHAR

FIM_TEXTO:
    POP SI
    POP DX
    POP BX
    POP AX

    RET

IMPRIMIR_TEXTO_COR ENDP


; ============================================================
; Rotina: DESENHAR_TITULO
; Funcao: Desenha as 11 linhas do titulo alinhadas
; ============================================================

DESENHAR_TITULO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    MOV BL, 0Ah         ; Verde claro

    ; Linha 1
    MOV DH, 0
    MOV DL, 6
    MOV SI, OFFSET titulo1
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 2
    MOV DH, 1
    MOV DL, 5
    MOV SI, OFFSET titulo2
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 3
    MOV DH, 2
    MOV DL, 5
    MOV SI, OFFSET titulo3
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 4
    MOV DH, 3
    MOV DL, 5
    MOV SI, OFFSET titulo4
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 5
    MOV DH, 4
    MOV DL, 5
    MOV SI, OFFSET titulo5
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 6
    MOV DH, 5
    MOV DL, 5
    MOV SI, OFFSET titulo6
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 7
    MOV DH, 6
    MOV DL, 5
    MOV SI, OFFSET titulo7
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 8
    MOV DH, 7
    MOV DL, 5
    MOV SI, OFFSET titulo8
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 9
    MOV DH, 8
    MOV DL, 5
    MOV SI, OFFSET titulo9
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 10
    MOV DH, 9
    MOV DL, 5
    MOV SI, OFFSET titulo10
    CALL IMPRIMIR_TEXTO_COR

    ; Linha 11
    MOV DH, 10
    MOV DL, 5
    MOV SI, OFFSET titulo11
    CALL IMPRIMIR_TEXTO_COR

    POP SI
    POP DX
    POP BX
    POP AX

    RET

DESENHAR_TITULO ENDP


; ============================================================
; Rotina: DESENHAR_OPCOES
; Funcao: Desenha/Atualiza as caixas JOGAR e SAIR
; ============================================================

DESENHAR_OPCOES PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; ---------------- CAIXA JOGAR ----------------
    MOV BL, 0Fh              ; Branco por padrao
    CMP selecao, 0
    JNE JOGAR_COR_OK
    MOV BL, 0Ch              ; Vermelho claro se selecionado

JOGAR_COR_OK:

    MOV DH, 12
    MOV DL, 14
    MOV AL, 218
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 12
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 12
    MOV DL, 25
    MOV AL, 191
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 13
    MOV DL, 14
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 13
    MOV DL, 17
    MOV SI, OFFSET jogarTxt
    CALL IMPRIMIR_TEXTO_COR

    MOV DH, 13
    MOV DL, 25
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 14
    MOV DL, 14
    MOV AL, 192
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 14
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 14
    MOV DL, 25
    MOV AL, 217
    CALL DESENHAR_CARACTERE_COR


    ; ---------------- CAIXA SAIR ----------------
    MOV BL, 0Fh              ; Branco por padrao
    CMP selecao, 1
    JNE SAIR_COR_OK
    MOV BL, 0Ch              ; Vermelho claro se selecionado

SAIR_COR_OK:

    MOV DH, 16
    MOV DL, 14
    MOV AL, 218
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 16
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 16
    MOV DL, 25
    MOV AL, 191
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 17
    MOV DL, 14
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 17
    MOV DL, 17
    MOV SI, OFFSET sairTxt
    CALL IMPRIMIR_TEXTO_COR

    MOV DH, 17
    MOV DL, 25
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 18
    MOV DL, 14
    MOV AL, 192
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 18
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 18
    MOV DL, 25
    MOV AL, 217
    CALL DESENHAR_CARACTERE_COR

    POP DX
    POP CX
    POP BX
    POP AX

    RET

DESENHAR_OPCOES ENDP


; ============================================================
; Rotina: ANIMAR_ELEMENTOS
; Funcao: Anima o jipe e a nave na parte inferior da tela
; ============================================================

ANIMAR_ELEMENTOS PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV CX, 4000
ATRASO:
    LOOP ATRASO

    ; Apaga posicao anterior
    MOV CX, animX
    MOV DX, 188
    MOV BX, 12
    MOV SI, 8
    MOV AL, 0
    CALL DESENHAR_RETANGULO

    MOV CX, animX
    ADD CX, 30
    MOV DX, 180
    MOV BX, 10
    MOV SI, 6
    CALL DESENHAR_RETANGULO

    ; Avanca X
    ADD animX, 2
    CMP animX, 270
    JB POSICAO_OK

    MOV animX, 10

POSICAO_OK:

    ; Desenha Jipe (Amarelo)
    MOV CX, animX
    MOV DX, 188
    MOV BX, 12
    MOV SI, 8
    MOV AL, 0Eh
    CALL DESENHAR_RETANGULO

    ; Desenha Nave (Ciano)
    MOV CX, animX
    ADD CX, 30
    MOV DX, 180
    MOV BX, 10
    MOV SI, 6
    MOV AL, 0Bh
    CALL DESENHAR_RETANGULO

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

ANIMAR_ELEMENTOS ENDP

END MAIN