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
  "scr_ABM/edu/edu_NoS.nls"
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
  print " "
  print " "
  print["Setting up"]

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
  print "[Set up finished!]"

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
755
375
1488
1109
-1
-1
7.25
1
10
1
1
1
0
0
0
1
0
99
0
99
1
1
1
ticks
30.0

PLOT
1015
70
1270
295
Land use type fractions
Zeit [Jahre]
[% der Eigentumsfläche]
0.0
10.0
0.0
1.0
true
true
"" ""
PENS

BUTTON
85
605
285
691
Siedlung generieren!
NoS-setup\n
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
300
605
500
690
Simulation starten!
go\nNoS-do-plots\nupdate-highscore\nupdate-time\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1280
70
1535
295
Carbon storage in agricultural area
Zeit [Jahre]
[t / ha]
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

BUTTON
805
330
860
363
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
757
330
812
363
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
880
330
1107
363
Besitzverhältnisse anzeigen
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
1110
330
1337
363
Landnutzungsart anzeigen
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
780
310
917
328
Kartengröße
12
0.0
1

TEXTBOX
775
395
1035
490
 Ölpalme (oilpalm)
25
24.0
0

TEXTBOX
785
424
1035
484
Kautschuk (rubber) 
25
44.0
0

TEXTBOX
785
455
1035
485
Wald (forest) 
25
52.0
0

SLIDER
85
190
327
223
palm-oil-price
palm-oil-price
33
200
90.0
1
1
US-Dollar / t
HORIZONTAL

SLIDER
85
230
327
263
rubber-price
rubber-price
250
1600
1106.0
1
1
US-Dollar / t
HORIZONTAL

SWITCH
85
325
325
358
learning
learning
0
1
-1000

TEXTBOX
1235
10
1385
28
NIL
12
0.0
1

TEXTBOX
40
65
690
136
[1] Versuche, den Gesamtwert des Systems zu maximieren (siehe [4]), indem Du den Wohlstand erhöhst und die 'CO2-Schulden' verringerst!
20
53.0
1

TEXTBOX
95
610
245
628
1.
16
53.0
1

TEXTBOX
310
610
460
628
2.
16
53.0
1

TEXTBOX
365
890
635
936
Highscore = Höchster bisher erreichter Systemwert
12
0.0
1

SLIDER
85
450
325
483
CO2-price
CO2-price
0
200
17.0
1
1
US-Dollar / t
HORIZONTAL

TEXTBOX
365
810
620
841
Systemwert = Differenz zwischen Vermögen und 'CO2-Schulden'
12
0.0
1

PLOT
755
70
1010
295
Hectare wealth & CO2 debt
Zeit [Jahre]
[US-Dollar / ha]
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

MONITOR
85
790
355
855
Dein Systemwert [US-Dollar]
sum [h_wealth] of hhs / area_under_agriculture -  hectare-CO2-debt
0
1
16

MONITOR
85
870
355
935
Aktueller Highscore [US-Dollar]
hectare-highscore
0
1
16

BUTTON
85
945
250
978
Highscore zurücksetzen
set hectare-highscore 0
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
1045
70
1240
88
Anteile der Landnutzungsarten
12
0.0
0

TEXTBOX
1300
70
1520
88
Kohlenstoffspeicher in Agrarfläche
12
0.0
0

TEXTBOX
785
70
980
88
Vermögen und 'CO2-Schulden'
12
0.0
0

TEXTBOX
75
140
615
190
[a] Ändere den Marktpreis, den der*die Landwirt*in für den Verkauf einer Tonne Palmöl und Kautschuk erhält! 
16
53.0
1

TEXTBOX
75
275
620
315
[b] Lege fest, ob die Landwirt*innen ihre Anbaueffizienz verbessern können, indem sie von ihren Nachbarn lernen!
16
53.0
1

TEXTBOX
75
380
660
445
[c] Ändere den Preis für die CO2-Schulden, die sich aus der geringeren Kohlenstoffspeicherung auf landwirtschaftlichen Flächen im Vergleich zu Wäldern ergeben! 
16
53.0
1

TEXTBOX
340
445
635
516
- Indonesia = ~5 US-Dollar/t\n- Europe = ~80 US-Dollar/t\n- Tatsächliche Kosten = 200-3000 US-Dollar/t\n
12
0.0
1

TEXTBOX
50
540
690
590
[2] Sobald Du die oben genannten Einstellungen gewählt hast, klicke hier:\n
20
53.0
1

TEXTBOX
50
735
670
785
[4] Vergleiche deinen erreichten Systemwert mit dem Highscore!
20
53.0
1

TEXTBOX
750
20
1415
45
[3] Schaue Dir die zeitliche und räumliche Ausgabe an!
20
53.0
1

@#$#@#$#@
# TODO: Update

## Abstract of corresponding publication

Land-use changes have dramatically transformed tropical landscapes. We describe an
ecological-economic land-use change model for use as an integrated, exploratory tool to
analyze how tropical land-use change affects ecological and socio-economic functions.
The model analysis seeks to determine what kind of landscape mosaic can improve the
ensemble of ecosystem functioning, biodiversity and economic benefit based on the
synergies and trade-offs that we have to account for. More specifically (1) How do
specific ecosystem services, such as carbon storage, and economic benefits, such as
household consumption, relate to each other? (2) How do external factors such as
output prices of crops affect these relationships? (3) How do these relationships change
when productivity differentials between smallholder farmers and production inefficiency
are considered and when learning is incorporated?
We initialized the ecological-economic model with artificially generated land-use
maps, parameterized to our study region. The economic submodel simulates smallholder
land-use management decisions based on a profit maximization assumption. Each
household determines factor inputs for all household fields and decides about land-use
change based on available wealth. The ecological submodel includes a simple account of
carbon sequestration in above- and below-ground vegetation. We demonstrate model
capabilities with results on household consumption and carbon sequestration from
different output price and farming efficiency scenarios. The overall results reveal
complex interactions between the economic and ecological sphere, especially when
fluctuating prices and household heterogeneity are considered. These findings underline
the utility of exploratory tools, such as our ecological-economic model, that will advance
our understanding of the mechanisms underlying the trade-offs and synergies of
ecological and economic functions in tropical landscapes.


## Instructions to run the model

* Please see the readme file, distributed with this model for details on NetLogo installation and extensions!

* When the model is openend, it loads the default parameter settings that are located in the EFForTS-ABM Parameters Tab. Parameters can be changed there!

* To initialize the model press the "setup" Button on the main interface!

* Afterwards, the model can be run by pressing one of the go Buttons:
** "Go-loop" will run the model in a loop
** "Go-once" will run the model for one time step

## Instructions to reproduce model scenarios from the corresponding publication

Follow these instructions to reproduce the scenarios that have been used for the corresponding publication. The following scenarios are implemented:

* CO - Constant prices; all households are optimally efficient
* CI - Constant prices; households have crop-specific heterogenous farming inefficiencies
* CIL - Constant prices; households have crop-specific heterogenous farming inefficiencies; Households can improve these inefficiencies by learning
* HO - Historical price trends; all households are optimally efficient
* HI - Historical price trends; households have crop-specific heterogenous farming inefficiencies
* HIL - Historical price trends; households have crop-specific heterogenous farming inefficiencies; Households can improve these inefficiencies by learning

To run these scenarios:

* Open the model (load default parameters)
* select a scenario from the dropdown menu on the main interface
* press the "Go-scenario" button!
* WARNING: For each scenario 20 simulation replicates are calculated to capture stochastic variability. Dependend on your machine it may take up to 30 minutes to finish one complete scenario!
* After the simulation is finshed, the aggregated results are plotted on the main interface!


## Other Scenarios and things to try

* Explore the maps that are provided with the model (different number of households)



## CREDITS AND REFERENCES

Copyright 2017. Claudia Dislich, Elisabeth Hettig, Jan Salecker, Johannes Heinonen, Jann Lay, Katrin M. Meyer, Kerstin Wiegand, Suria Tarigan. All rights reserved.

This work is licensed under a Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.

http://creativecommons.org/licenses/by-nc-nd/4.0/

Contact jsaleck(at)gwdg.de for license related questions.



## CHANGELOG

### v_1.0 - Published version:

This model is attached as supplementary material to the following publication:

Dislich C, Hettig E, Salecker J, Heinonen J, Lay J, Meyer KM, et al. (2018) Land-use change in oil palm dominated tropical landscapes—An agent-based model to explore ecological and socio-economic trade-offs. PLoS ONE 13(1): e0190506. https://doi.org/10.1371/journal.pone.0190506


### v_1.0.1b - Development version

* EFForTS-ABM and EFForTS-LGraf have been updated to NetLogo v6.0.2

Feature changes:

* Consolidation: Fields of bankrupt households are not removed anymore. Instead a pool of interested households is created (partly from already existing households - consolidation, partly from newly initialized households - immigrants). Ownership of these fields is gained by the household with the highest expected netcashflow for these fields

* Soical option matrix: Can be set with the parameter land-use-options. Social options matrix is created by using information from within the social network of the agent. First it is checked how many households converted to each landuse-type. If not at least one household converted to a specific landuse-type such conversion is only done under a certain proability (interface)


### v_2.0 - ModularExtension

* Landuses/Management: A big part of model parameters is now set within landuse parameter files in the subfolder "par_ABM". Defining new landuses and management options is now very easy. 1. Create a new subfolder in "par_ABM" (e.g. "rice") 2. Create a main parameterfile, just as the one for oilpalm and rubber. 3. Create at least one management parameter file. 4. Create the needed functions and define them correctly in the parameter files (e.g. one needs functions for carbon, yield, invest, labor and tinput - predefined functions for oilpalm, rubber and junglerubber are located in the subfile util_lut_functions.nls)
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

house2
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120
Line -16777216 false 45 285 45 120
Line -16777216 false 45 285 255 285
Line -16777216 false 255 285 255 120
Line -16777216 false 15 120 285 120
Line -16777216 false 15 120 150 15
Line -16777216 false 285 120 150 15

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
<experiments>
  <experiment name="nils_test1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup-with-external-maps</setup>
    <go>go-biodiversity</go>
    <timeLimit steps="1"/>
    <metric>count turtles</metric>
    <metric>area_under_agriculture</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;constant_prices&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="js_2016_sc12" repetitions="20" runMetricsEveryStep="true">
    <setup>setup-with-external-maps</setup>
    <go>step</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>pcount_op</metric>
    <metric>pcount_rm</metric>
    <metric>pcount_ra</metric>
    <metric>pcount_fo</metric>
    <metric>oilpalm_carbon</metric>
    <metric>rubberagro_carbon</metric>
    <metric>rubbermono_carbon</metric>
    <metric>big_plantation_carbon</metric>
    <metric>forest_carbon</metric>
    <metric>oilpalm_total_carbon</metric>
    <metric>rubber_total_carbon</metric>
    <metric>area_under_agriculture</metric>
    <metric>op_price</metric>
    <metric>rubber_price</metric>
    <metric>mean [h_wealth] of turtles</metric>
    <metric>standard-deviation [h_wealth] of turtles</metric>
    <metric>mean [h_consumption] of turtles</metric>
    <metric>standard-deviation [h_consumption] of turtles</metric>
    <metric>mean [h_fixconsumption] of turtles</metric>
    <metric>standard-deviation [h_fixconsumption] of turtles</metric>
    <metric>mean [h_varconsumption] of turtles</metric>
    <metric>standard-deviation [h_varconsumption] of turtles</metric>
    <metric>mean [h_netcashflow] of turtles</metric>
    <metric>standard-deviation [h_netcashflow] of turtles</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <metric>yield_op_all_hh_mean</metric>
    <metric>yield_rm_all_hh_mean</metric>
    <metric>yield_gap_op_all_hh_mean</metric>
    <metric>yield_gap_rm_all_hh_mean</metric>
    <enumeratedValueSet variable="price-fluctuation-%">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="same-wealth">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setlanduse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-alpha">
      <value value="3.168"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;constant_prices&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-alpha">
      <value value="3.445"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogenous-hhs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="palm-oil-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rubber-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-mu">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-lambda">
      <value value="0.093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-lambda">
      <value value="0.069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="js_2016_sc13" repetitions="20" runMetricsEveryStep="true">
    <setup>setup-with-external-maps
export-inefficiency-distribution</setup>
    <go>step</go>
    <final>export-inefficiency-distribution</final>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>pcount_op</metric>
    <metric>pcount_rm</metric>
    <metric>pcount_ra</metric>
    <metric>pcount_fo</metric>
    <metric>oilpalm_carbon</metric>
    <metric>rubberagro_carbon</metric>
    <metric>rubbermono_carbon</metric>
    <metric>big_plantation_carbon</metric>
    <metric>forest_carbon</metric>
    <metric>oilpalm_total_carbon</metric>
    <metric>rubber_total_carbon</metric>
    <metric>area_under_agriculture</metric>
    <metric>op_price</metric>
    <metric>rubber_price</metric>
    <metric>mean [h_wealth] of turtles</metric>
    <metric>standard-deviation [h_wealth] of turtles</metric>
    <metric>mean [h_consumption] of turtles</metric>
    <metric>standard-deviation [h_consumption] of turtles</metric>
    <metric>mean [h_fixconsumption] of turtles</metric>
    <metric>standard-deviation [h_fixconsumption] of turtles</metric>
    <metric>mean [h_varconsumption] of turtles</metric>
    <metric>standard-deviation [h_varconsumption] of turtles</metric>
    <metric>mean [h_netcashflow] of turtles</metric>
    <metric>standard-deviation [h_netcashflow] of turtles</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <metric>yield_op_all_hh_mean</metric>
    <metric>yield_rm_all_hh_mean</metric>
    <metric>yield_gap_op_all_hh_mean</metric>
    <metric>yield_gap_rm_all_hh_mean</metric>
    <enumeratedValueSet variable="price-fluctuation-%">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="same-wealth">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setlanduse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-alpha">
      <value value="3.168"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;constant_prices&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-alpha">
      <value value="3.445"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogenous-hhs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="palm-oil-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rubber-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-mu">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-lambda">
      <value value="0.093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-lambda">
      <value value="0.069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="js_2016_sc21" repetitions="20" runMetricsEveryStep="true">
    <setup>setup-with-external-maps</setup>
    <go>step</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>pcount_op</metric>
    <metric>pcount_rm</metric>
    <metric>pcount_ra</metric>
    <metric>pcount_fo</metric>
    <metric>oilpalm_carbon</metric>
    <metric>rubberagro_carbon</metric>
    <metric>rubbermono_carbon</metric>
    <metric>big_plantation_carbon</metric>
    <metric>forest_carbon</metric>
    <metric>oilpalm_total_carbon</metric>
    <metric>rubber_total_carbon</metric>
    <metric>area_under_agriculture</metric>
    <metric>op_price</metric>
    <metric>rubber_price</metric>
    <metric>mean [h_wealth] of turtles</metric>
    <metric>standard-deviation [h_wealth] of turtles</metric>
    <metric>mean [h_consumption] of turtles</metric>
    <metric>standard-deviation [h_consumption] of turtles</metric>
    <metric>mean [h_fixconsumption] of turtles</metric>
    <metric>standard-deviation [h_fixconsumption] of turtles</metric>
    <metric>mean [h_varconsumption] of turtles</metric>
    <metric>standard-deviation [h_varconsumption] of turtles</metric>
    <metric>mean [h_netcashflow] of turtles</metric>
    <metric>standard-deviation [h_netcashflow] of turtles</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <metric>yield_op_all_hh_mean</metric>
    <metric>yield_rm_all_hh_mean</metric>
    <metric>yield_gap_op_all_hh_mean</metric>
    <metric>yield_gap_rm_all_hh_mean</metric>
    <enumeratedValueSet variable="price-fluctuation-%">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="same-wealth">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setlanduse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-alpha">
      <value value="3.168"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;historical_trends&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-alpha">
      <value value="3.445"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogenous-hhs?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="palm-oil-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rubber-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-mu">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-lambda">
      <value value="0.093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-lambda">
      <value value="0.069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="js_2016_sc22" repetitions="20" runMetricsEveryStep="true">
    <setup>setup-with-external-maps</setup>
    <go>step</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>pcount_op</metric>
    <metric>pcount_rm</metric>
    <metric>pcount_ra</metric>
    <metric>pcount_fo</metric>
    <metric>oilpalm_carbon</metric>
    <metric>rubberagro_carbon</metric>
    <metric>rubbermono_carbon</metric>
    <metric>big_plantation_carbon</metric>
    <metric>forest_carbon</metric>
    <metric>oilpalm_total_carbon</metric>
    <metric>rubber_total_carbon</metric>
    <metric>area_under_agriculture</metric>
    <metric>op_price</metric>
    <metric>rubber_price</metric>
    <metric>mean [h_wealth] of turtles</metric>
    <metric>standard-deviation [h_wealth] of turtles</metric>
    <metric>mean [h_consumption] of turtles</metric>
    <metric>standard-deviation [h_consumption] of turtles</metric>
    <metric>mean [h_fixconsumption] of turtles</metric>
    <metric>standard-deviation [h_fixconsumption] of turtles</metric>
    <metric>mean [h_varconsumption] of turtles</metric>
    <metric>standard-deviation [h_varconsumption] of turtles</metric>
    <metric>mean [h_netcashflow] of turtles</metric>
    <metric>standard-deviation [h_netcashflow] of turtles</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <metric>yield_op_all_hh_mean</metric>
    <metric>yield_rm_all_hh_mean</metric>
    <metric>yield_gap_op_all_hh_mean</metric>
    <metric>yield_gap_rm_all_hh_mean</metric>
    <enumeratedValueSet variable="price-fluctuation-%">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="same-wealth">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setlanduse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-alpha">
      <value value="3.168"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;historical_trends&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-alpha">
      <value value="3.445"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogenous-hhs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="palm-oil-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rubber-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-mu">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-lambda">
      <value value="0.093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-lambda">
      <value value="0.069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="js_2016_sc23" repetitions="20" runMetricsEveryStep="true">
    <setup>setup-with-external-maps
export-inefficiency-distribution</setup>
    <go>step</go>
    <final>export-inefficiency-distribution</final>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>pcount_op</metric>
    <metric>pcount_rm</metric>
    <metric>pcount_ra</metric>
    <metric>pcount_fo</metric>
    <metric>oilpalm_carbon</metric>
    <metric>rubberagro_carbon</metric>
    <metric>rubbermono_carbon</metric>
    <metric>big_plantation_carbon</metric>
    <metric>forest_carbon</metric>
    <metric>oilpalm_total_carbon</metric>
    <metric>rubber_total_carbon</metric>
    <metric>area_under_agriculture</metric>
    <metric>op_price</metric>
    <metric>rubber_price</metric>
    <metric>mean [h_wealth] of turtles</metric>
    <metric>standard-deviation [h_wealth] of turtles</metric>
    <metric>mean [h_consumption] of turtles</metric>
    <metric>standard-deviation [h_consumption] of turtles</metric>
    <metric>mean [h_fixconsumption] of turtles</metric>
    <metric>standard-deviation [h_fixconsumption] of turtles</metric>
    <metric>mean [h_varconsumption] of turtles</metric>
    <metric>standard-deviation [h_varconsumption] of turtles</metric>
    <metric>mean [h_netcashflow] of turtles</metric>
    <metric>standard-deviation [h_netcashflow] of turtles</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <metric>yield_op_all_hh_mean</metric>
    <metric>yield_rm_all_hh_mean</metric>
    <metric>yield_gap_op_all_hh_mean</metric>
    <metric>yield_gap_rm_all_hh_mean</metric>
    <enumeratedValueSet variable="price-fluctuation-%">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;hundred-farmers3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="same-wealth">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-age">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setlanduse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-alpha">
      <value value="3.168"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;historical_trends&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-alpha">
      <value value="3.445"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogenous-hhs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="palm-oil-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rubber-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-mu">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-inefficiency-lambda">
      <value value="0.093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-inefficiency-lambda">
      <value value="0.069"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rb-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log-normal-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="gr-change-strategy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-0-specialize">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-3-price">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ecol_biodiv_interval">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-inaccessible-area-fraction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-s4.avoid">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-proportion-agricultural-area">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-3-color">
      <value value="84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-4-folder">
      <value value="&quot;NA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-road.algorithm">
      <value value="&quot;real.shapefile&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-inaccessible-area-mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-0-fraction">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-s1.homebase">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-fluctuation-percent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-perlin-persistence">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-vlg-area-distribution">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="heterogeneous-hhs?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="links-color">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rent_rate_capital_lend">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-perlin-octaves">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rnd-seed">
      <value value="1234"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-constant">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-occ-probability">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-s3.nearby">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-vlg-area-sd">
      <value value="56.73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-total-road-length">
      <value value="1099"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rent_rate_land">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-4-specialize">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-3-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-distribution">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-0-price-mu">
      <value value="1.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-wealth-distribution">
      <value value="&quot;constant&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="go-once-profiler?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-log-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historical_smoothing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-3-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-3-specialize">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="idrunnum">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biodiv_plants">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inacc-color">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-cell-length-meter">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;constant_prices&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-homebases?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-inaccessible-area-sd">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allow-fallow?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;five-farmers2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biodiv_invest_objective">
      <value value="&quot;general&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-machine?">
      <value value="&quot;local&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h_debt_years_max_bankrupt">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-2-folder">
      <value value="&quot;NA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-0-price-sd">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-4-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age_generation">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-land-use-types">
      <value value="&quot;household-level-specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-roads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh_age_lambda">
      <value value="0.31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-1-price-mu">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-area-distribution">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-type-sd">
      <value value="0.24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-height">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-3-folder">
      <value value="&quot;NA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-write-household-ids">
      <value value="&quot;only-first-households&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-1-price-sd">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land_price">
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-1-specialize">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-vlg-area-mean">
      <value value="68.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-width">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-dist-weight">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-4-color">
      <value value="134"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-0-color">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-number-of-villages">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="biodiv_birds">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-1-price">
      <value value="1100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="matrix-color">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-conversion-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-3-fraction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigrant_probability">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-2-price-mu">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-4-price">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SHOW-OUTPUT?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="road-color">
      <value value="9.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-color">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landmarket?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-2-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-setup-model">
      <value value="&quot;number-of-households&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-4-fraction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh_age_max">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-households-per-cell">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-road-map-id">
      <value value="&quot;jambi1&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-wealth-correction-factor">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-inaccessible-area-distribution">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-field-size-distribution">
      <value value="&quot;log-normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-cone-angle">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-area-sd-ha">
      <value value="0.92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-1-fraction">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-field-size-sd-ha">
      <value value="0.77"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh_age_min">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigrant-xp-bonus">
      <value value="&quot;[0 0]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-field-size-mean-ha">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-area-mean-ha">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-log-sd">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="external_income">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-rnd-seed">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-number-of-households">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-0-folder">
      <value value="&quot;oilpalm&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-default.maps">
      <value value="&quot;landuse-type&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-fill-up">
      <value value="&quot;LUT-1-fraction&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-inaccessible-area-location">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-1-folder">
      <value value="&quot;rubber&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigrant-wealth-factor">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh_age_alpha">
      <value value="14.24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land_price_increase">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-set-field-strategies-by-id?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-2-fraction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="buyer_pool_n">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="takeover_prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-LUT-2-specialize">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-4-price-sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-hh-type-mean">
      <value value="0.56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sim-time">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-1-color">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rent_rate_capital_borrow">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-min-dist-roads">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-2-price">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-s2.fields">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-0-price">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LUT-2-color">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-field-strategies-id">
      <value value="7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="nils_test2" repetitions="1" runMetricsEveryStep="true">
    <setup>test-invest</setup>
    <timeLimit steps="1"/>
    <metric>count turtles</metric>
    <metric>area_under_agriculture</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <enumeratedValueSet variable="which-machine?">
      <value value="&quot;local-linux&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="which-map">
      <value value="&quot;one-farmer-one-field&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-use-change-decision">
      <value value="&quot;only-one-field-per-year&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_base">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-spillover?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price_scenario">
      <value value="&quot;constant_prices&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-hh-network">
      <value value="&quot;hh-nw-kernel-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-wealth">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_wealth">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproducable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption_frac_cash">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-horizon">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="discount-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param1">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-view?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hh-nw-param2">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-hh-data-to-file?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="write-maps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spillover-share">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="nils_test_reduced" repetitions="1" runMetricsEveryStep="true">
    <setup>test-invest</setup>
    <timeLimit steps="1"/>
    <metric>count turtles</metric>
    <metric>area_under_agriculture</metric>
    <metric>min_hh_consumption</metric>
    <metric>max_hh_consumption</metric>
    <enumeratedValueSet variable="which-machine?">
      <value value="&quot;local-linux&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
