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

titulo1 DB ' __  __  ___  ___  _   _   ', '$'
titulo2 DB '|  \/  |/ _ \/ _ \| \ | |  ', '$'
titulo3 DB '| |\/| | | | | | |  \| |  ', '$'
titulo4 DB '| |  | | |_| | |_| | |\  |  ', '$'
titulo5 DB '|_|  |_|\___/ \___/|_| \_|  ', '$'

jogarTxt  DB 'JOGAR', '$'
sairTxt   DB 'SAIR', '$'
msgJogo   DB 'INICIANDO MOON PATROL...', '$'
msgVolta  DB 'Pressione qualquer tecla para voltar.', '$'
msgSair   DB 'Obrigado por jogar!', '$'

selecao DB 0
animX   DW 10    ; Posição X em pixels (0..319)

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

    CALL DESENHAR_MENU

CICLO_MENU:

    CALL ANIMAR_ELEMENTOS

    ; Verifica se existe tecla disponivel
    MOV AH, 01h
    INT 16h
    JZ CICLO_MENU

    ; Le a tecla
    XOR AH, AH
    INT 16h

    ; Seta para cima
    CMP AH, 48h
    JE TECLA_CIMA

    ; Seta para baixo
    CMP AH, 50h
    JE TECLA_BAIXO

    ; ENTER
    CMP AL, 13
    JE TECLA_ENTER

    ; ESC
    CMP AL, 27
    JE ENCERRAR

    JMP CICLO_MENU

TECLA_CIMA:
    MOV selecao, 0
    CALL DESENHAR_MENU
    JMP CICLO_MENU

TECLA_BAIXO:
    MOV selecao, 1
    CALL DESENHAR_MENU
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

    ; Aguarda uma tecla
    XOR AH, AH
    INT 16h

    JMP MENU_PRINCIPAL

; ============================================================
; Encerramento
; ============================================================

ENCERRAR:

    ; Retorna ao modo texto padrao
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

    ; Define ES para o segmento de memoria de video
    MOV BX, 0A000h
    MOV ES, BX

    ; Calcula Offset: DI = (Y * 320) + X
    MOV AX, DX          ; Coloca Y em AX (AX = Y)
    MOV BX, 320         ; BX = 320
    MUL BX              ; DX:AX = AX * BX  (Y * 320)
    MOV DI, AX          ; DI = resultado de (Y * 320)
    ADD DI, CX          ; DI = (Y * 320) + X

    ; Escreve a cor na VRAM
    MOV ES:[DI], AL

    POP DI
    POP ES
    POP BX
    POP AX

    RET

PLOT_PIXEL ENDP


; ============================================================
; Rotina: DESENHAR_RETANGULO
; Entrada:
;   CX = X1, DX = Y1 (Canto superior esquerdo)
;   BX = Largura, SI = Altura
;   AL = Cor
; ============================================================

DESENHAR_RETANGULO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV DI, SI          ; Salva altura em DI (contador vertical)

LINHA_Y:
    PUSH CX             ; Salva X inicial
    PUSH BX             ; Salva largura (contador horizontal)

COLUNA_X:
    CALL PLOT_PIXEL
    INC CX
    DEC BX
    JNZ COLUNA_X

    POP BX
    POP CX
    INC DX              ; Proxima linha Y
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
; Entrada: DH = linha, DL = coluna inicial, AL = caractere, 
;          BL = cor, CX = quantidade
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
; Rotina: DESENHAR_MENU
; Funcao: Desenha a interface com caixas ASCII formatadas
; ============================================================

DESENHAR_MENU PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Re-inicializa tela em Modo 13h
    MOV AX, 0013h
    INT 10h

    ; Titulo em ASCII Art
    MOV DH, 2
    MOV DL, 6
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET titulo1
    MOV AH, 09h
    INT 21h

    MOV DH, 3
    MOV DL, 6
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET titulo2
    MOV AH, 09h
    INT 21h

    MOV DH, 4
    MOV DL, 6
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET titulo3
    MOV AH, 09h
    INT 21h

    MOV DH, 5
    MOV DL, 6
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET titulo4
    MOV AH, 09h
    INT 21h

    MOV DH, 6
    MOV DL, 6
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET titulo5
    MOV AH, 09h
    INT 21h

    ; ---------------- CAIXA JOGAR ----------------
    MOV BL, 0Fh              ; Branco
    CMP selecao, 0
    JNE JOGAR_COR_OK
    MOV BL, 0Ch              ; Vermelho claro se selecionado

JOGAR_COR_OK:

    ; Linha Superior (+ -------- +)
    MOV DH, 12
    MOV DL, 14
    MOV AL, 218              ; +
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 12
    MOV DL, 15
    MOV AL, 196              ; -
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 12
    MOV DL, 25
    MOV AL, 191              ; +
    CALL DESENHAR_CARACTERE_COR

    ; Meio (¦  JOGAR   ¦)
    MOV DH, 13
    MOV DL, 14
    MOV AL, 179              ; ¦
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 13
    MOV DL, 17
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET jogarTxt
    MOV AH, 09h
    INT 21h

    MOV DH, 13
    MOV DL, 25
    MOV AL, 179              ; ¦
    CALL DESENHAR_CARACTERE_COR

    ; Linha Inferior (+ -------- +)
    MOV DH, 14
    MOV DL, 14
    MOV AL, 192              ; +
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 14
    MOV DL, 15
    MOV AL, 196              ; -
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 14
    MOV DL, 25
    MOV AL, 217              ; +
    CALL DESENHAR_CARACTERE_COR


    ; ---------------- CAIXA SAIR ----------------
    MOV BL, 0Fh              ; Branco
    CMP selecao, 1
    JNE SAIR_COR_OK
    MOV BL, 0Ch              ; Vermelho claro se selecionado

SAIR_COR_OK:

    ; Linha Superior (+ -------- +)
    MOV DH, 17
    MOV DL, 14
    MOV AL, 218              ; +
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 17
    MOV DL, 15
    MOV AL, 196              ; -
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 17
    MOV DL, 25
    MOV AL, 191              ; +
    CALL DESENHAR_CARACTERE_COR

    ; Meio (¦   SAIR    ¦)
    MOV DH, 18
    MOV DL, 14
    MOV AL, 179              ; ¦
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 18
    MOV DL, 17
    CALL POSICIONAR_CURSOR
    MOV DX, OFFSET sairTxt
    MOV AH, 09h
    INT 21h

    MOV DH, 18
    MOV DL, 25
    MOV AL, 179              ; ¦
    CALL DESENHAR_CARACTERE_COR

    ; Linha Inferior (+ -------- +)
    MOV DH, 19
    MOV DL, 14
    MOV AL, 192              ; +
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 19
    MOV DL, 15
    MOV AL, 196              ; -
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 19
    MOV DL, 25
    MOV AL, 217              ; +
    CALL DESENHAR_CARACTERE_COR

    POP DX
    POP CX
    POP BX
    POP AX

    RET

DESENHAR_MENU ENDP


; ============================================================
; Rotina: ANIMAR_ELEMENTOS
; Funcao: Desenha elementos gráficos via VRAM (A000h)
; ============================================================

ANIMAR_ELEMENTOS PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Pausa
    MOV CX, 20000
ATRASO:
    LOOP ATRASO

    ; Apaga posição anterior desenhando um bloco preto (cor 0)
    MOV CX, animX
    MOV DX, 175
    MOV BX, 12
    MOV SI, 8
    MOV AL, 0            ; Preto
    CALL DESENHAR_RETANGULO

    ; Apaga naves anteriores
    MOV CX, animX
    ADD CX, 30
    MOV DX, 160
    MOV BX, 10
    MOV SI, 6
    CALL DESENHAR_RETANGULO

    ; Incrementa X em pixels
    ADD animX, 2
    CMP animX, 270
    JB POSICAO_OK

    MOV animX, 10

POSICAO_OK:

    ; Desenha Jipe (Bloco Amarelo - Cor 0Eh)
    MOV CX, animX
    MOV DX, 175
    MOV BX, 12
    MOV SI, 8
    MOV AL, 0Eh
    CALL DESENHAR_RETANGULO

    ; Desenha Nave (Bloco Ciano - Cor 0Bh)
    MOV CX, animX
    ADD CX, 30
    MOV DX, 160
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