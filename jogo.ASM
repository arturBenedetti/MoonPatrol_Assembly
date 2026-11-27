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

TEMPO_INICIAL  EQU 60       ; segundos de jogo
COL_TEMPO      EQU 33       ; coluna de texto do contador (x = 33*8 = 264)
tempoRestante  DW 60
ultimoTick     DW 0

jipeX   DW 0          ; posicao X do jipe
jipeY   DW 160        ; posicao Y do jipe
VELOCIDADE EQU 3      ; pixels por movimento
LIMITE_X   EQU 140    ; metade da tela (160) - largura do jipe (20)

CHAO         EQU 160   ; Y do jipe no chao
ALTURA_PULO  EQU 15    ; altura maxima do pulo (px)
VEL_PULO     EQU 3     ; px por quadro na subida e na descida
DESLOC_TOPO  EQU 5     ; px horizontais que ele "fica" no topo
estadoPulo   DB 0      ; 0 = chao, 1 = subindo, 2 = topo, 3 = descendo
deslocTopo   DW 0      ; px andados na horizontal enquanto esta no topo
oldX         DW 0      ; posicao anterior (para apagar)
oldY         DW 0

LIMITE_SUP       EQU 15    ; linha limite do tiro superior
TIRO_SUP_ALT     EQU 4     ; tiro superior: 2 px de largura x 4 de altura
VEL_TIRO_SUP     EQU 4     ; px por quadro
VEL_TIRO_FRENTE  EQU 4     ; px por quadro
ALCANCE_FRENTE   EQU 50    ; distancia maxima do tiro frontal (px)
COR_TIRO_SUP     EQU 0Eh   ; amarelo
COR_TIRO_FRENTE  EQU 0Ch   ; vermelho

pedidoTiro   DB 0          ; 1 = espaco foi apertado neste quadro
tiroSupAtivo DB 0
tiroSupX     DW 0
tiroSupY     DW 0          ; linha do topo do tiro
tiroFrAtivo  DB 0
tiroFrX      DW 0
tiroFrY      DW 0
tiroFrDist   DW 0          ; px ja percorridos

MAX_NAVES   EQU 3
NAVE_W      EQU 14
NAVE_H      EQU 14
NAVE_Y_MIN  EQU 15      ; linha minima de aparecimento
NAVE_Y_MAX  EQU 100     ; linha maxima de aparecimento
NAVE_DIST   EQU 30      ; distancia minima entre naves do grupo
VEL_NAVE    EQU 1       ; px por quadro (para a esquerda)

naveAtiva   DW 0, 0, 0
ESPERA_NAVE EQU 140          ; quadros entre naves do grupo (~2 s a 70 Hz)
naveEspera  DW 0, 0, 0       ; quadros ate a nave entrar na tela
naveX       DW 0, 0, 0
naveY       DW 0, 0, 0
tipoGrupo   DW 0        ; 0, 2 ou 4 (indice na tabela, em bytes)
qtdGrupo    DW 0
yMinProx    DW 0
navesVivas  DW 0
apagarFlag  DB 0        ; 1 = desenhar_nave apaga em vez de desenhar
semente     DW 1234h

BOMBA_W     EQU 2
BOMBA_H     EQU 4
VEL_BOMBA   EQU 2        ; px por quadro
SOLO        EQU 170      ; linha do solo (CHAO + altura do jipe)
COR_BOMBA   EQU 0Fh      ; branco (nao confunde com EH_NAVE nem EH_ROCHA)

bombaAtiva  DW 0, 0, 0   ; uma bomba por nave (mesmo indice)
bombaX      DW 0, 0, 0
bombaY      DW 0, 0, 0
naveTimer   DW 0, 0, 0   ; quadros ate o proximo disparo
vidas       DB 3

COL_PONTOS     EQU 17       ; coluna de texto (x = 17*8 = 136)
PONTOS_NAVE    EQU 100
pontos         DW 0

COR_PISO    EQU 0Eh          ; amarelo
PISO_ALT    EQU 200 - SOLO   ; 30 linhas (Y = 170 a 199)

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
msgSair   DB 'Obrigado por jogar!', '$'
msgGameOver    DB 'GAME OVER', '$'
msgScore       DB 'SCORE: ', '$'

relogio_map DB 0, 0, 0Eh, 0Eh, 0Eh, 0, 0
            DB 0, 0Eh, 0Eh, 00h, 0Eh, 0Eh, 0
            DB 0Eh, 0Eh, 0Eh, 00h, 0Eh, 0Eh, 0Eh
            DB 0Eh, 0Eh, 0Eh, 00h, 00h, 00h, 0Eh
            DB 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh
            DB 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh
            DB 0, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0
            DB 0, 0, 0Eh, 0Eh, 0Eh, 0, 0
            
vida1_map DB 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0
          
vida2_map DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0
          DB 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0
          
vida3_map DB 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0
          DB 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
          DB 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
          DB 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
          DB 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
          DB 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 4, 4, 4, 4, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0
          DB 0, 0, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 4, 4, 0, 0, 0, 0
          
jipe_map DB 7, 7, 7, 7, 7, 7, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 7, 7, 7, 7, 7, 7, 7, 7
         DB 7, 7, 7, 7, 0Ch, 0Ch, 0Ch, 0Ch, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Ch, 7, 7, 7, 7, 7, 7
         DB 7, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Bh, 0Bh, 0Bh, 0Bh, 0Ch, 0Ch, 0Ch, 0Ch, 7, 7, 7
         DB 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 7
         DB 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 1, 1, 1, 1
         DB 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 0Ch, 7, 7, 7
         DB 7, 0Bh, 1, 1, 1, 0Bh, 7, 1, 1, 1, 0Bh, 7, 7, 7, 0Bh, 1, 1, 1, 0Bh, 7
         DB 7, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 1, 7, 7, 1, 1, 1, 1, 1, 7
         DB 7, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 1, 7, 7, 1, 1, 1, 1, 1, 7
         DB 7, 0Bh, 1, 1, 1, 0Bh, 7, 0Bh, 1, 1, 1, 0Bh, 7, 7, 0Bh, 1, 1, 1, 0Bh, 7
         
nave1_map DB 7, 7, 7, 7, 7, 7, 0Bh, 0Bh, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 7, 7
          DB 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7
          DB 7, 0Bh, 0Bh, 0Bh, 0Ch, 0Ch, 0Bh, 0Bh, 0Ch, 0Ch, 0Bh, 0Bh, 0Bh, 7
          DB 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7
          DB 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7
          DB 0Eh, 0Eh, 0Eh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Eh, 0Eh, 0Eh
          DB 0Eh, 0Eh, 0Eh, 0Eh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Eh, 0Eh, 0Eh, 0Eh
          DB 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh
          DB 7, 7, 0Ch, 0Ch, 7, 7, 7, 7, 7, 7, 0Ch, 0Ch, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          
nave2_map DB 7, 7, 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 7, 7, 7
          DB 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 7
          DB 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Ch, 0Bh, 0Bh, 0Bh, 7, 7, 7
          DB 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 7
          DB 7, 7, 7, 7, 0Bh, 0Bh, 7, 7, 0Bh, 0Bh, 7, 7, 7, 7
          DB 0Bh, 0Bh, 0Bh, 0Bh, 0Ch, 7, 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 7
          DB 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 0Ch, 0Ch, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh
          DB 0Bh, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 0Ch, 7, 0Bh, 0Bh, 0Bh, 0Bh, 0Bh
          DB 7, 0Bh, 0Bh, 0Bh, 0Bh, 7, 7, 7, 7, 0Bh, 0Bh, 0Bh, 0Bh, 7
          DB 7, 7, 0Bh, 0Bh, 7, 7, 7, 7, 7, 7, 0Bh, 0Bh, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          
nave3_map DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 7, 7, 7, 7, 7
          DB 7, 7, 7, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 7, 7, 7, 7
          DB 7, 7, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 7, 7
          DB 7, 0Eh, 0Eh, 0Eh, 0Ch, 0Ch, 0Ch, 0Eh, 0Ch, 0Eh, 0Eh, 0Eh, 0Eh, 7
          DB 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh
          DB 7, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 7
          DB 7, 7, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 0Eh, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
          
rocha1_map DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 7, 7, 6, 6, 2, 7, 7, 7, 7
           DB 7, 7, 7, 6, 6, 6, 6, 2, 2, 7, 7, 7
           DB 7, 6, 6, 6, 6, 6, 6, 2, 2, 7, 7, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2
           
rocha2_map DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 7, 7, 6, 6, 2, 7, 7, 7, 7
           DB 7, 7, 7, 6, 6, 6, 6, 2, 2, 7, 7, 7
           DB 7, 7, 6, 6, 6, 6, 6, 6, 6, 2, 7, 7
           DB 7, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           
rocha3_map DB 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
           DB 7, 7, 7, 6, 6, 2, 2, 7, 7, 7, 7, 7
           DB 7, 7, 6, 6, 6, 6, 2, 2, 7, 7, 7, 7
           DB 7, 6, 6, 6, 6, 6, 6, 2, 7, 7, 7, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 2, 7, 7, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 7, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           
rocha4_map DB 7, 7, 7, 7, 7, 6, 6, 2, 7, 7, 7, 7
           DB 7, 7, 7, 6, 6, 6, 6, 2, 2, 7, 7, 7
           DB 7, 7, 6, 6, 6, 6, 6, 6, 2, 2, 7, 7
           DB 7, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2, 7
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           DB 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2
           
tabNaves    DW OFFSET nave1_map, OFFSET nave2_map, OFFSET nave3_map

selecao DB 0
animX   DW 10    ; Posicao X em pixels (0..319)

.CODE

; ============================================================
; Programa principal
; ============================================================

MAIN PROC NEAR

    MOV AX, @data
    MOV DS, AX

MENU_PRINCIPAL:

    ; Ativa Modo Grafico VGA 320x200 (Modo 13h)
    MOV AX, 0013h
    INT 10h

    ; Desenha o titulo FIXO uma unica vez
    CALL DESENHAR_TITULO
    CALL DESENHAR_OPCOES
    
    ; ==========================================================
    ; EXIBIR JIPE E AS 3 NAVES NO MENU
    ; ==========================================================
    
    ; 1. Desenhar o Jipe
    MOV CX, 95
    MOV DX, 100
    MOV BX, 20
    MOV SI, 10
    MOV DI, OFFSET jipe_map
    CALL DESENHAR_SPRITE

    ; 2. Desenhar a Nave 1
    MOV CX, 140
    MOV DX, 100
    MOV BX, 14
    MOV SI, 14
    MOV DI, OFFSET nave1_map
    CALL DESENHAR_SPRITE

    ; 3. Desenhar a Nave 2
    MOV CX, 170
    MOV DX, 100
    MOV BX, 14
    MOV SI, 14
    MOV DI, OFFSET nave2_map
    CALL DESENHAR_SPRITE

    ; 4. Desenhar a Nave 3
    MOV CX, 200
    MOV DX, 100
    MOV BX, 14
    MOV SI, 14
    MOV DI, OFFSET nave3_map
    CALL DESENHAR_SPRITE

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
    JE IR_ENCERRAR

    JMP CICLO_MENU

IR_ENCERRAR:
    JMP ENCERRAR

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

    ; Desenha 3 coracoes de vida
    MOV CX, 0
    MOV DX, 0
    MOV BX, 18
    MOV SI, 11
    MOV DI, OFFSET vida3_map
    CALL DESENHAR_SPRITE

    ; Desenha relogio
    MOV CX, 250
    MOV DX, 0
    MOV BX, 7
    MOV SI, 8
    MOV DI, OFFSET relogio_map
    CALL DESENHAR_SPRITE
    
    ; Desenha o piso amarelo (largura total da tela)
    MOV CX, 0
    MOV DX, SOLO
    MOV BX, 320
    MOV SI, PISO_ALT
    MOV AL, COR_PISO
    CALL PREENCHER_RETANGULO

    ; Estado inicial
    MOV jipeX, 0
    MOV jipeY, CHAO
    MOV estadoPulo, 0
    MOV deslocTopo, 0
    CALL DESENHAR_JIPE
    
    MOV tempoRestante, TEMPO_INICIAL
    MOV AH, 00h                ; le o contador de ticks da BIOS
    INT 1Ah
    MOV ultimoTick, DX
    MOV semente, DX            ; semente aleatoria vinda do relogio
    MOV naveAtiva, 0           ; nenhuma nave ativa
    MOV naveAtiva + 2, 0
    MOV naveAtiva + 4, 0
    MOV naveEspera, 0
    MOV naveEspera + 2, 0
    MOV naveEspera + 4, 0
    MOV bombaAtiva, 0
    MOV bombaAtiva + 2, 0
    MOV bombaAtiva + 4, 0
    MOV vidas, 3
    MOV pontos, 0
    CALL DESENHAR_PONTOS
    CALL DESENHAR_TEMPO
    
    MOV pedidoTiro, 0
    MOV tiroSupAtivo, 0
    MOV tiroFrAtivo, 0

LOOP_JOGO:

    CALL ESPERA_VSYNC

    ; Guarda posicao anterior
    MOV AX, jipeX
    MOV oldX, AX
    MOV AX, jipeY
    MOV oldY, AX

; ---------- Leitura das teclas (esvazia o buffer) ----------
LER_TECLAS:
    MOV AH, 01h
    INT 16h
    JZ FIM_TECLAS

    XOR AH, AH
    INT 16h

    CMP AL, 27                 ; ESC volta ao menu
    JNE NAO_ESC
    JMP MENU_PRINCIPAL
    
NAO_ESC:
    CMP AL, 20h                ; barra de espaco
    JNE NAO_ESPACO
    MOV pedidoTiro, 1
    JMP LER_TECLAS
    
NAO_ESPACO:
    CMP AH, 4Bh                ; seta esquerda
    JE TECLA_ESQ
    CMP AH, 4Dh                ; seta direita
    JE TECLA_DIR
    CMP AH, 48h                ; seta cima
    JE TECLA_PULO
    JMP LER_TECLAS

TECLA_ESQ:
    MOV AX, jipeX
    MOV BX, AX                 ; BX = X antigo
    SUB AX, VELOCIDADE
    JNC ESQ_OK
    XOR AX, AX                 ; trava em 0
ESQ_OK:
    MOV jipeX, AX
    CMP estadoPulo, 2          ; no topo? acumula deslocamento
    JNE LER_TECLAS
    SUB BX, AX                 ; px realmente andados
    ADD deslocTopo, BX
    JMP LER_TECLAS

TECLA_DIR:
    MOV AX, jipeX
    MOV BX, AX                 ; BX = X antigo
    ADD AX, VELOCIDADE
    CMP AX, LIMITE_X
    JBE DIR_OK
    MOV AX, LIMITE_X           ; trava na metade esquerda
DIR_OK:
    MOV jipeX, AX
    CMP estadoPulo, 2
    JNE LER_TECLAS
    SUB AX, BX                 ; px realmente andados
    ADD deslocTopo, AX
    JMP LER_TECLAS

TECLA_PULO:
    CMP estadoPulo, 0          ; so pula se estiver no chao
    JNE LER_TECLAS
    MOV estadoPulo, 1
    JMP LER_TECLAS

; ---------- Atualiza o pulo (1 passo por quadro) ----------
FIM_TECLAS:
    CMP estadoPulo, 1
    JE PULO_SUBINDO
    CMP estadoPulo, 2
    JE PULO_TOPO
    CMP estadoPulo, 3
    JE PULO_DESCENDO
    JMP REDESENHAR

PULO_SUBINDO:
    SUB jipeY, VEL_PULO
    CMP jipeY, CHAO - ALTURA_PULO
    JA REDESENHAR              ; ainda nao chegou ao topo
    MOV jipeY, CHAO - ALTURA_PULO
    MOV estadoPulo, 2
    MOV deslocTopo, 0
    JMP REDESENHAR

PULO_TOPO:
    CMP deslocTopo, DESLOC_TOPO
    JB REDESENHAR              ; ainda nao andou o suficiente
    MOV estadoPulo, 3          ; comeca a descer ja neste quadro

PULO_DESCENDO:
    ADD jipeY, VEL_PULO
    CMP jipeY, CHAO
    JB REDESENHAR
    MOV jipeY, CHAO            ; pousou
    MOV estadoPulo, 0

; ---------- Redesenha so se mudou ----------
REDESENHAR:
    MOV AX, jipeX
    CMP AX, oldX
    JNE PRECISA_REDESENHAR
    MOV AX, jipeY
    CMP AX, oldY
    JE  FIM_QUADRO

PRECISA_REDESENHAR:
    MOV CX, oldX               ; apaga na posicao antiga
    MOV DX, oldY
    MOV BX, 20
    MOV SI, 10
    CALL APAGAR_RETANGULO
    CALL DESENHAR_JIPE         ; desenha na nova

FIM_QUADRO:
    CALL ATUALIZAR_TIROS
    CALL ATUALIZAR_NAVES
    CALL ATUALIZAR_BOMBAS      ; disparos das naves
    CALL ATUALIZAR_TEMPO
    CMP vidas, 0
    JNE TEM_VIDA
    JMP GAME_OVER              ; sem vidas
TEM_VIDA:
    CMP tempoRestante, 0
    JNE CONTINUA_JOGO
    JMP GAME_OVER
CONTINUA_JOGO:
    JMP LOOP_JOGO
    
GAME_OVER:
    ; fundo preto atras do texto
    MOV CX, 112
    MOV DX, 92
    MOV BX, 96
    MOV SI, 16
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    ; texto vermelho centralizado (coluna 15, linha 12)
    MOV BL, 0Ch
    MOV DH, 12
    MOV DL, 15
    MOV SI, OFFSET msgGameOver
    CALL IMPRIMIR_TEXTO_COR
    
    MOV BL, 0Ch
    MOV DH, 12
    MOV DL, 15
    MOV SI, OFFSET msgGameOver
    CALL IMPRIMIR_TEXTO_COR

    CALL DESENHAR_SCORE_FINAL  ; <-- nova linha

    ; descarta teclas apertadas durante o jogo
GO_LIMPA_TECLADO:
    MOV AH, 01h
    INT 16h
    JZ GO_ESPERA
    XOR AH, AH
    INT 16h
    JMP GO_LIMPA_TECLADO

GO_ESPERA:
    XOR AH, AH                 ; espera uma tecla
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
    PUSH DX
    PUSH ES
    PUSH DI
    PUSH SI

    MOV SI, AX
    MOV AX, 0A000h
    MOV ES, AX

    MOV AX, DX
    MOV BX, 320
    MUL BX
    MOV DI, AX
    ADD DI, CX

    MOV AX, SI
    MOV ES:[DI], AL

    POP SI
    POP DI
    POP ES
    POP DX
    POP BX
    POP AX
    RET
PLOT_PIXEL ENDP

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
    PUSH CX         ; Salva o CX (quantidade) na pilha

    CALL POSICIONAR_CURSOR

    POP CX          ; Recupera o CX com a quantidade correta para a INT 10h
    PUSH CX         ; Guarda novamente para restaurar no final

    MOV AH, 09h
    MOV BH, 0
    INT 10h

    POP CX          ; Limpa a pilha
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

    MOV DH, 15
    MOV DL, 14
    MOV AL, 218
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 15
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 15
    MOV DL, 25
    MOV AL, 191
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 16
    MOV DL, 14
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 16
    MOV DL, 17
    MOV SI, OFFSET jogarTxt
    CALL IMPRIMIR_TEXTO_COR

    MOV DH, 16
    MOV DL, 25
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 17
    MOV DL, 14
    MOV AL, 192
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 17
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 17
    MOV DL, 25
    MOV AL, 217
    CALL DESENHAR_CARACTERE_COR


    ; ---------------- CAIXA SAIR ----------------
    MOV BL, 0Fh              ; Branco por padrao
    CMP selecao, 1
    JNE SAIR_COR_OK
    MOV BL, 0Ch              ; Vermelho claro se selecionado

SAIR_COR_OK:

    MOV DH, 18
    MOV DL, 14
    MOV AL, 218
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 18
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 18
    MOV DL, 25
    MOV AL, 191
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 19
    MOV DL, 14
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 19
    MOV DL, 17
    MOV SI, OFFSET sairTxt
    CALL IMPRIMIR_TEXTO_COR

    MOV DH, 19
    MOV DL, 25
    MOV AL, 179
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 20
    MOV DL, 14
    MOV AL, 192
    CALL DESENHAR_CARACTERE_COR

    MOV DH, 20
    MOV DL, 15
    MOV AL, 196
    MOV CX, 10
    CALL DESENHAR_LINHA_HORIZ_COR

    MOV DH, 20
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

    MOV CX, animX
    ADD CX, 30
    MOV DX, 180
    MOV BX, 10
    MOV SI, 6

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

    ; Desenha Nave (Ciano)
    MOV CX, animX
    ADD CX, 30
    MOV DX, 180
    MOV BX, 10
    MOV SI, 6
    MOV AL, 0Bh

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

ANIMAR_ELEMENTOS ENDP

; ============================================================
; Rotina: DESENHAR_SPRITE
; Entrada: CX = X, DX = Y, BX = Largura, SI = Altura, DI = Offset do Mapa
; ============================================================
DESENHAR_SPRITE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

DESENHAR_LINHA_SPRITE:
    PUSH CX
    PUSH BX             ; Salva a largura inicial da linha

COLUNA_SPRITE:
    MOV AL, [DI]        ; L? a cor atual do pixel no mapa
    CMP AL, 7           ; Se for 7 (cinza de fundo), n?o desenha (transparente)
    JE PULAR_PIXEL_TRANSPARENTE
    CALL PLOT_PIXEL     ; Desenha o pixel na tela

PULAR_PIXEL_TRANSPARENTE:
    INC CX              ; Avan?a o pixel na tela (X)
    INC DI              ; Avan?a para o pr?ximo byte no mapa de dados
    DEC BX              ; Decrementa o contador de largura
    JNZ COLUNA_SPRITE

    POP BX              ; Recupera a largura original
    POP CX              ; Recupera o X inicial
    INC DX              ; Vai para a pr?xima linha na tela (Y)
    
    ; O DI j? avan?ou a largura exata da linha anterior, ent?o n?o precisa recalcular
    DEC SI              ; Decrementa o contador de altura
    JNZ DESENHAR_LINHA_SPRITE

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHAR_SPRITE ENDP

; ============================================================
; Rotina: DESENHAR_JIPE
; Desenha o jipe em (jipeX, jipeY)
; ============================================================
DESENHAR_JIPE PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CX, jipeX
    MOV DX, jipeY
    MOV BX, 20
    MOV SI, 10
    MOV DI, OFFSET jipe_map
    CALL DESENHAR_SPRITE

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
DESENHAR_JIPE ENDP

; ============================================================
; Rotina: APAGAR_JIPE
; Pinta de preto o retangulo 20x10 do jipe
; ============================================================
APAGAR_JIPE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV CX, jipeX
    MOV DX, jipeY
    MOV BX, 20
    MOV SI, 10
    CALL APAGAR_RETANGULO

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
APAGAR_JIPE ENDP

; ============================================================
; Rotina: APAGAR_RETANGULO
; Entrada: CX = X, DX = Y, BX = Largura, SI = Altura
; Pinta de preto (cor 0)
; ============================================================
APAGAR_RETANGULO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR AL, AL              ; cor preta

APAGAR_LINHA:
    PUSH CX
    PUSH BX

APAGAR_COLUNA:
    CALL PLOT_PIXEL
    INC CX
    DEC BX
    JNZ APAGAR_COLUNA

    POP BX
    POP CX
    INC DX
    DEC SI
    JNZ APAGAR_LINHA

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
APAGAR_RETANGULO ENDP

; ============================================================
; Rotina: ESPERA_VSYNC
; Aguarda o retrace vertical da VGA (porta 3DAh, bit 3)
; ============================================================
ESPERA_VSYNC PROC NEAR
    PUSH AX
    PUSH DX

    MOV DX, 3DAh
VS_FIM:
    IN AL, DX
    TEST AL, 08h
    JNZ VS_FIM              ; espera sair do retrace atual
VS_INICIO:
    IN AL, DX
    TEST AL, 08h
    JZ VS_INICIO            ; espera comecar o proximo

    POP DX
    POP AX
    RET
ESPERA_VSYNC ENDP

; ============================================================
; Rotina: LER_PIXEL
; Entrada: CX = X, DX = Y     Saida: AL = cor do pixel
; ============================================================
LER_PIXEL PROC NEAR
    PUSH BX
    PUSH DX
    PUSH ES
    PUSH DI

    MOV AX, 0A000h
    MOV ES, AX
    MOV AX, DX
    MOV BX, 320
    MUL BX
    MOV DI, AX
    ADD DI, CX
    MOV AL, ES:[DI]

    POP DI
    POP ES
    POP DX
    POP BX
    RET
LER_PIXEL ENDP

; ============================================================
; Rotina: EH_ROCHA   (CX = X, DX = Y)  ->  AL = 1 se for rocha (cor 6 ou 2)
; ============================================================
EH_ROCHA PROC NEAR
    CALL LER_PIXEL
    CMP AL, 6
    JE ER_SIM
    CMP AL, 2
    JE ER_SIM
    XOR AL, AL
    RET
ER_SIM:
    MOV AL, 1
    RET
EH_ROCHA ENDP

; ============================================================
; Rotina: EH_NAVE   (CX = X, DX = Y)  ->  AL = 1 se for nave (cor 0Bh, 0Ch ou 0Eh)
; ============================================================
EH_NAVE PROC NEAR
    CALL LER_PIXEL
    CMP AL, 0Bh
    JE EN_SIM
    CMP AL, 0Ch
    JE EN_SIM
    CMP AL, 0Eh
    JE EN_SIM
    XOR AL, AL
    RET
EN_SIM:
    MOV AL, 1
    RET
EH_NAVE ENDP

; ============================================================
; Rotina: PREENCHER_RETANGULO
; Entrada: CX = X, DX = Y, BX = Largura, SI = Altura, AL = Cor
; ============================================================
PREENCHER_RETANGULO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

PRE_LINHA:
    PUSH CX
    PUSH BX
PRE_COLUNA:
    CALL PLOT_PIXEL
    INC CX
    DEC BX
    JNZ PRE_COLUNA
    POP BX
    POP CX
    INC DX
    DEC SI
    JNZ PRE_LINHA

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PREENCHER_RETANGULO ENDP

; ============================================================
; Rotina: ATUALIZAR_TIROS
; Cria os tiros (se espaco foi apertado) e move os ativos
; ============================================================
ATUALIZAR_TIROS PROC NEAR
    PUSH AX

    CMP pedidoTiro, 0
    JE AT_MOVER
    MOV pedidoTiro, 0

    ; ---- canhao superior (sai do meio do jipe, por cima) ----
    CMP tiroSupAtivo, 0
    JNE AT_NOVO_FRENTE
    MOV AX, jipeX
    ADD AX, 9
    MOV tiroSupX, AX
    MOV AX, jipeY
    SUB AX, TIRO_SUP_ALT
    MOV tiroSupY, AX
    MOV tiroSupAtivo, 1

    ; ---- canhao frontal (sai da frente do jipe) ----
AT_NOVO_FRENTE:
    CMP tiroFrAtivo, 0
    JNE AT_MOVER
    MOV AX, jipeX
    ADD AX, 20
    MOV tiroFrX, AX
    MOV AX, jipeY
    ADD AX, 3
    MOV tiroFrY, AX
    MOV tiroFrDist, 0
    MOV tiroFrAtivo, 1

AT_MOVER:
    CMP tiroSupAtivo, 0
    JE AT_FRENTE
    CALL MOVER_TIRO_SUP
AT_FRENTE:
    CMP tiroFrAtivo, 0
    JE AT_FIM
    CALL MOVER_TIRO_FRENTE
AT_FIM:
    POP AX
    RET
ATUALIZAR_TIROS ENDP

; ============================================================
; Rotina: MOVER_TIRO_SUP
; Sobe ate acertar uma nave ou chegar na linha LIMITE_SUP
; ============================================================
MOVER_TIRO_SUP PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; apaga na posicao atual
    MOV CX, tiroSupX
    MOV DX, tiroSupY
    MOV BX, 2
    MOV SI, TIRO_SUP_ALT
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    MOV BX, VEL_TIRO_SUP        ; passos restantes neste quadro
MTS_PASSO:
    CMP tiroSupY, LIMITE_SUP
    JBE MTS_DESATIVA            ; chegou na linha 15

    MOV CX, tiroSupX            ; olha a linha logo acima (2 pixels)
    MOV DX, tiroSupY
    DEC DX
    CALL EH_NAVE
    CMP AL, 1
    JE MTS_ACERTOU
    INC CX
    CALL EH_NAVE
    CMP AL, 1
    JE MTS_ACERTOU

    DEC tiroSupY
    DEC BX
    JNZ MTS_PASSO

    ; ainda esta voando: desenha na nova posicao
    MOV CX, tiroSupX
    MOV DX, tiroSupY
    MOV BX, 2
    MOV SI, TIRO_SUP_ALT
    MOV AL, COR_TIRO_SUP
    CALL PREENCHER_RETANGULO
    JMP MTS_FIM

MTS_ACERTOU:
    CALL DESTRUIR_NAVE_EM      ; apaga a nave que contem o pixel (CX, DX)
MTS_DESATIVA:
    MOV tiroSupAtivo, 0
MTS_FIM:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MOVER_TIRO_SUP ENDP

; ============================================================
; Rotina: MOVER_TIRO_FRENTE
; Anda para a direita ate 50 px ou ate bater em uma rocha
; ============================================================
MOVER_TIRO_FRENTE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; apaga na posicao atual (4x2)
    MOV CX, tiroFrX
    MOV DX, tiroFrY
    MOV BX, 4
    MOV SI, 2
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    MOV BX, VEL_TIRO_FRENTE
MTF_PASSO:
    CMP tiroFrDist, ALCANCE_FRENTE
    JAE MTF_DESATIVA            ; percorreu 50 px

    MOV CX, tiroFrX             ; olha a coluna logo a frente (2 pixels)
    ADD CX, 4
    MOV DX, tiroFrY
    CALL EH_ROCHA
    CMP AL, 1
    JE MTF_ACERTOU
    INC DX
    CALL EH_ROCHA
    CMP AL, 1
    JE MTF_ACERTOU

    INC tiroFrX
    INC tiroFrDist
    DEC BX
    JNZ MTF_PASSO

    ; ainda esta voando: desenha
    MOV CX, tiroFrX
    MOV DX, tiroFrY
    MOV BX, 4
    MOV SI, 2
    MOV AL, COR_TIRO_FRENTE
    CALL PREENCHER_RETANGULO
    JMP MTF_FIM

MTF_ACERTOU:
    ; AQUI entra a destruicao da rocha atingida
MTF_DESATIVA:
    MOV tiroFrAtivo, 0
MTF_FIM:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MOVER_TIRO_FRENTE ENDP

; ============================================================
; Rotina: ATUALIZAR_TEMPO
; A cada 18 ticks da BIOS (~1 s) diminui tempoRestante
; ============================================================
ATUALIZAR_TEMPO PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX

    MOV AH, 00h
    INT 1Ah                    ; CX:DX = ticks
    MOV AX, DX
    SUB AX, ultimoTick
    CMP AX, 18
    JB ATE_FIM                 ; ainda nao passou 1 segundo

    ADD ultimoTick, 18
    CMP tempoRestante, 0
    JE ATE_FIM
    DEC tempoRestante
    CALL DESENHAR_TEMPO

ATE_FIM:
    POP DX
    POP CX
    POP AX
    RET
ATUALIZAR_TEMPO ENDP

; ============================================================
; Rotina: DESENHAR_TEMPO
; Escreve tempoRestante (2 digitos, vermelho) ao lado do relogio
; ============================================================
DESENHAR_TEMPO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; apaga os 2 digitos anteriores (16x8 px a partir de x=264)
    MOV CX, COL_TEMPO * 8
    XOR DX, DX
    MOV BX, 16
    MOV SI, 8
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    MOV AX, tempoRestante
    MOV CL, 10
    DIV CL                     ; AL = dezenas, AH = unidades
    MOV CH, AH                 ; guarda as unidades

    ADD AL, '0'
    MOV BL, 0Ch                ; vermelho
    MOV DH, 0
    MOV DL, COL_TEMPO
    CALL DESENHAR_CARACTERE_COR

    MOV AL, CH
    ADD AL, '0'
    MOV DL, COL_TEMPO + 1
    CALL DESENHAR_CARACTERE_COR

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHAR_TEMPO ENDP

; ============================================================
; Rotina: RANDOM
; Entrada: CX = limite (1..255)     Saida: AX = 0..CX-1
; ============================================================
RANDOM PROC NEAR
    PUSH BX
    PUSH DX

    MOV AX, semente
    MOV BX, 25173
    MUL BX
    ADD AX, 13849
    MOV semente, AX

    MOV AL, AH                 ; usa o byte alto (mais aleatorio)
    XOR AH, AH
    XOR DX, DX
    DIV CX
    MOV AX, DX

    POP DX
    POP BX
    RET
RANDOM ENDP

; ============================================================
; Rotina: DESENHAR_NAVE_IDX
; Entrada: BX = indice da nave (0, 2, 4)
; Desenha (apagarFlag = 0) ou apaga (apagarFlag = 1) a nave,
; com recorte nas bordas esquerda e direita da tela
; ============================================================
DESENHAR_NAVE_IDX PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CX, naveX[BX]
    MOV DX, naveY[BX]
    MOV SI, tipoGrupo
    MOV DI, tabNaves[SI]
    MOV SI, NAVE_H

DN_LINHA:
    PUSH CX
    MOV BX, NAVE_W
DN_COLUNA:
    MOV AL, [DI]
    CMP AL, 7                  ; transparente
    JE DN_PULA
    CMP CX, 320                ; fora da tela (negativo ou >= 320)
    JAE DN_PULA
    CMP apagarFlag, 0
    JE DN_PLOT
    XOR AL, AL                 ; apagando: pinta de preto
DN_PLOT:
    CALL PLOT_PIXEL
DN_PULA:
    INC CX
    INC DI
    DEC BX
    JNZ DN_COLUNA
    POP CX
    INC DX
    DEC SI
    JNZ DN_LINHA

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHAR_NAVE_IDX ENDP

; ============================================================
; Rotina: GERAR_GRUPO
; Cria 1 a 3 naves do mesmo tipo, com Y aleatorio entre
; NAVE_Y_MIN e NAVE_Y_MAX e distancia minima NAVE_DIST
; ============================================================
GERAR_GRUPO PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CX, 3                  ; tipo aleatorio (0..2)
    CALL RANDOM
    SHL AX, 1
    MOV tipoGrupo, AX

    MOV CX, 3                  ; quantidade aleatoria (1..3)
    CALL RANDOM
    INC AX
    MOV qtdGrupo, AX

    MOV yMinProx, NAVE_Y_MIN
    XOR SI, SI                 ; i = 0
    XOR BX, BX                 ; indice em bytes

GG_LOOP:
    ; max_y = NAVE_Y_MAX - NAVE_DIST * (naves que ainda faltam depois desta)
    MOV AX, qtdGrupo
    DEC AX
    SUB AX, SI
    MOV CX, NAVE_DIST
    MUL CX
    MOV CX, NAVE_Y_MAX
    SUB CX, AX
    SUB CX, yMinProx
    INC CX                     ; CX = quantidade de valores possiveis
    CALL RANDOM
    ADD AX, yMinProx

    MOV naveY[BX], AX
    MOV naveX[BX], 320         ; entra pela direita
    MOV naveAtiva[BX], 0       ; ainda nao esta na tela

    ADD AX, NAVE_DIST          ; a proxima precisa estar 30 px abaixo
    MOV yMinProx, AX

    MOV CX, 60                 ; primeiro disparo entre 40 e 99 quadros
    CALL RANDOM
    ADD AX, 40
    MOV naveTimer[BX], AX

    MOV AX, SI                 ; espera = i * ESPERA_NAVE + 1
    MOV CX, ESPERA_NAVE
    MUL CX
    INC AX
    MOV naveEspera[BX], AX

    ADD BX, 2
    INC SI
    CMP SI, qtdGrupo
    JB GG_LOOP

    ; ---- embaralha os Y (Fisher-Yates), mantendo os 30 px entre eles ----
    MOV SI, qtdGrupo
    DEC SI                     ; i = qtd - 1
GG_SORT:
    CMP SI, 0
    JE GG_FIM
    MOV CX, SI
    INC CX
    CALL RANDOM                ; AX = j (0..i)
    MOV BX, AX
    SHL BX, 1                  ; BX = j * 2
    MOV DI, SI
    SHL DI, 1                  ; DI = i * 2
    MOV AX, naveY[BX]
    XCHG AX, naveY[DI]
    MOV naveY[BX], AX
    DEC SI
    JMP GG_SORT

GG_FIM:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GERAR_GRUPO ENDP

; ============================================================
; Rotina: ATUALIZAR_NAVES
; Move as naves ativas e gera novo grupo quando nao sobrar nenhuma
; ============================================================
ATUALIZAR_NAVES PROC NEAR
    PUSH BX

    MOV navesVivas, 0
    XOR BX, BX

AN_LOOP:
    AN_LOOP:
    CMP naveAtiva[BX], 0
    JNE AN_ATIVA

    ; nave ainda esperando para entrar
    CMP naveEspera[BX], 0
    JE AN_PROX                 ; nao existe (destruida ou ja saiu)
    INC navesVivas             ; conta como viva: o proximo grupo espera
    DEC naveEspera[BX]
    JNZ AN_PROX
    MOV naveAtiva[BX], 1       ; chegou a hora: entra pela direita (X = 320)
    JMP AN_PROX

AN_ATIVA:
    MOV apagarFlag, 1          ; apaga na posicao antiga
    CALL DESENHAR_NAVE_IDX

    SUB naveX[BX], VEL_NAVE
    CMP naveX[BX], -NAVE_W     ; saiu totalmente pela esquerda?
    JLE AN_SAIU

    MOV apagarFlag, 0          ; desenha na nova
    CALL DESENHAR_NAVE_IDX
    INC navesVivas
    JMP AN_PROX

AN_SAIU:
    MOV naveAtiva[BX], 0

AN_PROX:
    ADD BX, 2
    CMP BX, MAX_NAVES * 2
    JB AN_LOOP

    CMP navesVivas, 0
    JNE AN_FIM
    CALL GERAR_GRUPO           ; grupo anterior acabou: gera o proximo
AN_FIM:
    POP BX
    RET
ATUALIZAR_NAVES ENDP

; ============================================================
; Rotina: DESTRUIR_NAVE_EM
; Entrada: CX = X, DX = Y de um pixel atingido
; Apaga e desativa a nave que contem esse pixel
; ============================================================
DESTRUIR_NAVE_EM PROC NEAR
    PUSH AX
    PUSH BX

    XOR BX, BX
DNE_LOOP:
    CMP naveAtiva[BX], 0
    JE DNE_PROX

    MOV AX, naveX[BX]
    CMP CX, AX
    JL DNE_PROX
    ADD AX, NAVE_W
    CMP CX, AX
    JGE DNE_PROX

    MOV AX, naveY[BX]
    CMP DX, AX
    JL DNE_PROX
    ADD AX, NAVE_H
    CMP DX, AX
    JGE DNE_PROX

    MOV apagarFlag, 1          ; acertou esta nave
    CALL DESENHAR_NAVE_IDX
    MOV naveAtiva[BX], 0
    ADD pontos, PONTOS_NAVE
    CALL DESENHAR_PONTOS
    JMP DNE_FIM

DNE_PROX:
    ADD BX, 2
    CMP BX, MAX_NAVES * 2
    JB DNE_LOOP

DNE_FIM:
    POP BX
    POP AX
    RET
DESTRUIR_NAVE_EM ENDP

; ============================================================
; Rotina: APAGAR_BOMBA   (CX = X, DX = Y)
; Apaga so os pixels da cor da bomba, sem estragar jipe ou naves
; ============================================================
APAGAR_BOMBA PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV SI, BOMBA_H
APB_LINHA:
    PUSH CX
    MOV BX, BOMBA_W
APB_COLUNA:
    CALL LER_PIXEL
    CMP AL, COR_BOMBA
    JNE APB_PULA
    XOR AL, AL
    CALL PLOT_PIXEL
APB_PULA:
    INC CX
    DEC BX
    JNZ APB_COLUNA
    POP CX
    INC DX
    DEC SI
    JNZ APB_LINHA

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
APAGAR_BOMBA ENDP

; ============================================================
; Rotina: PERDER_VIDA
; Tira uma vida e redesenha os coracoes do HUD
; ============================================================
PERDER_VIDA PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    CMP vidas, 0
    JE PV_FIM
    DEC vidas

    XOR CX, CX                 ; apaga a area dos coracoes (18x11)
    XOR DX, DX
    MOV BX, 18
    MOV SI, 11
    CALL APAGAR_RETANGULO

    CMP vidas, 0
    JE PV_FIM
    MOV DI, OFFSET vida1_map
    CMP vidas, 1
    JE PV_DESENHA
    MOV DI, OFFSET vida2_map   ; vidas = 2
PV_DESENHA:
    XOR CX, CX
    XOR DX, DX
    MOV BX, 18
    MOV SI, 11
    CALL DESENHAR_SPRITE

PV_FIM:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PERDER_VIDA ENDP

; ============================================================
; Rotina: ATUALIZAR_BOMBAS
; Para cada nave: conta o timer e dispara; move as bombas ativas
; ============================================================
ATUALIZAR_BOMBAS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR BX, BX

AB_LOOP:
    ; ---------- disparo ----------
    CMP naveAtiva[BX], 0
    JE AB_MOVER
    DEC naveTimer[BX]
    JNZ AB_MOVER

    MOV CX, 60                 ; reinicia o timer (40 a 99 quadros)
    CALL RANDOM
    ADD AX, 40
    MOV naveTimer[BX], AX

    CMP bombaAtiva[BX], 0      ; so uma bomba por nave
    JNE AB_MOVER
    CMP naveX[BX], 0           ; so atira se a nave estiver na tela
    JL AB_MOVER
    CMP naveX[BX], 300
    JG AB_MOVER

    MOV AX, naveX[BX]
    ADD AX, 6                  ; meio da nave
    MOV bombaX[BX], AX
    MOV AX, naveY[BX]
    ADD AX, 10                 ; logo abaixo do sprite visivel
    MOV bombaY[BX], AX
    MOV bombaAtiva[BX], 1

    ; ---------- movimento ----------
AB_MOVER:
    CMP bombaAtiva[BX], 0
    JE AB_PROX

    MOV CX, bombaX[BX]         ; apaga na posicao atual
    MOV DX, bombaY[BX]
    CALL APAGAR_BOMBA

    MOV SI, VEL_BOMBA
AB_PASSO:
    INC bombaY[BX]
    MOV AX, bombaY[BX]
    ADD AX, BOMBA_H            ; AX = linha logo abaixo da bomba
    CMP AX, SOLO
    JGE AB_SOLO                ; chegou no solo

    ; colisao com o jipe (retangulos 2x4 e 20x10)
    MOV CX, bombaX[BX]
    ADD CX, BOMBA_W
    CMP CX, jipeX
    JLE AB_LIVRE
    MOV CX, bombaX[BX]
    MOV DX, jipeX
    ADD DX, 20
    CMP CX, DX
    JGE AB_LIVRE
    CMP AX, jipeY
    JLE AB_LIVRE
    MOV AX, bombaY[BX]
    MOV DX, jipeY
    ADD DX, 10
    CMP AX, DX
    JGE AB_LIVRE
    JMP AB_ACERTOU

AB_LIVRE:
    DEC SI
    JNZ AB_PASSO

    ; ainda cai: desenha na nova posicao
    MOV CX, bombaX[BX]
    MOV DX, bombaY[BX]
    PUSH BX
    MOV BX, BOMBA_W
    MOV SI, BOMBA_H
    MOV AL, COR_BOMBA
    CALL PREENCHER_RETANGULO
    POP BX
    JMP AB_PROX

AB_ACERTOU:
    MOV bombaAtiva[BX], 0
    CALL PERDER_VIDA
    JMP AB_PROX

AB_SOLO:
    MOV bombaAtiva[BX], 0

AB_PROX:
    ADD BX, 2
    CMP BX, MAX_NAVES * 2
    JAE AB_FIM
    JMP AB_LOOP

AB_FIM:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ATUALIZAR_BOMBAS ENDP

; ============================================================
; Rotina: DESENHAR_PONTOS
; Escreve "pontos" com 5 digitos, em branco, no topo e centralizado
; ============================================================
DESENHAR_PONTOS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; apaga os 5 digitos anteriores (40x8 px)
    MOV CX, COL_PONTOS * 8
    XOR DX, DX
    MOV BX, 40
    MOV SI, 8
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    ; separa os digitos (o ultimo sai primeiro, por isso usa a pilha)
    MOV AX, pontos
    MOV BX, 10
    MOV CX, 5
DP_DIV:
    XOR DX, DX
    DIV BX                     ; DX = digito
    PUSH DX
    LOOP DP_DIV

    ; imprime do mais significativo ao menos
    MOV DH, 0                  ; linha 0
    MOV DL, COL_PONTOS
    MOV CX, 5
DP_PRINT:
    POP AX
    ADD AL, '0'
    MOV BL, 0Fh                ; branco
    CALL DESENHAR_CARACTERE_COR
    INC DL
    LOOP DP_PRINT

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHAR_PONTOS ENDP

; ============================================================
; Rotina: DESENHAR_SCORE_FINAL
; Escreve "SCORE: 00000" em branco, na linha 14, centralizado
; (12 caracteres = 96 px, de x=112 a x=207, centro exato em 160)
; ============================================================
DESENHAR_SCORE_FINAL PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; limpa a area do score (96x8 px na linha 14)
    MOV CX, 112
    MOV DX, 112
    MOV BX, 96
    MOV SI, 8
    XOR AL, AL
    CALL PREENCHER_RETANGULO

    ; rotulo "SCORE: "
    MOV BL, 0Fh                ; branco
    MOV DH, 14
    MOV DL, 14
    MOV SI, OFFSET msgScore
    CALL IMPRIMIR_TEXTO_COR

    ; separa os 5 digitos (o ultimo sai primeiro, por isso usa a pilha)
    MOV AX, pontos
    MOV BX, 10
    MOV CX, 5
DSF_DIV:
    XOR DX, DX
    DIV BX
    PUSH DX
    LOOP DSF_DIV

    ; imprime do mais significativo ao menos, apos o rotulo (coluna 21)
    MOV DH, 14
    MOV DL, 21
    MOV CX, 5
DSF_PRINT:
    POP AX
    ADD AL, '0'
    MOV BL, 0Fh                ; branco
    CALL DESENHAR_CARACTERE_COR
    INC DL
    LOOP DSF_PRINT

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DESENHAR_SCORE_FINAL ENDP

END MAIN