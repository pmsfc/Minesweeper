extensions [jesslogo pathdir]

globals [
  clock             ;; how many seconds the game has lasted so far
  game-started?     ;; initially false, becomes true when player first presses GO
  game-over?        ;; initially false, becomes true if the player loses
  Resultado
  the-mines
  na-run
  score
  num-derrotas
  score-medio
]

patches-own [opened]

breed [ grass-squares grass-square ]    ;; these are the green squares the player hasn't tested yet
breed [ mines mine ]             ;; the mines (initially invisible)
breed [ markers marker ]          ;; show where the player thinks mines are




;;;
;;;; setup everything
;;;;
to setup
  ;ca
  set score 0
  reset-ticks
  reset-perspective
  ask turtles [die]
  ask patches [set opened 0 set plabel ""]
  set clock 0
  set Resultado "Espera..."
  set game-started? false
  set game-over? false
  set-default-shape grass-squares "grass patch"
  set-default-shape mines "bomb"
  set-default-shape markers "flag"
  ask patches [
    sprout-grass-squares 1 [ set color green ]
    set pcolor gray
  ]
  ;; make the number of mines determined by the mine-count slider
  ifelse manual-mining? 
    [manual-mines]
    [setup-mines]
  show jesslogo:eval "(reset)"
  show "SetUp Done"
  let out jesslogo:eval (word "(assert (MAIN::minas " mine-count "))")
  set out jesslogo:eval (word "(assert (MAIN::mundo  (min-x " min-pxcor ")"
                                                    "(max-x " max-pxcor ")"
                                                    "(min-y " min-pycor ")"
                                                    "(max-y " max-pycor ")))")
end

;;;; colocacao automatica de minas
to setup-mines
    ask n-of mine-count patches [
    sprout-mines 1 [
      set color black
      hide-turtle
    ]
  ]
end

;;; colocacao manual de minas
to manual-mines
   run  word "set the-mines " my-mines 
   set mine-count length the-mines
  foreach the-mines [create-mine ?]
end

to create-mine [coords]
  ask patch first coords item 1 coords [
     sprout-mines 1 [
      set color black
      hide-turtle
    ]]
end

;;; Load the player
;;;
to load

  show jesslogo:eval (trans (word "(batch \"" pathdir:get-current pathdir:get-separator "minesweeperX.jess\")"))
  show jesslogo:eval (trans (word "(batch \"" pathdir:get-current pathdir:get-separator "mineX-" jog ".jess\")"))
  show jesslogo:eval "(set-current-module MAIN)"

end

;;; load the green cells as jess facts
;;;
to carrega-verdes
  ask grass-squares [insere-verde]

end

;;
;; assert a fact with the coordinates
;;
to insere-verde
  let out jesslogo:eval (word "(assert (celula (x " xcor ") (y " ycor ")))")
end

;; Load the most recent uncovered cells
;;
to carrega-abertas
  ask patches with [not any? grass-squares-here and opened = ticks - 1] [insere-aberto]

end

;;
;; assert a fact with coordinates and the number of adjacent mines
;;
to insere-aberto
  let out jesslogo:eval (word "(assert (aberta (x " pxcor ") (y " pycor ") (valor "  meu-valor  ")))")
end

;;
;; if there is no label then 0 else report myu label
;;
to-report meu-valor
  if plabel = "" [report "0"]
  report plabel
end

;;
;;  please play
;;
to go
  if resultado != "Espera..." [stop]
  reset-perspective
  if not game-started? [
    ;; this must be the first time through GO, so start the clock
    reset-timer
    set game-started? true
  ]
  set clock timer

  
    let focus jesslogo:eval "(focus MINE)"
    let rrun jesslogo:eval "(run)"
    let xxxcor read-from-string jesslogo:eval "?*x*"
    ;show xxxcor
    run xxxcor
    ;let yyycor read-from-string jesslogo:eval "?*y*"
    ;show yyycor

 
  tick
   if game-over? [
    derrota
    calc-score stop
  ]
     if all? grass-squares [any? mines-here] or
     all? mines [any? markers-here][
    ;; you win!!!
    ask mines [ show-turtle ]
    ask patches [ set pcolor blue ]
    set Resultado "Vitoria"
    calc-score stop]
 carrega-abertas
end



to derrota
   ;   ask markers with [any? mines-here] [ die ]
    ask markers [ show-turtle  set color yellow ]
    ask mines [ show-turtle ]
    ask patches [ set pcolor red ]
    set Resultado "Derrota"
end

to clic [x y flags]
  mark flags

  if (x != 1000 and y != 1000)
    [ask patch x y [watch-me display wait atraso ifelse any? grass-squares-here
                   [clica-relva ];show "RELVA"]
                   [clica-aberto]]] ;show "Numero"]]]
  
end



;;
;; select a covered cel
;;
to clica-relva
      ifelse any? mines-here
        [ set game-over? true ask mines-here [set color violet set size 1.5]]   ;; aiggghhhh!
        [ clear ]                 ;; whew!
end


;;
;; SELECT a uncovered cell
;;
to clica-aberto
 ask neighbors with [not any? markers-here] [clica-relva]
end

to clear  ;; patch procedure
  ask grass-squares-here [ die ]
  ask markers-here [ die ]
  let total count neighbors with [any? mines-here]
  set opened ticks
  ifelse total > 0
    [ set plabel word total "  " ]
    ;; if none of our neighbors have mines on them, then they can
    ;; be cleared too, to save the user from extra clicking
    [ ask neighbors with [any? grass-squares-here]
      [ clear ] ]
end


to mark [flags]
    if not empty? flags
       [let x item 0 flags
         let y item 1 flags
         ask patch x y [
             if not any? markers-here [sprout-markers 1 [ set color red show-turtle]]
             if not any? mines-here
               [;show (word "BAD FLAG: " x "-" y) 
                 set game-over? true 
                ask grass-squares-here [die] set plabel "OH"]
        ]
       mark butfirst butfirst flags]
end

to-report trans [str]
  ifelse empty? str
    [report ""]
    [report word (tt first str) (trans (butfirst str))]
end

to-report tt [Elem]
  ifelse Elem = "\\"
    [report "\\\\"]
    [report Elem]
end

to clica [x y Bands]
  if resultado != "Espera..." [stop]
  reset-perspective
  if not game-started? [
    ;; this must be the first time through GO, so start the clock
    reset-timer
    set game-started? true
  ]
  set clock timer

  
   clic x y Bands
    ;let yyycor read-from-string jesslogo:eval "?*y*"
    ;show yyycor

 
  tick
   if game-over? [
    derrota
    stop
  ]
     if all? grass-squares [any? mines-here] or
     all? mines [any? markers-here][
    ;; you win!!!
    ask mines [ show-turtle ]
    ask patches [ set pcolor blue ]
    set Resultado "Vitoria"
    stop]
 carrega-abertas
end


to valid-game
  setup
  gogo
  if Resultado = "Derrota" and ticks <= derrota-acima-de
    [valid-game]
end

to gogo
    if resultado != "Espera..." [ stop]
  reset-perspective
  if not game-started? [
    ;; this must be the first time through GO, so start the clock
    reset-timer
    set game-started? true
  ]
  set clock timer

  
    let focus jesslogo:eval "(focus MINE)"
    let rrun jesslogo:eval "(run)"
    let xxxcor read-from-string jesslogo:eval "?*x*"
    ;show xxxcor
    run xxxcor
    ;let yyycor read-from-string jesslogo:eval "?*y*"
    ;show yyycor

 
  tick
   if game-over? [
    derrota
    calc-score stop
  ]
     if all? grass-squares [any? mines-here] or
     all? mines [any? markers-here][
    ;; you win!!!
    ask mines [ show-turtle ]
    ask patches [ set pcolor blue ]
    set Resultado "Vitoria"
    calc-score stop]
 carrega-abertas
 gogo
end


to setup-n
  set na-run 0
  set num-derrotas 0
  set score-medio 0
end

to calc-score
  set score ticks
  if Resultado = "Derrota"
    [set score score + (count mines - count markers) * valor-mina-por-descobrir]     
end

to one-run
  valid-game
  set na-run na-run + 1
  if Resultado = "Derrota"
     [set num-derrotas num-derrotas + 1]
end

to n-runs
  setup-n
  repeat runs [one-run set score-medio score-medio + score]
  set score-medio score-medio / runs
end

; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
18
103
706
595
12
8
27.12
1
20
1
1
1
0
0
0
1
-12
12
-8
8
1
1
1
ticks
30.0

SLIDER
119
49
243
82
mine-count
mine-count
1
300
380
1
1
NIL
HORIZONTAL

BUTTON
190
11
246
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
251
11
306
44
play
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
442
23
516
68
NIL
clock
1
1
11

MONITOR
525
23
630
68
bandeiras
count markers
0
1
11

INPUTBOX
21
10
108
70
jog
0
1
0
String

BUTTON
116
10
179
43
NIL
load
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
251
47
306
80
step
go\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
641
25
710
70
NIL
Resultado
0
1
11

SLIDER
315
13
422
46
atraso
atraso
0
4
0
0.5
1
NIL
HORIZONTAL

SWITCH
311
52
434
85
manual-mining?
manual-mining?
0
1
-1000

INPUTBOX
5
600
1013
660
my-mines
[[1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4][1 1] [3 4] [5 6] [6 8] [4 4]]
1
0
String

SLIDER
752
248
924
281
runs
runs
1
100
100
1
1
NIL
HORIZONTAL

SLIDER
751
290
923
323
derrota-acima-de
derrota-acima-de
1
5
3
1
1
NIL
HORIZONTAL

MONITOR
754
334
811
379
NIL
na-run
0
1
11

MONITOR
824
334
912
379
NIL
num-derrotas
0
1
11

MONITOR
755
388
835
433
NIL
score-medio
2
1
11

BUTTON
793
453
886
486
NIL
N-runs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
757
174
912
234
valor-mina-por-descobrir
50
1
0
Number

MONITOR
719
27
776
72
NIL
score
0
1
11

@#$#@#$#@
## O QUE É?

Este é um jogo de estratégia. Existem minas escondidas npor detrás do mosaico do terreno relvado. A tarefa é localizar as minas sem as fazer explodir. O jogo é feito para que seja um programa a jogar, escrito na linguagem Jess.
Existe a extensão jesslogo que permite a ligação entre o Netlogo e o Jess.

Em cada jogada o programa toma a decisão onde colocar novas bandeiras, e que célula escolher para abrir ou para abrir as vizinhas encobertas que não tenham bandeira.

## QUANDO SE GANHA?

1. Colocam-se bandeiras em todas as casas com mina
2. Descobrem-se (abrem-se) todas as casas excepto as casas que contêm as minas


## QUANDO SE PERDE?
1. Se coloca uma bandeira numa casa sem mina
2. Quando se abre uma casa, acertando numa mina
3. Quando se selecciona uma casa já aberta e uma das suas 8 vizinhas não tem uma bandeira e tem uma mina. 

## OBJECTIVO

O primeiro objectivo é descobrir onde estão todas as minas e pretende-se minimizar o número de cliques necessários até o sucesso. Cada jogo vai ter um score e pretende-se minimizar o score ou no caso de haver um conjunto de jogos, pretende-se minimizar a pontuação média.


## SCORE

Em caso de vitória a pontuação é dada pelo

número de cliques (jogadas) até descobrir todas as bombas. 

e em caso de derrota

(num de minas - num de bandeiras) * valor-mina-por-descobrir + jogadas

Na derrota pretende-se penalizar aquele que colocou menos bandeiras ou/e faça mais  cliques par ao mesmo número de bombas por colocar, perdendo mais tarde.

Note que os seguintes elementos são parâmetros ajustáveis no interface do programa

----valor-mina-por-descobrir


## COMO FUNCIONA

Se for clicado uma casa de relva (coberta ou fechada) sem mina, aparece um número a indicar quantas minas há nas células vizinhas. Note que quando se escolhe uma casa sem minas na vizinhança, todas as suas vizinhas são descobertas.

Se acertares numa mina o jogo acaba e perdes.

Se for escolhida uma casa já descoberta então as suas vizinhas ainda cobertas e sem bandeira são abertas. 

Se perderes o terreno torna-se vermelho, mas se ganhares fica azul.

## INTERFACE PARA UM JOGO

Vamos discutir todos os elementos do interface:

LOAD
Carrega os ficheiros Jess

JOG
Indica o ID do jogador. Se for ID=0 entao o ficheiro que se espera carregar será minesX-0.jess.

MINES-COUNT  
Número de minas que serão colocadas

MANUAL-MINING
Podemos deixar o programa colocar ao acaso as minas ou seleccionar os lugares onde estão as minas

MY-MINES
a lista com os pares de coordenadas das minas, a ser usado com o botão de manual-mining ligado (ON).

Exemplo:
[[1 2] [2 3] [3 3]] representa 3 minas nas casas (1,2), (2,3) e (3,3).

Para saber a posição de uma dada casa colocar o rato sobre ela e clicar com o botão direito.

SETUP
Botão que serve para inicializar um jogo

STEP
Modo passo a passo. permite fazer apenas uma jogada

PLAY (botão forever)
Executa o jogo até ao fim.

RESULTADO
Indica o resultado do jogo: Derrota, Vitpria, Em espera.

TICKS
Indica o número de jogadas ou cliques.

SCORE
Indica o score do jogo, só é actualizado no final.

CLOCK
Indica o tempo que durou o jogo. Não é muito relevante mas pode ajudar a detectar programas que são pouco eficientes ou que são muito eficientes.

ATRASO
O slider atraso permite-nos criar um delay em cada jogada para acompanharmos com cuidado a evolção do jogo.

BANDEIRAS
Indica o número de bandeiras colocadas.


## COMO EXECUTAR UM JOGO

Pressione LOAD para carregar os ficheiros Jess necessários

Pressione SETUP e depois PLAY ou STEP.


## INTERFACE PARA EXECUTAR VÁRIOS JOGOS

É possível executar vários jogos e obter a média dos scores.

RUNS
Número de jogos que queremos fazer.

N-RUNS
Botão para fazer uma série de jogos.

DERROTA-ACIMA-DE
Como se pode logo rebentar uma mina na primeira jogada ou nas N primeiras jogadas, define-se uma derrota como sendo sempre após um certo número de cliques expresso como parâmetro

VALOR-MINA-POR-DESCOBRIR
Penalização por cada mina não marcada com bandeira. Importante para cálculo do score numa derrota.

NA-RUN
Indica qual o jogo corrente.

NUM-DERROTAS
Indicador do número de derrotas

SCORE-MEDIO
Monitor para nos dar o score-médio dos vários jogos realizados. Só tem valor exacto no fim, vai somando, somando e no fim divide o total pelo número de jogos


## COMO EXECUTAR VÁRIOS JOGOS

Basta carregar no botão N-RUNS


## ESTRUTURAS DE DADOS DO JESS
O programa usa 5 estruturas de dados expressos em factos.

(minas 4)

Indica que há 4 minas.


(mundo (min-x -12) (max-x 12) (min-y -8) (max-y 8))

Indica os limites do terreno relvado.


(escolhe (x -6) (y 4)) 

A célula (-6,4) é seleccionada-clicada.

Para inserir o facto que indica qual a celula escolhida.
(escolhe (x 1000) (y 1000)) 

indica que nada é seleccionado.


(novas-bandeiras 2 3 5 6 7 8)

Indica que serão colocadas bandeiras nas células (2,3) (5,6) (7,8). 


Em cada jogada o programa Jess deve inserir um facto (escolhe...) e um facto (novas-bandeiras ...)


## CONSOLA JESS PARA DEBUGGING DO CÓDIGO JESS

Quando se abre o programa, abres-se automaticamente uma consola Jess interactiva que é o ambiente natural do Jess para fazer debuggind: permite ver os factos, ver a agenda, executar comandos e as regras.
Deve ser usada com o botão STEP.

Para usar em modo debugging deve-se começar por executar 

(focus MINE)

porque o Netlogo invoca o Jess fazendo (focus MINE) seguido de (run)

Depois pode-se fazer tudo o que o Jess permite.


## CRÉDITOS E REFERÊNCIAS

According to http://en.wikipedia.org/wiki/Minesweeper_%28computer_game%29, Minesweeper was invented by Robert Donner in 1989.  A version of the game is included with the Windows operating system.



## COPYRIGHT

Copyright 2016 Paulo Urbano.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bomb
false
0
Circle -7500403 true true 56 71 188
Rectangle -7500403 true true 120 60 180 90
Polygon -7500403 false true 150 75 148 57 141 52 133 38 136 27 145 22 165 22 184 23 210 28 221 32 239 37 249 40 264 43 264 46 258 45 248 43 239 39 229 36 210 31 192 28 180 26 172 25 154 27 140 27 137 29 137 36 149 45 151 51 150 57 154 65

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

grass patch
false
0
Rectangle -10899396 true false 0 0 300 300
Rectangle -16777216 true false 0 285 300 300
Rectangle -16777216 true false 285 0 300 330
Rectangle -1 true false 0 0 285 15
Rectangle -1 true false 0 0 15 285

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
setup
ask patch -5 0 [ clear ]
ask patch -9 -1 [ sprout-markers 1 [ set color black ] ]
ask patch -6 3 [ sprout-markers 1 [ set color black ] ]
ask patch -7 3 [ sprout-markers 1 [ set color black ] ]
ask patch -6 4 [ sprout-markers 1 [ set color black ] ]
ask patch -5 -3 [ sprout-markers 1 [ set color black ] ]
ask patch -6 -3 [ sprout-markers 1 [ set color black ] ]
ask patch -4 -3 [ sprout-markers 1 [ set color black ] ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
