; Marek Spisak & Roman Sperka
; 2011
; Transaction Costs in Financial Market

patches-own [
  behavior                     ; fundamental = 0 / technical trader = 1
  indicator                    ; allows to count traders    
]
;------------------------------------------------------------------------------------

globals [
  log-price                    ; current price calculated
  last-price                   ; price in time t-1
  returns                      ; log price changes (percentage of current price)
  F                            ; fundamental value of the asset
  orders-by-technical-rules    ; orders triggered by technical trading rules
  orders-by-fundamental-rules  ; orders triggered by fundamental trading rules
  orders-by-technical-rules2   ; orders triggered by technical trading rules in previous run
  orders-by-fundamental-rules2 ; orders triggered by fundamental trading rules in previous run
  orders-by-technical-rules3   ; orders triggered by technical trading rules in pre-previous run
  orders-by-fundamental-rules3 ; orders triggered by fundamental trading rules in pre-previous run
  weight-technical-traders     ; weight of technical traders
  weight-fundamental-traders   ; weight of fundamental traders
  fitness-technical-rules      ; fitness (attractiveness) of technical trading rules
  fitness-fundamental-rules    ; fitness (attractiveness) of fundamental rules
  fitness-technical-rules2     ; fitness (attractiveness) of technical trading rules in previous run
  fitness-fundamental-rules2   ; fitness (attractiveness) of fundamental rules in previous run
  K                            ; number of technical traders
  K2                           ; number of technical traders in previous run
  N                            ; total number of traders 
  alpha                        ; random term to price calculation
  beta                         ; random term to technical-rule decision
  gamma                        ; random term to fundamental-rule decision
  agent2-behavior              ; behavior of the randomly selected agent  
  talks-done                   ; number of already finished agents discussions
  probab-change-tech-fund      ; probability that technical agent will change to fundamental
  probab-change-fund-tech      ; probability that fundamental agent will change to technical
  transition-prob-tech-plus    ; transition probability for technical grow
  transition-prob-tech-minus   ; transition probability for fundamental grow
  transition-prob              ; global transition probability
]
;------------------------------------------------------------------------------------

to setup 
    ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks ; = clear-all
    clear-all-plots 
    
    ; preparing traders
    ask patches 
    [
      set indicator 1
      set behavior (random-float 1)
      ifelse behavior < 0.5
      [
        set behavior 0
        set pcolor black
      ]
      [
        set behavior 1
        set pcolor yellow
      ]          
    ]

    ; setting the default values
    set log-price 0
    set last-price 0
    set returns 0
    set weight-technical-traders 0
    set weight-fundamental-traders 0
    set orders-by-technical-rules 0
    set orders-by-technical-rules2 0
    set orders-by-technical-rules3 0
    set orders-by-fundamental-rules 0
    set orders-by-fundamental-rules2 0
    set orders-by-fundamental-rules3 0
    set fitness-technical-rules 0
    set fitness-technical-rules2 0
    set fitness-fundamental-rules 0
    set fitness-fundamental-rules2 0
    set F 0
    set K2 0
    set N sum [indicator] of patches
    set K sum [indicator] of patches with [behavior = 1]
end
;------------------------------------------------------------------------------------

to go
  if ticks >= 5000 [stop]
  if ticks > 2 [agent-talk-and-decision]
  market-clearing
  tick
  do-plot
end 
;------------------------------------------------------------------------------------

; agents are going to decide
to agent-talk-and-decision 
  set talks-done 0
  
  while [talks-total >= talks-done]
  [  
    ; selecting first discussing agent (the one that may adopt his opinion)  
    ask patch random-xcor random-ycor
    [
      ;asking the second agent for behavior
      set agent2-behavior [behavior] of patch random-xcor random-ycor
      
      if behavior = 0 and not(agent2-behavior = behavior)
      [      
        if (fitness-technical-rules > fitness-fundamental-rules) and (transition-prob > minimal-transaction-prob)
        [
          set pcolor yellow
          set behavior 1
        ]    
      ]
      
      if behavior = 1 and not(agent2-behavior = behavior)
      [
        if (fitness-technical-rules < fitness-fundamental-rules) and (transition-prob > minimal-transaction-prob)
        [
          set pcolor black
          set behavior 0
        ]
      ]          
    ]
    set talks-done talks-done + 1
  ]
    
end
;------------------------------------------------------------------------------------

; Market clearing mechanism 
to market-clearing 
  set alpha random-normal 0 sigma-alfa
  set beta random-normal 0 sigma-beta
  set gamma random-normal 0 sigma-gamma
  
  ; calculating technical rules orders
  set orders-by-technical-rules3 orders-by-technical-rules2
  set orders-by-technical-rules2 orders-by-technical-rules
  set orders-by-technical-rules (b * (log-price - last-price) + beta)
   
  ; calculating fundamental rules orders
  set orders-by-fundamental-rules3 orders-by-fundamental-rules2
  set orders-by-fundamental-rules2 orders-by-fundamental-rules
  set orders-by-fundamental-rules (c * (F - log-price) + gamma)
  
  ; calculating weights
  set K2 K
  set K sum [indicator] of patches with [behavior = 1]
  set weight-technical-traders (K / N)
  set weight-fundamental-traders ((N - K) / N)
  
  ; price updates
  set last-price log-price
  set log-price (last-price + a * (orders-by-technical-rules * weight-technical-traders + orders-by-fundamental-rules * weight-fundamental-traders) + alpha) + transaction-costs-amount
  
  ifelse last-price = 0
  [set returns 0.0]
  [set returns (log-price - last-price)]
  
  ; fitness rules calculation
  set fitness-technical-rules2 fitness-technical-rules
  set fitness-fundamental-rules2 fitness-fundamental-rules
  set fitness-technical-rules (((exp log-price) - (exp last-price)) * orders-by-technical-rules3 + d * fitness-technical-rules2)
  set fitness-fundamental-rules (((exp log-price) - (exp last-price)) * orders-by-fundamental-rules3 + d * fitness-fundamental-rules2)
  
  ; probabilities that agents change their oppinion and use different rules
  ifelse (fitness-technical-rules > fitness-fundamental-rules)
  [
    set probab-change-fund-tech 0.5 + lambda
    set probab-change-tech-fund 0.5 - lambda
  ]
  [
    set probab-change-fund-tech 0.5 - lambda
    set probab-change-tech-fund 0.5 + lambda
  ]
   
  set transition-prob-tech-plus ((N - K2) / N) * (epsilon + probab-change-fund-tech * (K2 / (N - 1)))
  set transition-prob-tech-minus (K2 / N) * (epsilon + probab-change-tech-fund * ((N - K2) / (N - 1)))
  set transition-prob 1 - transition-prob-tech-plus - transition-prob-tech-minus  

end
;------------------------------------------------------------------------------------

; Presenting the results in plots
to do-plot
  set-current-plot "log-price"
  set-current-plot-pen "default"
  plot log-price
  set-current-plot "returns"
  set-current-plot-pen "default"
  plot returns
  set-current-plot "weights"
  set-current-plot-pen "default"
  plot weight-technical-traders
  
  set-current-plot "transition-prob-tech"
  set-current-plot-pen "transition-prob-tech-plus"
  plot transition-prob-tech-plus
  set-current-plot-pen "transition-prob-tech-minus"
  plot transition-prob-tech-minus
  set-current-plot-pen "transition-prob"
  plot transition-prob
  
end
;------------------------------------------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
922
52
1288
439
100
100
1.7711443
1
10
1
1
1
0
1
1
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
9
12
76
45
NIL
SETUP
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
87
13
150
46
NIL
GO
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
57
186
90
a
a
0
1
1
0.01
1
NIL
HORIZONTAL

SLIDER
15
97
187
130
b
b
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
14
136
186
169
c
c
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
13
216
185
249
epsilon
epsilon
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
14
176
186
209
d
d
0
1
0.95
0.01
1
NIL
HORIZONTAL

SLIDER
14
256
186
289
lambda
lambda
0
1
0.45
0.01
1
NIL
HORIZONTAL

SLIDER
14
295
186
328
sigma-alfa
sigma-alfa
0
1
0.0025
0.0001
1
NIL
HORIZONTAL

SLIDER
15
332
187
365
sigma-beta
sigma-beta
0
1
0.025
0.0001
1
NIL
HORIZONTAL

SLIDER
15
371
187
404
sigma-gamma
sigma-gamma
0
1
0.0025
0.0001
1
NIL
HORIZONTAL

PLOT
204
53
910
213
log-price
time
log price
0.0
5000.0
-0.5
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
204
224
911
389
returns
time
return
0.0
5000.0
-0.06
0.06
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
205
405
911
557
weights
time
weight
0.0
5000.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
16
412
188
445
talks-total
talks-total
1
1000
100
1
1
NIL
HORIZONTAL

PLOT
208
571
907
721
transition-prob-tech
NIL
NIL
0.0
5000.0
0.0
1.0
true
true
"" ""
PENS
"transition-prob-tech-plus" 1.0 0 -1184463 true "" ""
"transition-prob-tech-minus" 1.0 0 -16777216 true "" ""
"transition-prob" 1.0 0 -10899396 true "" ""

SLIDER
16
453
190
486
minimal-transaction-prob
minimal-transaction-prob
0
1
0.51
0.05
1
NIL
HORIZONTAL

SLIDER
12
493
45
729
transaction-costs-amount
transaction-costs-amount
0
0.1
0.0080
0.001
1
NIL
VERTICAL

@#$#@#$#@
## Transaction Costs in Financial Market

## WHAT IS IT?

Spišák, M. and Šperka, R. (2014): Transaction Costs in Financial Market. Netlogo v. 5.01 simulation.
 http://ccl.northwestern.edu/netlogo/models/community/Transaction%20Costs%20in%20Financial%20Market.nlogo

## HOW IT WORKS

The base model developed by Frank Westerhoff (Westerhoff, 2009) was chosen for the implementation. It is an agent-based model, which simulates the financial market. Two base types of traders are represented by agents:

* fundamental traders, whose reactions are based on fundamental analysis - they believe that asset prices in long term approximate their fundamental price - they buy assets when the price is under fundamental value  
* technical traders, who decide using technical analysis - prices tend to move in trends - by their extrapolating there comes the positive feedback, which can cause the instability

Price changes are reflecting current demand excess. This excess is expressing the orders amount submitted by technical and fundamental traders each turn and the rate between their orders evolves in a time. Agents regularly meet and they are discussing their trading performance. One agent can be persuaded by the other to change his trading method, if his rules relative success is less than the others one. Communication is direct talk one agent with other. Talking agents meets randomly - there is no special relationship between them. The success of rules is represented by current and passed myoptic profitability. It is very important to mention, that model assumes traders ability to define the fundamental value of assets and they are behave rationally.   
The price is reflecting the relation between assets that have been bought and sold in a turn and the price change caused by these orders. This can be formalized as a simple log-linear price impact function. 

P_(t+1)= P_t+a(W_t^C D_t^C+ W_t^F D_t^F )+ ?_t

Where a is positive price adjustment coefficient, D^C are orders generated by technical angents while D^Fare orders of fundamental ones. W^C and W^Fare weights of the agents using technical respective fundamental rules. They are reflecting current ratio between the technical and fudamental agents. ? brings the random term to Figure 1. It is an IID  normal random variable with mean zero and constant standard deviation ?^?.  
As was already said, technical analysis extrapolates price trends - when they go up (price is growing) agents buy the assets. So the formalization for technical order rules can be like this

D_t^C=b(P_t- P_(t-1) )+ ?_t

The parameter b is positive and presents agent sensitivity to price changes. The difference in brackets reflects the trend and ? is the random term - IID normal random variable with mean zero and constant standard deviation ?^?.  
Fundamental analysis permits the difference between price and fundamental value for short time only. In long run there is an aproximation of them. So if the price is below the fundamental value - the assets are bought and vice versa - orders according fundamentalists are formalized

D_t^F=c(F- P_t )+ ?_t

c is positive and presents agent sensitivity to reaction. F represents fundamental value - we keep as constant value to keep the implementation as simple as possible . ? is the random term - IID normal random variable with mean zero and constant standard deviation ?^?.  
If we say that N is the total number of agents and K is the number of technical traders, then we define the weight of technical traders

W_t^C= K_t/N

and the weight of fundamental traders

W_t^F=(N- K_t)/N

Two traders meet at each step and they are discussing about the success of their rules. If the second agent rules are more successful, the first one changes its behavior with a probability K. Probability of transition is defined as (1-?). Also there is a small probability ? that agent changes his mind independently. Transition probability is formalized as

K_(t-1)(t) {?(K_(t-1)+1  with probability   p_(t-1)^+= (N- K_(t-1))/N (?+(1-?)_(t-1)^(F?C)
    K_(t-1)/(N-1))@K_(t-1)-1  with probability   p_(t-1)^-=  ( K_(t-1))/N (?+(1-?)_(t-1)^(C?F)    (N- K_(t-1))/(N-1))@K_(t-1)          with probability   1+? p?_(t-1)^+- p_(t-1)^-                                                 )?

where the probability that fundamental agent becomes technical one is

(1-?)_(t-1)^(F?C)={?(0.5+? for A_t^C>A_t^F  @0.5-? otherwise
     )?

respective that technical agent becomes fundamental one is
   
(1-?)_(t-1)^(C?F)={?(0.5-? for A_t^C>A_t^F  @0.5+? otherwise
     )?

Success (fitness of the rule) is represented by past myoptic profitability of the rules that are formalized as  
A_t^C=(exp?[P_t ]-exp?[P_(t-1) ] ) D_(t-2)^C+dA_(t-1)^C

for the technical rules and  
A_t^F=(exp?[P_t ]-exp?[P_(t-1) ] ) D_(t-2)^F+dA_(t-1)^F

for the fundamental rules. Agents use most recent performance (at the end of  A_^C formula resp. A_^F) and also the orders submitted in period t-2 are executed at prices started in period t-1. In this way the myoptic profits are calculated. Agents have memory - which is represented by parameter d. Values are 0 ? d ? 1. If d = 0 then agent has no memory, much higher value is, much higher influence the myoptic profits have on the rule fitness. 

## EXTENDING THE MODEL WITH TRANSACTION COSTS

The aim of the model is to investigate the influence of the transaction costs on the market stability (which is measured by the price volatility - much more stable the market is, much less are price differences in a time). The entrance of transaction costs (TC) - e.g. as a tax will have direct impact on the asset price. The model was little changed to adopt also this aspect into price. So price is composed this way:

P_(t+1)= P_t+a(W_t^C D_t^C+ W_t^F D_t^F )+ ?_t+TC

Where TC is a value of the transaction costs, which is constant during all the simulation.

While the tax is out-of trade factor, all the agents will be affected in the same way. Generally there can be also different transaction costs than taxes - e.g. information obtaining costs.  
The TC increase has following results:  
* price increase will stimulate technical rules usage, it-s influence on expected future profit opportunities (as the fundamental value of asset) is irrelevant - they depend on the company state, rather than on transaction costs     
* in a short time, the price grow will attract technical traders, but after the realized profits will fall down and the fundamental traders will start to dominate, it will lead to market stabilization (price changes are falling - volatility of price is lower) 

## HOW TO USE IT

In the interface section set the values for the parameters, SETUP and RUN the model.

## THINGS TO NOTICE

The most important thing to notice is price and technical traders percent envolvement based on the enterd transaction costs amount.

## THINGS TO TRY

Try to set high and low tranaction costs to see the influence on the price and technical traders percent.

## CREDITS AND REFERENCES

This model was developed with the support by grant of Silesian University no. SGS/6/2013 "Advanced Modeling and Simulation of Economic Systems”.

This model was described and analysed in detail in these papers:

ŠPERKA, R., SPIŠÁK, M. Transaction Costs Influence on the Stability of Financial Market: Agent-based Simulation. Journal of Business Economics and Management, Taylor & Francis, London, United Kingdom, 2013. Volume 14, Supplement 1, pp. S1-S12, DOI: 10.3846/16111699.2012.701227. Print ISSN 1611-1699, Online ISSN 2029-4433. Available from: <http://www.tandfonline.com/doi/abs/10.3846/16111699.2012.701227#.Ur80j9LuLy0>.

 ŠPERKA, R., SPIŠÁK, M. Tobin Tax Introduction and Risk Analysis in the Java Simulation. In: Proc. 30th International Conference Mathematical Methods in Economics. Part II. Silesian University in Opava, Karvina, Czech Republic, 11.-13.9.2012, pp. 885-890, ISBN 978-80-7248-779-0. Available from: < http://mme2012.opf.slu.cz/proceedings/pdf/152_Sperka.pdf>.

SPIŠÁK, M., ŠPERKA, R. Financial Market Simulation Based on Intelligent Agents - Case Study. Journal of Applied Economic Sciences, Volume VI, Issue 3(17), Fall 2011, Spiru Haret University: Romania, ISSN 1843-6110, pp. 249-256. Available from: <http://www.jaes.reprograph.ro/articles/winter2011/JAES_Fall_2011_online.pdf>.
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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
