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
  "scr_ABM/econ_capitalstock.nls" "scr_ABM/econ_invest.nls" "scr_ABM/econ_costs.nls" "scr_ABM/econ_consumption.nls" "scr_ABM/econ_production.nls" "scr_ABM/econ_cashflow.nls" "scr_ABM/econ_decision.nls" "scr_ABM/econ_optionmatrix.nls" "scr_ABM/econ_socialnw.nls" "scr_ABM/econ_factorinputs.nls" "scr_ABM/econ_landmarket.nls" "scr_ABM/econ_age.nls"
  "scr_ABM/ecol_carbon.nls" "scr_ABM/ecol_birds.nls" "scr_ABM/ecol_invest_plantdiv.nls" "scr_ABM/ecol_invest_plantdiv_SAR.nls"
  "scr_ABM/util_lut_functions.nls" "scr_ABM/util_gui_defaults.nls" "scr_ABM/util_testing.nls" "scr_ABM/util_paramfiles.nls" "scr_ABM/util_reporter.nls"
]

; Extensions used in this NetLogo model:
extensions [gis matrix nw ls profiler csv]

breed[luts a-lut]
breed[lms lm]
breed[hhs hh]

; Define global variables/parameters:
globals
[
  LUT-ids
  LUT-ids-manage
  LUT-fractions  ;; List to store the fractions of each landuse

  ;constants
  simulation_year        ; current year of the simulation
  rand-seed              ; random seed of the simulation. is stored in a text file inthe output folder (random_seed.txt)
  patch_size             ; size of patches in ha (0.25)
  landscape_size         ; size of landscape in ha
  area_under_agriculture ; size of area under agriculture in ha
  ineff_precision        ; number of digits for household inefficiencies

  ;variables
  carbon
  prices-matrix               ; historical oil palm and rubber selling prices (for several years - currently past 10 years)
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

  ; Landmarket variables:
  lm_new                    ; number of newly created landmarkets
  lm_seller_wealth_log      ; wealth of all agents who sold land on a landmarket auction
  lm_seller_area_log        ; area of all agents who sold land on a landmarket auction
  lm_seller_lut0_ineff_log  ; lut0 inefficiency of all agents who sold land on a landmarket auction
  lm_seller_lut1_ineff_log  ; lut1 inefficiency of all agents who sold land on a landmarket auction
  lm_buyer_wealth_log      ; wealth of all agents who bought land on a landmarket auction
  lm_buyer_area_log        ; area of all agents who bought land on a landmarket auction
  lm_buyer_lut0_ineff_log  ; lut0 inefficiency of all agents who bought land on a landmarket auction
  lm_buyer_lut1_ineff_log  ; lut1 inefficiency of all agents who bought land on a landmarket auction

  ; Testing biodiv models:
  bird_richness
  plantdiv_all_probs
  ws_list
  sar
  sar_t
  sar_t0
  sar_ratio
  trade-off-plot-xy

    ;; Edu version globals:
;  edu_carbon_baseline
;  edu_consumption_baseline
;  edu_biodiversity_baseline
  edu_carbon_scenario
  edu_consumption_scenario
  edu_biodiversity_scenario
  edu_carbon_p
  edu_consumption_p
  edu_biodiversity_p
  edu_index
  edu_index_total

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
  p_beetlesRichness
  p_antsRichness
  p_canopy
  p_luDiversity
  p_bird_richness

  ;; Testing invest plant model:
  p_MBVx
  p_MBV
  p_RMBV

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

lms-own
[
  lm_ticks
  ; Landmarket output:
  lm_seller_who
  lm_seller_area
  lm_seller_fields
  lm_seller_wealth
  lm_seller_lut0_ineff
  lm_seller_lut1_ineff
  lm_land_price
  lm_poolall_wealth
  lm_poolall_immigrant
  lm_poolpot_wealth
  lm_poolpot_immigrant
  lm_buyer_who
  lm_buyer_area
  lm_buyer_wealth
  lm_buyer_immigrant
  lm_buyer_lut0_ineff
  lm_buyer_lut1_ineff
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
  ca

  ; control randomness
  set-rand-seed

  ; Read land-use parameter from files in "par_ABM" folder
  read-lut-parameters

  ; Set global constants/parameters
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
  init-household-age
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

  ; Initialize plant biodiv invest module
  if (invest_plantdiv?) [init_invest_plantdiv]

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
  if(learning-spillover?) [learning-spillover]

  ; Check if households have to many consecutive years with debts and freeze them if needed
  sort-out-bankrupt-turtles
  landmarket-auction
  increase-hh-age

  ; Update agricultaral area (if households have been frozen)
  calculate-area-under-agriculture

  ; update capital stocks before land-use change decision
  update-capital-stocks-cell

  ; Main Decision procedure - Forecast land use options and implement option with highest netcashflow
  perform-lu-and-production-decision

  ; Update the mean consumption of households
  aggregate-household-consumption


  ; Update carbon levels in patches
  calculate_patch_carbon
  calculate_LUT_carbon
  if (invest_plantdiv?) [update_invest-Plantdiv]

  ; Load new prices for next timestep
  update_prices

  ; Calculate current Land-use type fractions
  calculate_LUT_fractions

  ; If activated, calculate bird richness:
  if (calc_bird_richness?) [calculate_patch_bird_richness]

  ; If show-output? is turned on, update plots and world output
  ifelse (show-output?)
  [
    display
    do-plots-and-output
  ]
  [
    no-display
  ]

  ; If hh-data should be written to an output file, do it
  if (write-hh-data-to-file?) [write-hh-data-to-file]

  ; Increase time step
  set simulation_year (simulation_year + 1)
  tick

  ; If moutput maps should be written, do it now
  if (write-maps?) [write-map-files]

  ;; Check stop condition:
  if (ticks = sim-time) [print "Simulation finished!" stop]

End

to go-profiler

  if (go-once-profiler?)
  [
    profiler:reset
    profiler:start
  ]

  go

  if (go-once-profiler?)
  [
    profiler:stop
    print profiler:report
  ]

end


;****************************************************************************
;****************************************************************************
;
;  EDUCATION VERSION 2.0
;
; How to:
;
; 1. press setup
; 2. choose seetings (prices etc) or press button "set-default"
; 3. run benchmark scenario
; 4. play with parameters and press run-experiment and try to increase score
; 5. investigate results

to edu-run-baseline

  setup-with-external-maps

  repeat sim-time [go]

  ;; Edu version globals:
  set edu_carbon_baseline ((lut0.carbon + lut1.carbon) / area_under_agriculture) * price-for-1t-carbon
  set edu_consumption_baseline hh.consumption.mean * price-for-1k-consumption
  set edu_biodiversity_baseline sar_ratio * price-for-1-promille-biodiversity

end

to edu-run-scenario

  setup-with-external-maps
  set edu_index []
  repeat sim-time
  [
    go
    set edu_index lput edu-calc-index edu_index
  ]

  ;; overall index:
  set edu_index_total mean edu_index
  print (word "Overall mean improvement: " edu_index_total)

end

to-report edu-calc-index

  set edu_carbon_scenario ((lut0.carbon + lut1.carbon) / area_under_agriculture) * price-for-1t-carbon
  set edu_consumption_scenario hh.consumption.mean * price-for-1k-consumption
  set edu_biodiversity_scenario sar_ratio * price-for-1-promille-biodiversity

  set edu_carbon_p ((edu_carbon_scenario - edu_carbon_baseline) / edu_carbon_baseline) * 100
  set edu_consumption_p ((edu_consumption_scenario - edu_consumption_baseline) / edu_consumption_baseline) * 100
  set edu_carbon_p ((edu_biodiversity_scenario - edu_biodiversity_baseline) / edu_biodiversity_baseline) * 100

  let edu_index_t mean (list edu_carbon_p edu_consumption_p edu_carbon_p)

  report edu_index_t

end

@#$#@#$#@
GRAPHICS-WINDOW
1315
135
2023
844
-1
-1
7.0
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
2530
545
2740
700
Prices
Year
NIL
0.0
10.0
0.0
12.0
true
false
"" ""
PENS

PLOT
2065
760
2320
980
Household wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"box" 1.0 0 -16777216 true "" ""
"median" 1.0 0 -5298144 true "" ""
"whisker.top" 1.0 0 -16777216 true "" ""
"whisker.bottom" 1.0 0 -16777216 true "" ""
"outlier" 1.0 2 -16777216 true "" ""

BUTTON
255
35
310
68
setup
setup-with-external-maps
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
310
35
365
68
Go - loop
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

BUTTON
365
35
420
68
Go - once
go-profiler
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
2295
545
2530
700
Carbon in agricultural area
Time [years]
Carbon [T/Ha]
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"op-carbon" 1.0 0 -3844592 true "" ""
"rb-carbon" 1.0 0 -4079321 true "" ""
"tot-carbon" 1.0 0 -16777216 true "" ""
"op-carbon-env-up" 1.0 2 -955883 true "" ""
"op-carbon-env-lo" 1.0 2 -955883 true "" ""
"rb-carbon-env-up" 1.0 2 -1184463 true "" ""
"rb-carbon-env-lo" 1.0 2 -1184463 true "" ""
"tot-carbon-env-up" 1.0 2 -7500403 true "" ""
"tot-carbon-env-lo" 1.0 2 -7500403 true "" ""

SWITCH
550
35
680
68
SHOW-OUTPUT?
SHOW-OUTPUT?
0
1
-1000

PLOT
2320
760
2575
980
Household consumption
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"box" 1.0 0 -16777216 true "" ""
"whisker.top" 1.0 0 -16777216 true "" ""
"whisker.bottom" 1.0 0 -16777216 true "" ""
"median" 1.0 0 -2674135 true "" ""
"outlier" 1.0 2 -16777216 true "" ""

TEXTBOX
2065
515
2325
536
== Landscape level output ==
17
105.0
1

TEXTBOX
1315
110
2030
128
== World output ================================================
17
105.0
1

TEXTBOX
255
10
560
28
== Model control ==============
17
105.0
1

TEXTBOX
15
10
245
56
EFForTS-ABM
38
55.0
1

TEXTBOX
15
105
160
125
== Parameters ==
17
105.0
1

SWITCH
335
435
475
468
landmarket?
landmarket?
0
1
-1000

TEXTBOX
10
130
60
148
Output
12
0.0
1

SWITCH
5
245
155
278
write-maps?
write-maps?
1
1
-1000

SWITCH
5
315
155
348
export-view?
export-view?
1
1
-1000

SWITCH
5
150
155
183
reproducable?
reproducable?
0
1
-1000

INPUTBOX
5
185
155
245
rnd-seed
12345.0
1
0
Number

SWITCH
5
280
155
313
write-hh-data-to-file?
write-hh-data-to-file?
1
1
-1000

SWITCH
5
385
155
418
show-roads?
show-roads?
0
1
-1000

SWITCH
5
350
155
383
show-homebases?
show-homebases?
0
1
-1000

TEXTBOX
10
425
160
443
Map & Landuse
12
0.0
1

CHOOSER
5
445
155
490
which-map
which-map
"one-farmer-one-field" "one-farmer" "five-farmers" "five-farmers2" "five-farmers3" "ten-farmers" "ten-farmers2" "twenty-farmers" "twenty-farmers2" "thirty-farmers2" "fifty-farmers" "fifty-farmers2" "fifty-farmers4" "fifty-farmers5" "hundred-farmers" "hundred-farmers2" "hundred-farmers3" "twohundred-farmers" "twohundred-farmers-big-plantations" "fourhundred-farmers" "landmarkets1" "EFForTS-LGraf"
14

CHOOSER
5
490
155
535
land-use-change-decision
land-use-change-decision
"only-one-field-per-year" "all-options" "social-options"
0

TEXTBOX
10
595
155
613
Prices
12
0.0
1

CHOOSER
5
615
160
660
price_scenario
price_scenario
"constant_prices" "variable_prices" "correlated_prices_1" "random_walk" "historical_trends" "production-related" "price_shock"
0

INPUTBOX
660
275
730
335
LUT-0-price
500.0
1
0
Number

INPUTBOX
660
335
730
395
LUT-1-price
1000.0
1
0
Number

TEXTBOX
325
130
475
148
Wealth
12
0.0
1

INPUTBOX
410
290
485
350
min-wealth
3000.0
1
0
Number

INPUTBOX
320
350
410
410
time-horizon
20.0
1
0
Number

INPUTBOX
410
350
485
410
discount-rate
0.1
1
0
Number

CHOOSER
320
150
485
195
initial-wealth-distribution
initial-wealth-distribution
"constant" "log-normal"
1

INPUTBOX
320
230
410
290
wealth-log-mean
7.0
1
0
Number

INPUTBOX
410
230
485
290
wealth-log-sd
1.0
1
0
Number

INPUTBOX
320
290
410
350
wealth-constant
10000.0
1
0
Number

TEXTBOX
170
375
250
393
Consumption
12
0.0
1

SWITCH
165
395
305
428
consumption-on?
consumption-on?
0
1
-1000

INPUTBOX
165
430
305
490
consumption_base
1000.0
1
0
Number

TEXTBOX
175
130
325
148
Inefficiency & Learning
12
0.0
1

SWITCH
170
150
305
183
heterogeneous-hhs?
heterogeneous-hhs?
0
1
-1000

SWITCH
170
185
305
218
learning-spillover?
learning-spillover?
0
1
-1000

CHOOSER
170
220
305
265
setup-hh-network
setup-hh-network
"hh-nw-none" "hh-nw-kernel" "hh-nw-kernel-distance" "hh-nw-n-nearest-neighbors" "hh-nw-distance"
4

TEXTBOX
165
595
275
613
Household Finances
12
0.0
1

INPUTBOX
165
615
230
675
land_price
750.0
1
0
Number

BUTTON
255
70
420
103
NIL
set-gui-parameters-to-default
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
25
790
1280
808
== EFForTS-LGraf Parameters ================================================================================================
17
15.0
1

TEXTBOX
25
820
120
838
Model Control
12
15.0
1

SWITCH
20
840
130
873
gr-reproducable?
gr-reproducable?
0
1
-1000

INPUTBOX
20
875
130
935
gr-rnd-seed
100.0
1
0
Number

INPUTBOX
20
935
75
995
gr-width
100.0
1
0
Number

INPUTBOX
75
935
130
995
gr-height
100.0
1
0
Number

INPUTBOX
20
995
130
1055
gr-cell-length-meter
50.0
1
0
Number

TEXTBOX
145
820
180
838
Road
12
15.0
1

CHOOSER
135
840
250
885
gr-road.algorithm
gr-road.algorithm
"artificial.graffe" "artificial.perlin" "real.shapefile"
2

INPUTBOX
135
885
250
945
gr-total-road-length
800.0
1
0
Number

TEXTBOX
420
820
485
838
Household
12
15.0
1

CHOOSER
415
840
595
885
gr-hh-area-distribution
gr-hh-area-distribution
"constant" "normal" "log-normal"
2

INPUTBOX
415
885
505
945
gr-hh-area-mean-ha
1.0
1
0
Number

INPUTBOX
505
885
595
945
gr-hh-area-sd-ha
0.92
1
0
Number

TEXTBOX
735
820
885
838
Inaccessible Areas
12
15.0
1

CHOOSER
730
840
870
885
gr-inaccessible-area-location
gr-inaccessible-area-location
"random" "road-connected"
0

CHOOSER
730
885
870
930
gr-inaccessible-area-distribution
gr-inaccessible-area-distribution
"constant" "uniform" "normal"
2

INPUTBOX
730
965
870
1025
gr-inaccessible-area-mean
0.5
1
0
Number

INPUTBOX
730
1025
870
1085
gr-inaccessible-area-sd
10.0
1
0
Number

TEXTBOX
880
820
1030
838
Fields
12
15.0
1

CHOOSER
875
840
1055
885
gr-field-size-distribution
gr-field-size-distribution
"constant" "uniform" "normal" "log-normal"
3

INPUTBOX
875
885
965
945
gr-field-size-mean-ha
0.49
1
0
Number

INPUTBOX
965
885
1055
945
gr-field-size-sd-ha
0.77
1
0
Number

SWITCH
875
980
965
1013
gr-s1.homebase
gr-s1.homebase
0
1
-1000

SWITCH
965
980
1055
1013
gr-s2.fields
gr-s2.fields
0
1
-1000

SWITCH
875
1015
965
1048
gr-s3.nearby
gr-s3.nearby
0
1
-1000

SWITCH
965
1015
1055
1048
gr-s4.avoid
gr-s4.avoid
0
1
-1000

TEXTBOX
1065
820
1215
838
Land-uses
12
15.0
1

CHOOSER
1180
840
1290
885
gr-land-use-types
gr-land-use-types
"landscape-level-fraction" "household-level-specialization" "spatial-clustering (not there yet)"
1

CHOOSER
1060
840
1180
885
gr-LUT-fill-up
gr-LUT-fill-up
"LUT-1-fraction" "LUT-2-fraction" "LUT-3-fraction" "LUT-4-fraction" "LUT-5-fraction"
0

TEXTBOX
275
1055
425
1073
Input/Output
12
15.0
1

CHOOSER
275
1080
385
1125
gr-default.maps
gr-default.maps
"forest-non-forest" "landuse" "landuse-type" "field-patches" "household-patches" "forestcluster"
2

CHOOSER
275
1125
385
1170
gr-write-household-ids
gr-write-household-ids
"only-first-households" "layered-files"
0

INPUTBOX
490
275
585
335
LUT-0-folder
oilpalm
1
0
String

INPUTBOX
490
335
585
395
LUT-1-folder
rubber
1
0
String

INPUTBOX
490
395
585
455
LUT-2-folder
junglerubber
1
0
String

INPUTBOX
490
515
585
575
LUT-4-folder
0
1
0
String

INPUTBOX
490
455
585
515
LUT-3-folder
0
1
0
String

INPUTBOX
585
335
660
395
LUT-1-color
44.0
1
0
Color

INPUTBOX
585
395
660
455
LUT-2-color
34.0
1
0
Color

INPUTBOX
585
455
660
515
LUT-3-color
84.0
1
0
Color

INPUTBOX
585
515
660
575
LUT-4-color
134.0
1
0
Color

INPUTBOX
585
275
660
335
LUT-0-color
24.0
1
0
Color

INPUTBOX
760
600
830
660
matrix-color
52.0
1
0
Color

INPUTBOX
760
660
830
720
inacc-color
5.0
1
0
Color

INPUTBOX
660
395
730
455
LUT-2-price
1100.0
1
0
Number

INPUTBOX
660
455
730
515
LUT-3-price
0.0
1
0
Number

INPUTBOX
660
515
730
575
LUT-4-price
0.0
1
0
Number

INPUTBOX
815
275
895
335
LUT-0-price-sd
30.0
1
0
Number

INPUTBOX
815
335
895
395
LUT-1-price-sd
255.0
1
0
Number

INPUTBOX
815
395
895
455
LUT-2-price-sd
255.0
1
0
Number

INPUTBOX
815
455
895
515
LUT-3-price-sd
0.0
1
0
Number

INPUTBOX
815
515
895
575
LUT-4-price-sd
0.0
1
0
Number

TEXTBOX
495
120
675
138
== LUT Definitions ==
17
105.0
1

TEXTBOX
520
255
555
273
Folder
12
0.0
1

TEXTBOX
605
255
645
273
Colors
12
0.0
1

TEXTBOX
690
255
725
273
Price
12
0.0
1

TEXTBOX
825
240
875
275
Price \nvariation
12
0.0
1

MONITOR
495
185
595
230
NIL
LUT-ids
17
1
11

MONITOR
595
185
695
230
NIL
LUT-ids-manage
17
1
11

TEXTBOX
340
415
490
433
Land market
12
0.0
1

INPUTBOX
830
660
890
720
hh-color
8.0
1
0
Color

INPUTBOX
830
600
890
660
road-color
9.9
1
0
Color

TEXTBOX
765
580
915
598
Colors
12
0.0
1

SWITCH
420
35
550
68
go-once-profiler?
go-once-profiler?
0
1
-1000

SLIDER
135
1005
250
1038
gr-min-dist-roads
gr-min-dist-roads
1
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
135
1035
250
1068
gr-perlin-octaves
gr-perlin-octaves
1
12
10.0
1
1
NIL
HORIZONTAL

SLIDER
135
1065
250
1098
gr-perlin-persistence
gr-perlin-persistence
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
135
1095
250
1128
gr-cone-angle
gr-cone-angle
0
360
120.0
1
1
NIL
HORIZONTAL

SLIDER
135
1125
250
1158
gr-dist-weight
gr-dist-weight
0
1
0.6
0.01
1
NIL
HORIZONTAL

CHOOSER
255
840
410
885
gr-setup-model
gr-setup-model
"number-of-households" "number-of-villages" "agricultural-area"
2

SLIDER
255
885
410
918
gr-number-of-households
gr-number-of-households
1
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
255
915
410
948
gr-number-of-villages
gr-number-of-villages
1
100
12.0
1
1
NIL
HORIZONTAL

SLIDER
255
945
410
978
gr-proportion-agricultural-area
gr-proportion-agricultural-area
0
1
0.35
0.01
1
NIL
HORIZONTAL

TEXTBOX
260
820
410
838
Setup
12
15.0
1

SLIDER
255
975
410
1008
gr-households-per-cell
gr-households-per-cell
1
20
1.0
1
1
NIL
HORIZONTAL

CHOOSER
415
945
595
990
gr-vlg-area-distribution
gr-vlg-area-distribution
"constant" "uniform" "normal" "lognormal"
1

INPUTBOX
415
990
520
1050
gr-vlg-area-mean
68.17
1
0
Number

INPUTBOX
520
990
595
1050
gr-vlg-area-sd
56.73
1
0
Number

SLIDER
600
840
725
873
gr-occ-probability
gr-occ-probability
0
1
0.0
0.01
1
NIL
HORIZONTAL

INPUTBOX
600
980
725
1040
gr-hh-type-sd
0.24
1
0
Number

INPUTBOX
600
920
725
980
gr-hh-type-mean
0.56
1
0
Number

CHOOSER
600
875
725
920
gr-hh-distribution
gr-hh-distribution
"uniform" "log-normal" "normal"
1

TEXTBOX
605
820
755
838
Household type 2
12
15.0
1

SLIDER
730
930
870
963
gr-inaccessible-area-fraction
gr-inaccessible-area-fraction
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
875
945
1055
978
gr-change-strategy
gr-change-strategy
1
100
2.0
1
1
NIL
HORIZONTAL

SWITCH
875
1050
1055
1083
gr-set-field-strategies-by-id?
gr-set-field-strategies-by-id?
1
1
-1000

SLIDER
875
1085
1055
1118
gr-field-strategies-id
gr-field-strategies-id
1
8
7.0
1
1
NIL
HORIZONTAL

SLIDER
1060
885
1180
918
gr-LUT-0-fraction
gr-LUT-0-fraction
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
1060
915
1180
948
gr-LUT-1-fraction
gr-LUT-1-fraction
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
1060
945
1180
978
gr-LUT-2-fraction
gr-LUT-2-fraction
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1060
975
1180
1008
gr-LUT-3-fraction
gr-LUT-3-fraction
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1060
1005
1180
1038
gr-LUT-4-fraction
gr-LUT-4-fraction
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1180
885
1290
918
gr-LUT-0-specialize
gr-LUT-0-specialize
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1180
915
1290
948
gr-LUT-1-specialize
gr-LUT-1-specialize
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1180
945
1290
978
gr-LUT-2-specialize
gr-LUT-2-specialize
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1180
975
1290
1008
gr-LUT-3-specialize
gr-LUT-3-specialize
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1180
1005
1290
1038
gr-LUT-4-specialize
gr-LUT-4-specialize
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
165
560
305
593
h_debt_years_max_bankrupt
h_debt_years_max_bankrupt
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
165
490
305
523
consumption_frac_cash
consumption_frac_cash
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
165
525
305
558
consumption_frac_wealth
consumption_frac_wealth
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
5
695
160
728
price-fluctuation-percent
price-fluctuation-percent
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
5
660
160
693
sim-time
sim-time
1
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
320
195
485
228
init-wealth-correction-factor
init-wealth-correction-factor
1
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
170
265
305
298
hh-nw-param1
hh-nw-param1
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
170
300
305
333
hh-nw-param2
hh-nw-param2
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
170
335
305
368
spillover-share
spillover-share
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
335
470
475
503
buyer_pool_n
buyer_pool_n
1
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
335
505
475
538
immigrant_probability
immigrant_probability
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
335
540
475
573
land_price_increase
land_price_increase
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
165
675
320
708
rent_rate_capital_lend
rent_rate_capital_lend
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
165
710
320
743
rent_rate_capital_borrow
rent_rate_capital_borrow
0
1
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
165
745
320
778
rent_rate_land
rent_rate_land
0
1
0.1
0.01
1
NIL
HORIZONTAL

TEXTBOX
495
150
645
180
IDs of loaded land-use\nand management files:
12
0.0
1

TEXTBOX
2065
730
2395
755
== Aggregated household output ==
17
105.0
1

INPUTBOX
760
720
830
780
links-color
105.0
1
0
Color

INPUTBOX
230
615
320
675
external_income
500.0
1
0
Number

BUTTON
695
185
775
230
lut parameters
show-lut-parameters
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
490
600
570
660
hh_age_alpha
14.24
1
0
Number

INPUTBOX
570
600
660
660
hh_age_lambda
0.31
1
0
Number

INPUTBOX
490
660
570
720
hh_age_min
18.0
1
0
Number

INPUTBOX
570
660
660
720
hh_age_max
80.0
1
0
Number

TEXTBOX
500
580
650
598
Household age
12
0.0
1

SLIDER
490
720
660
753
takeover_prob
takeover_prob
0
1
0.5
0.01
1
NIL
HORIZONTAL

INPUTBOX
660
600
750
660
age_generation
40.0
1
0
Number

SWITCH
1100
155
1222
188
allow-fallow?
allow-fallow?
1
1
-1000

SLIDER
5
730
160
763
historical_smoothing
historical_smoothing
0
50
0.0
1
1
NIL
HORIZONTAL

INPUTBOX
335
575
475
635
immigrant-xp-bonus
[0 0]
1
0
String

SLIDER
335
635
475
668
immigrant-wealth-factor
immigrant-wealth-factor
1
100
10.0
1
1
NIL
HORIZONTAL

INPUTBOX
135
945
250
1005
gr-road-map-id
jambi1
1
0
String

INPUTBOX
730
275
815
335
LUT-0-price-mu
1.9
1
0
Number

INPUTBOX
730
335
815
395
LUT-1-price-mu
11.0
1
0
Number

BUTTON
930
270
1090
303
NIL
calculate_patch_bird_richness
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
930
305
1090
338
NIL
visualize-bird-richness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
930
235
1090
268
calc_bird_richness?
calc_bird_richness?
1
1
-1000

SWITCH
940
95
1082
128
invest_plantdiv?
invest_plantdiv?
0
1
-1000

MONITOR
940
130
1085
175
NIL
sar_ratio
17
1
11

INPUTBOX
5
535
155
595
social-conversion-prob
0.1
1
0
Number

INPUTBOX
420
70
500
130
idrunnum
NIL
1
0
String

TEXTBOX
935
30
1110
48
== TESTING AREA ==
17
105.0
1

TEXTBOX
945
70
1145
88
Preliminary inVEST biodiversity module:
11
0.0
1

TEXTBOX
935
185
1085
226
Preliminary bird species richness biodiversity model (Mats Mahnken):
11
0.0
1

INPUTBOX
730
395
815
455
LUT-2-price-mu
11.0
1
0
Number

INPUTBOX
730
455
815
515
LUT-3-price-mu
0.0
1
0
Number

INPUTBOX
730
515
815
575
LUT-4-price-mu
0.0
1
0
Number

TEXTBOX
1105
110
1255
151
Preliminary fallow option.\nOnly works with specific land-use folders
11
0.0
1

INPUTBOX
1100
185
1180
245
LUT-0-shock-t
20.0
1
0
Number

INPUTBOX
1100
245
1180
305
LUT-1-shock-t
20.0
1
0
Number

INPUTBOX
1180
185
1260
245
LUT-0-shock-p
0.5
1
0
Number

INPUTBOX
1180
245
1260
305
LUT-1-shock-p
0.0
1
0
Number

PLOT
2060
545
2295
700
LUT-fractions (owned patches)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"op" 1.0 0 -3844592 true "" ""
"rm" 1.0 0 -7171555 true "" ""
"ra" 1.0 0 -14439633 true "" ""
"fo" 1.0 0 -15575016 true "" ""
"op_env_up" 1.0 2 -955883 true "" ""
"op_env_lo" 1.0 2 -955883 true "" ""
"rm_env_up" 1.0 2 -1184463 true "" ""
"rm_env_lo" 1.0 2 -1184463 true "" ""

TEXTBOX
1320
10
1710
28
== EDUCATION VERSION INTERFACE ==
18
25.0
1

TEXTBOX
1310
40
1770
95
On the left there is still the normal EFForTS-ABM parameters\n\nThese will be replaced trough global settings once this is finalized. This version is only meant as a playground to test edu features with the current model version
11
0.0
1

TEXTBOX
2065
30
2265
48
Step 1: Run baseline scenario
14
0.0
1

TEXTBOX
2065
55
2215
81
Set price parmeters via sliders or use button on the right
11
0.0
1

BUTTON
2215
55
2342
88
exemplary-button
go
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
2060
90
2182
123
NIL
edu-run-baseline
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2060
145
2230
178
price-for-1t-carbon
price-for-1t-carbon
0
100
18.0
1
1
NIL
HORIZONTAL

SLIDER
2230
145
2420
178
price-for-1k-consumption
price-for-1k-consumption
0
10
0.47
0.01
1
NIL
HORIZONTAL

SLIDER
2420
145
2605
178
price-for-1-promille-biodiversity
price-for-1-promille-biodiversity
0
100
49.0
1
1
NIL
HORIZONTAL

BUTTON
2190
95
2312
128
NIL
edu-run-scenario
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
2060
245
2230
290
NIL
edu_carbon_scenario
17
1
11

MONITOR
2230
245
2420
290
NIL
edu_consumption_scenario
17
1
11

MONITOR
2420
245
2605
290
NIL
edu_biodiversity_scenario
17
1
11

INPUTBOX
2405
50
2557
110
sim-time
3.0
1
0
Number

INPUTBOX
2060
180
2230
240
edu_carbon_baseline
512.7165256143903
1
0
Number

INPUTBOX
2230
180
2420
240
edu_consumption_baseline
2027.6482692609675
1
0
Number

INPUTBOX
2420
180
2605
240
edu_biodiversity_baseline
49.01648370467397
1
0
Number

MONITOR
2060
290
2230
335
NIL
edu_carbon_p
17
1
11

MONITOR
2230
290
2420
335
NIL
edu_consumption_p
17
1
11

MONITOR
2420
290
2605
335
NIL
edu_biodiversity_p
17
1
11

MONITOR
2060
375
2770
420
NIL
edu_index
17
1
11

MONITOR
2060
420
2162
465
NIL
edu_index_total
17
1
11

@#$#@#$#@
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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="js_2016_sc11" repetitions="20" runMetricsEveryStep="true">
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
