extensions [jesslogo pathdir]

globals [
  clock             ;; how many seconds the game has lasted so far
  game-started?     ;; initially false, becomes true when player first presses GO
  game-over?        ;; initially false, becomes true if the player loses
  Resultado
]

patches-own [opened]

breed [ grass-squares grass-square ]    ;; these are the green squares the player hasn't tested yet
breed [ mines mine ]             ;; the mines (initially invisible)
breed [ markers marker ]          ;; show where the player thinks mines are




;;;
;;;; setup everything
;;;;
to setup
  clear-all
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
  ask n-of mine-count patches [
    sprout-mines 1 [
      set color black
      hide-turtle
    ]
  ]
  reset-ticks
  show jesslogo:eval "(reset)"

  show "SetUp Done"
  let out jesslogo:eval (word "(assert (MAIN::minas " mine-count "))")
  set out jesslogo:eval (word "(assert (MAIN::mundo  (min-x " min-pxcor ")"
                                                    "(max-x " max-pxcor ")"
                                                    "(min-y " min-pycor ")"
                                                    "(max-y " max-pycor ")))")
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
    show xxxcor
    run xxxcor
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
                   [clica-relva show "RELVA"]
                   [clica-aberto show "Numero"]]]
 ;if count mines = count markers and all? markers [any? mines-here]
 ;    [set game-over? true]
 
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
               [show (word "BAD FLAG: " x "-" y) set game-over? true 
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


; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
20
90
730
597
12
8
28.0
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
6
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
426
12
500
57
NIL
clock
1
1
11

MONITOR
509
12
614
57
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
625
14
694
59
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
1
0.5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is game of strategy.  There are land mines hidden beneath the green landscape.  Your job is to locate all of the mines without exploding any of them.

## HOW IT WORKS

If you click on a patch of grass without a mine, a number appears. The number tells you how many adjacent mines there are.

If you click on a mine, the mine explodes, and you lose the game.

You win the game by uncovering every square that doesn't have a mine.

If you lose, the land turns red.  If you win, it turns blue.

## HOW TO USE IT

Press SETUP to set up the board, then press GO to play the game.

While GO is pressed, click on green squares to check them for mines.

To help you remember where where you think the mines are, you can mark a square by pointing at it and pressing the M key.  (Note the M in the corner of the MARK/UNMARK button.  If the M is grayed out, hide the command center.)

You can make the game easier or harder by adjusting the MINE-COUNT slider before pressing SETUP.

## THINGS TO NOTICE

Use the numbers to deduce where it is safe to click and where it isn't.

Can you always know where it is safe to click, or do you have to guess sometimes?

Note that when you click in an empty region, the model saves you time by automatically clearing all the surrounding empty cells for you.  This keeps the game from being tedious.

## THINGS TO TRY

Try to win the game as fast as possible.  Your time appears in the CLOCK monitor.

Try playing with a bigger or smaller board by editing the view and adjusting min-p(x/y)cor and max-p(x/y)cor.

## EXTENDING THE MODEL

Write out a file to disk containing the best times players have achieved so far for a given board size.  Update the file when someone beats a previous time.

Write a computer player that can play the game automatically.  What strategy should it use?

Modify the game to use a hexagonal grid instead of a square one.  (See Hex Cells Example, in Code Examples, to see how to make a hexagonal grid.)

## NETLOGO FEATURES

The `neighbors` primitive is used to find neighboring squares.

## RELATED MODELS

Some of the models in Cellular Automata section, under Computer Science, also have rules based on how many neighboring cells are occupied.

## CREDITS AND REFERENCES

According to http://en.wikipedia.org/wiki/Minesweeper_%28computer_game%29, Minesweeper was invented by Robert Donner in 1989.  A version of the game is included with the Windows operating system.

Landmines are a real problem that kills people every day. To learn more about the campaign to ban landmines, see http://www.icbl.org.


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (2005).  NetLogo Minesweeper model.  http://ccl.northwestern.edu/netlogo/models/Minesweeper.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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
