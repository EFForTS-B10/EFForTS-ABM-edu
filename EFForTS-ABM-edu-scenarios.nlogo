;############################################################################################################
;#  ________  ________  ________               _________   ______            _       ______   ____    ____  #
;# |_   __  ||_   __  ||_   __  |             |  _   _  |.' ____ \          / \     |_   _ \ |_   \  /   _| #
;#   | |_ \_|  | |_ \_|  | |_ \_|.--.   _ .--.|_/ | | \_|| (___ \_|______  / _ \      | |_) |  |   \/   |   #
;#   |  _| _   |  _|     |  _| / .'`\ \[ `/'`\]   | |     _.____`.|______|/ ___ \     |  __'.  | |\  /| |   #
;#  _| |__/ | _| |_     _| |_  | \__. | | |      _| |_   | \____) |     _/ /   \ \_  _| |__) |_| |_\/_| |_  #
;# |________||_____|   |_____|  '.__.' [___]    |_____|   \______.'    |____| |____||_______/|_____||_____| #
;#                                                                                                          #
;############################################################################################################

; Additional code files included in this NetLogo model (accessable via the "Includes" dropdown menu)
__includes [
  "scr_ABM/input_maps.nls" "scr_ABM/input_prices.nls"
  "scr_ABM/output.nls"
  "scr_ABM/initialization.nls"
  "scr_ABM/econ_capitalstock.nls" "scr_ABM/econ_invest.nls" "scr_ABM/econ_costs.nls" "scr_ABM/econ_consumption.nls" "scr_ABM/econ_production.nls" "scr_ABM/econ_cashflow.nls" "scr_ABM/econ_decision.nls" "scr_ABM/econ_optionmatrix.nls" "scr_ABM/econ_socialnw.nls" "scr_ABM/econ_factorinputs.nls"
  "scr_ABM/ecol_carbon.nls"
  "scr_ABM/util_lut_functions.nls" "scr_ABM/util_paramfiles.nls" "scr_ABM/util_reporter.nls"

  ; source files for education versions:
  "scr_ABM/edu/edu_scenarios.nls"
  "scr_ABM/edu/parameters_tab.nls"
]


; Extensions used in this NetLogo model:
;print["loading extensions"]
extensions [gis matrix nw ls csv]
;print["finished loading extensions"]

breed[luts a-lut] ; land use types
breed[hhs hh] ; households

; Define global variables/parameters:
globals
[
  LUT-ids
  LUT-ids-manage
  LUT-fractions          ; List to store the fractions of each landuse

  ;constants
  simulation_year        ; current year of the simulation
  rand-seed              ; random seed of the simulation. is stored in a text file inthe output folder (random_seed.txt)
  patch_size             ; size of patches in ha (0.25)
  landscape_size         ; size of landscape in ha
  area_under_agriculture ; size of area under agriculture in ha
  ineff_precision        ; number of digits for household inefficiencies
  carbon_forest          ; carbon storage in forest [t / ha]

  ;variables
  carbon
  prices-matrix          ; historical oil palm and rubber selling prices (for several years - currently past 10 years)
  prices

  ; Map parameters:
  road-file          ; Current road file
  envelope           ; GIS envelope of the road file
  x-extent           ; x extent of the map
  y-extent           ; y extent of the map
  number-of-cells-x  ; number of cells in x direction
  number-of-cells-y  ; number of cells in y direction

  ; Household variables:
  min_hh_consumption         ; minimum level of consumption of all households in one year
  max_hh_consumption         ; maximum level of consumption of all households in one year
  mean_hh_consumption        ; mean level of consumption of all households in one year

]

; Define patch properties:
patches-own
[
  p_landuse                ; patch land-use value as input from land-use map
  p_landuse_previous
  p_management             ; current management id
  p_road                   ; 0 if patch is not road, 1, if patch is road
  p_age                    ; age of a patch since last LUC
  p_fieldsize              ; number of patches belonging to this field
  p_carbon                 ; carbon storage of patch
  p_owner                  ; number of the turtle that owns this patch; -1 means no owner
  p_homebase               ; number of the turtle that has this cell as homebase
  p_production             ; yield in Mg per patch (for oil palm fresh fruit bunches, for rubber rubber)
  p_id                     ; patch identity, all cells that belong to the same patch (i.e. connected cells of the same crop, the same age, the same owner) have the same p_id
  p_labor                  ; labor invested in this cell in one year. output of production and land-use change decision, needed for calculating production
  p_tinput                 ; technical input invested in this cell in one year. output of production and land-use change decision, needed for calculating production
  p_capitalstock           ; captial stock of this cell, i.e. value of plantation
  p_capitalstock_previous  ; capital stock of this cell in the previous timestep
  p_invest                 ; investment costs of this cell
  p_actual_production      ; actual production of this cell
  p_optimal_production     ; optimal production of this cell

  ;; Variables used by biodiv_birds_mahnken module:
  p_beetlesRichness
  p_antsRichness
  p_canopy
  p_luDiversity
  p_bird_richness

  ;; Variables used by biodiv_plants_invest modules:
  p_landuse_invest         ; patch land use and land cover (LULC) integer, converted from p_landuse for generation of maps
 ; p_impact-value
  p_impact-location        ; location of corresponding impacts; TRUE means impact located on patch FALSE means no impact located
  p_habitat_quality        ; variable for storing habitat quality

]

luts-own
[
  l_lut_id
  l_landuse
  l_inefficiency_alpha
  l_inefficiency_lambda
  l_depriciation_rate_young
  l_depriciation_rate_old
  l_depriciation_rate_switch
  l_max_age
  l_yield_function
  l_carbon_function
  l_prices
  l_mng_ids
  l_mng_management
  l_mng_labor_function
  l_mng_tinput_function
  l_mng_price_tinput
  l_mng_invest_function
  l_mng_wages
  l_mng_yield_factor
  l_mng_optimal_capitalstock
  l_mng_external_income_factor
]


; Define agent properties:
hhs-own
[
  h_homebase          ; location of the household homebase
  h_id                ; household identification number
  h_age               ; household age
  h_area              ; actual number of patches that belong to the household
  h_patches           ; agentset of patches beloning to the household
  h_field_id_list     ; list of field_ids that belong to the household
  h_wealth_previous   ; wealth of the previeous year
  h_wealth            ; wealth of the household. This is the maximum sum available for investments in land-use
  h_debts             ; whenever the household wealth falls below the minimum wealth the household takes up debts wich are accumulated here
  h_capitalstock      ; capital of the household fixed in plantations (sum of p_capitalstock); resale value of capital stock embodied in household patches
  h_exincome          ; exogenous income (eg. NGOs, remittances)
  h_netcashflow       ; net cash flow from all household cells in one year
  h_netcashflow_exp   ; predicted netcashflow for the best affordable option
  h_consumption       ; consumption of household (welfare)
  h_fixconsumption    ; fix part of the household consumption, constant + fraction of household wealth
  h_varconsumption    ; variable part of consumption, fraction of net cash flow from this year
  h_cost_investment   ; investment costs of this year
  h_cost_labor        ; labor costs of  this year
  h_cost_tinput       ; technical input costs of this year
  h_cost_capital      ; capital costs of this year
  h_cost_land         ; land costs (for rent) of this year
  h_revenue           ; revenue of the hosehold in one year
  h_production        ; production of each landuse
  h_debt_years        ; consecutive years where household has debts > 0
  h_inefficiencies    ; inefficiency factors [0,1]
  h_inefficiencies_temp ; inefficiency factors [0,1]
  h_connected_hhs             ; other households that are connected within the social network
  h_immigrant?
  h_management       ; List with management ids for each LUT
  h_landmarket
  h_land-use-change
]



;###################################################################################
; ╔═╗┌─┐┌┬┐┬ ┬┌─┐
; ╚═╗├┤  │ │ │├─┘
; ╚═╝└─┘ ┴ └─┘┴
;###################################################################################

; Main Setup procedure:
To setup-with-external-maps
  print["setting up"]

  ; control randomness
  set-rand-seed

  ; Read land-use parameter from files in "par_ABM" folder
  read-lut-parameters

  ; Set further global constants/parameters
  set_global_constants

  ; Generate a list with optimal capitalstocks:
  calculate-optimal-capitalstocks-all-landuses

  ; Import maps
  import-maps

  ; Init hh management:
  init-household-management

  ; Initialize fields
  assign-patch-age
  init-patch-capital-stock
  init-investment-costs
  calculate_patch_carbon

  ; Initialize households
  init-household-area
  init-household-wealth
  init-household-inefficiencies
  init-log-land-use-change-list
  assign-hh-capital-stock

  ; Calculate outputs and set remaining constants
  calculate_LUT_fractions
  set_remaining_constants
  calculated-field-sizes
  calculate-area-under-agriculture
  calculate_LUT_carbon

  ; Initialize social networks
  setup_social_networks

  ; Paint world:
  paint-landuse

  ; Reset the time counter
  reset-ticks

End

;###################################################################################
; ╔═╗┌─┐
; ║ ╦│ │
; ╚═╝└─┘
;###################################################################################

To go

  ;; Check if screenshot output should be created
  store-screenshot

  ; If learning is turned on, start the learning procedure
  if(learning-spillover? = TRUE) [learning-spillover]

  ; Check if households have to many consecutive years with debts and freeze them if needed
  sort-out-bankrupt-turtles

  ; Update agricultaral area (if households have been frozen)
  calculate-area-under-agriculture

  ;update capital stocks before land-use change decision
  update-capital-stocks-cell

  ;Main Decision procedure - Forecast land use options and implement option with highest netcashflow
  perform-lu-and-production-decision

  ;Update the mean consumption of households
  aggregate-household-consumption

  ; Update carbon levels in patches
  calculate_patch_carbon
  calculate_LUT_carbon

  ; Load new prices for next timestep
  update_prices

  ; Calculate current Land-use type fractions
  calculate_LUT_fractions

  paint

  ; If hh-data should be written to an output file, do it
  if (write-hh-data-to-file?) [write-hh-data-to-file]

   ; If moutput maps should be written, do it now
  if (write-maps?) [write-map-files]
end

to update-time
  ; Increase time step
  set simulation_year (simulation_year + 1)
  tick

  ;; Check stop condition:
  if (ticks = sim-time) [
    print "Simulation finished!" stop]
End
@#$#@#$#@
GRAPHICS-WINDOW
854
106
1762
1015
-1
-1
9.0
1
10
1
1
1
0
1
1
1
0
99
0
99
0
0
1
ticks
30.0

SLIDER
33
57
172
90
n-replicates
n-replicates
1
20
1.0
1
1
NIL
HORIZONTAL

BUTTON
33
153
170
186
Run scenario!
run-scenario
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
32
96
170
141
scenarios
scenarios
"CO" "CI" "CIL" "HO" "HI" "HIL"
2

TEXTBOX
189
70
718
183
C0 : Constant prices (C), No inefficiencies (0)\nCI  : Constant prices (C), Heterogeneous inefficient households and no learning (I)\nCIL :  Constant prices (C), Heterogeneous inefficient households and learning (IL)\n\nH0 : Historical trends (H), No inefficiencies (0)\nHI : Historical trends (H), Heterogeneous inefficient households and no learning (I)\nHIL : Historical trends (H), Heterogeneous inefficient households and learning (IL)
12
0.0
1

PLOT
23
215
413
468
Land use type fractions
Time [years]
[% of owned cells]
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
421
216
833
468
Carbon storage in agricultural area
Time [years]
[t/ha]
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
23
476
414
738
Household consumption
Time [years]
[US-Dollar / Household]
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
24
744
416
935
Historic Prices
Time [years]
US-Dollar / t
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

TEXTBOX
16
11
320
58
EFForTS-ABM
36
64.0
1

PLOT
421
477
833
738
Yield Gap
Time [years]
[% of optimal yield]
0.0
10.0
0.0
60.0
true
true
"" ""
PENS

TEXTBOX
853
82
1064
112
1 cell = 50 m x 50 m = 0.25 ha
12
0.0
1

TEXTBOX
901
23
939
41
Zoom
12
0.0
1

BUTTON
854
41
917
74
+
set-patch-size round (patch-size + 2)
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
917
41
980
74
-
set-patch-size round (patch-size - 2)
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
1070
65
1280
98
paint fields by ownership
paint-fields-by-households
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
1070
32
1280
65
paint cells by land use type
paint
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
207
185
357
203
NIL
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
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
