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
  "scr_ABM/util_lut_functions.nls" "scr_ABM/util_paramfiles.nls" "scr_ABM/util_reporter.nls" "scr_ABM/util_gui_defaults.nls"
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
  edu-NoS-version? ; education Version for Night of Science?
  edu-scenarios-version? ; education version with different scenarios (Dislich  2018)?
  extra-parameters-tab? ; are parameteres mainly choosen in extra Parameters Tab (and not main Intereface tab)?
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
  h_management       ; List with management ids for each LUT
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
  print["setting up"]

  ; control randomness
  set-rnd-seed

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
  print ["Set up finished!"]
  print " "

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
900
70
1608
779
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
2085
40
2295
195
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
1615
40
1850
195
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

PLOT
1940
240
2195
460
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
ca\nsetup-with-external-maps
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
go\ndo-plots\nupdate-time
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
2195
460
2450
680
Household capitalstock [$]
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

PLOT
1850
40
2085
195
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

BUTTON
955
35
1010
68
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
901
35
956
68
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
1010
35
1095
68
inspect rnd hh
inspect one-of turtles
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
1095
35
1190
68
inspect rnd patch
inspect one-of patches
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
1940
460
2195
680
Household expected netcashflow of chosen option
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

SWITCH
505
70
635
103
SHOW-OUTPUT?
SHOW-OUTPUT?
0
1
-1000

PLOT
2195
240
2450
460
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
1620
10
1880
31
== Landscape level output ==
17
105.0
1

TEXTBOX
900
10
1615
28
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

BUTTON
1190
35
1335
68
NIL
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
1335
35
1390
68
NIL
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

MONITOR
2300
40
2375
85
active_hhs
count hhs
17
1
11

MONITOR
2375
40
2447
85
immigrants
count hhs with [h_immigrant? = TRUE]
17
1
11

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
157
183
reproducible?
reproducible?
1
1
-1000

INPUTBOX
5
185
155
245
rnd-seed
7.60267126E8
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
"one-farmer-one-field" "one-farmer" "five-farmers" "five-farmers2" "five-farmers3" "ten-farmers" "ten-farmers2" "twenty-farmers" "twenty-farmers2" "thirty-farmers2" "fifty-farmers" "fifty-farmers2" "fifty-farmers4" "fifty-farmers5" "hundred-farmers" "hundred-farmers2" "hundred-farmers3" "twohundred-farmers" "twohundred-farmers-big-plantations" "fourhundred-farmers" "landmarkets1" "landmarkets2" "EFForTS-LGraf"
0

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
665
235
735
295
LUT-0-price
90.0
1
0
Number

INPUTBOX
665
295
735
355
LUT-1-price
1100.0
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
30.0
1
0
Number

INPUTBOX
320
350
410
410
time-horizon
10.0
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
1
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
2

TEXTBOX
165
600
275
618
Household Finances
12
0.0
1

INPUTBOX
165
620
230
680
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
15
890
1400
908
== EFForTS-LGraf Parameters ================================================================================================
17
15.0
1

TEXTBOX
15
920
110
938
Model Control
12
15.0
1

SWITCH
10
940
182
973
gr-reproducible?
gr-reproducible?
1
1
-1000

INPUTBOX
10
975
120
1035
gr-rnd-seed
100.0
1
0
Number

INPUTBOX
10
1035
65
1095
gr-width
100.0
1
0
Number

INPUTBOX
65
1035
120
1095
gr-height
100.0
1
0
Number

INPUTBOX
10
1095
120
1155
gr-cell-length-meter
50.0
1
0
Number

TEXTBOX
135
920
170
938
Road
12
15.0
1

CHOOSER
125
940
240
985
gr-road.algorithm
gr-road.algorithm
"artificial.graffe" "artificial.perlin" "real.shapefile"
2

INPUTBOX
125
985
240
1045
gr-total-road-length
1099.0
1
0
Number

TEXTBOX
410
920
475
938
Household
12
15.0
1

CHOOSER
405
940
585
985
gr-hh-area-distribution
gr-hh-area-distribution
"constant" "normal" "log-normal"
2

INPUTBOX
405
985
495
1045
gr-hh-area-mean-ha
1.0
1
0
Number

INPUTBOX
495
985
585
1045
gr-hh-area-sd-ha
0.92
1
0
Number

TEXTBOX
725
920
875
938
Inaccessible Areas
12
15.0
1

CHOOSER
720
940
860
985
gr-inaccessible-area-location
gr-inaccessible-area-location
"random" "road-connected"
0

CHOOSER
720
985
860
1030
gr-inaccessible-area-distribution
gr-inaccessible-area-distribution
"constant" "uniform" "normal"
2

INPUTBOX
720
1065
860
1125
gr-inaccessible-area-mean
0.5
1
0
Number

INPUTBOX
720
1125
860
1185
gr-inaccessible-area-sd
10.0
1
0
Number

TEXTBOX
870
920
1020
938
Fields
12
15.0
1

CHOOSER
865
940
1045
985
gr-field-size-distribution
gr-field-size-distribution
"constant" "uniform" "normal" "log-normal"
3

INPUTBOX
865
985
955
1045
gr-field-size-mean-ha
0.49
1
0
Number

INPUTBOX
955
985
1045
1045
gr-field-size-sd-ha
0.77
1
0
Number

SWITCH
865
1080
955
1113
gr-s1.homebase
gr-s1.homebase
0
1
-1000

SWITCH
955
1080
1045
1113
gr-s2.fields
gr-s2.fields
0
1
-1000

SWITCH
865
1115
955
1148
gr-s3.nearby
gr-s3.nearby
0
1
-1000

SWITCH
955
1115
1045
1148
gr-s4.avoid
gr-s4.avoid
0
1
-1000

TEXTBOX
1055
920
1205
938
Land-uses
12
15.0
1

CHOOSER
1170
940
1280
985
gr-land-use-types
gr-land-use-types
"landscape-level-fraction" "household-level-specialization" "spatial-clustering (not there yet)"
1

CHOOSER
1050
940
1170
985
gr-LUT-fill-up
gr-LUT-fill-up
"LUT-1-fraction" "LUT-2-fraction" "LUT-3-fraction" "LUT-4-fraction" "LUT-5-fraction"
0

TEXTBOX
1285
915
1435
933
Input/Output
12
15.0
1

CHOOSER
1285
940
1395
985
gr-default.maps
gr-default.maps
"forest-non-forest" "landuse" "landuse-type" "field-patches" "household-patches" "forestcluster"
5

CHOOSER
1285
985
1395
1030
gr-write-household-ids
gr-write-household-ids
"only-first-households" "layered-files"
1

INPUTBOX
495
235
590
295
LUT-0-folder
oilpalm
1
0
String

INPUTBOX
495
295
590
355
LUT-1-folder
rubber
1
0
String

INPUTBOX
495
355
590
415
LUT-2-folder
NA
1
0
String

INPUTBOX
495
475
590
535
LUT-4-folder
NA
1
0
String

INPUTBOX
495
415
590
475
LUT-3-folder
NA
1
0
String

INPUTBOX
590
295
665
355
LUT-1-color
44.0
1
0
Color

INPUTBOX
590
355
665
415
LUT-2-color
34.0
1
0
Color

INPUTBOX
590
415
665
475
LUT-3-color
84.0
1
0
Color

INPUTBOX
590
475
665
535
LUT-4-color
134.0
1
0
Color

INPUTBOX
590
235
665
295
LUT-0-color
24.0
1
0
Color

INPUTBOX
495
560
565
620
matrix-color
52.0
1
0
Color

INPUTBOX
625
560
695
620
inacc-color
5.0
1
0
Color

INPUTBOX
665
355
735
415
LUT-2-price
0.0
1
0
Number

INPUTBOX
665
415
735
475
LUT-3-price
0.0
1
0
Number

INPUTBOX
665
475
735
535
LUT-4-price
0.0
1
0
Number

INPUTBOX
820
235
900
295
LUT-0-price-sd
10.0
1
0
Number

INPUTBOX
820
295
900
355
LUT-1-price-sd
100.0
1
0
Number

INPUTBOX
820
355
900
415
LUT-2-price-sd
0.0
1
0
Number

INPUTBOX
820
415
900
475
LUT-3-price-sd
0.0
1
0
Number

INPUTBOX
820
475
900
535
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
525
215
560
233
Folder
12
0.0
1

TEXTBOX
610
215
650
233
Colors
12
0.0
1

TEXTBOX
695
215
730
233
Price
12
0.0
1

TEXTBOX
830
200
880
235
Price \nvariation
12
0.0
1

MONITOR
495
165
595
210
NIL
LUT-ids
17
1
11

MONITOR
595
165
695
210
NIL
LUT-ids-manage
17
1
11

INPUTBOX
695
560
755
620
hh-color
8.0
1
0
Color

INPUTBOX
565
560
625
620
road-color
9.9
1
0
Color

TEXTBOX
500
540
650
558
Colors
12
0.0
1

SWITCH
505
35
635
68
go-once-profiler?
go-once-profiler?
0
1
-1000

SLIDER
125
1105
240
1138
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
125
1135
240
1168
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
125
1165
240
1198
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
240
1135
355
1168
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
240
1165
355
1198
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
245
940
400
985
gr-setup-model
gr-setup-model
"number-of-households" "number-of-villages" "agricultural-area"
0

SLIDER
245
985
400
1018
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
245
1015
400
1048
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
245
1045
400
1078
gr-proportion-agricultural-area
gr-proportion-agricultural-area
0
1
0.3
0.01
1
NIL
HORIZONTAL

TEXTBOX
250
920
400
938
Setup
12
15.0
1

SLIDER
245
1075
400
1108
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
405
1045
585
1090
gr-vlg-area-distribution
gr-vlg-area-distribution
"constant" "uniform" "normal" "lognormal"
1

INPUTBOX
405
1090
510
1150
gr-vlg-area-mean
68.17
1
0
Number

INPUTBOX
510
1090
585
1150
gr-vlg-area-sd
56.73
1
0
Number

SLIDER
590
940
715
973
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
590
1080
715
1140
gr-hh-type-sd
0.24
1
0
Number

INPUTBOX
590
1020
715
1080
gr-hh-type-mean
0.56
1
0
Number

CHOOSER
590
975
715
1020
gr-hh-distribution
gr-hh-distribution
"uniform" "log-normal" "normal"
1

TEXTBOX
595
920
745
938
Household type 2
12
15.0
1

SLIDER
720
1030
860
1063
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
865
1045
1045
1078
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
865
1150
1045
1183
gr-set-field-strategies-by-id?
gr-set-field-strategies-by-id?
1
1
-1000

SLIDER
865
1185
1045
1218
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
1050
985
1170
1018
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
1050
1015
1170
1048
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
1050
1045
1170
1078
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
1050
1075
1170
1108
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
1050
1105
1170
1138
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
1170
985
1280
1018
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
1170
1015
1280
1048
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
1170
1045
1280
1078
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
1170
1075
1280
1108
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
1170
1105
1280
1138
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
50.0
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
10.0
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
165
680
320
713
rent_rate_capital_lend
rent_rate_capital_lend
0
1
0.08
0.01
1
NIL
HORIZONTAL

SLIDER
165
715
320
748
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
750
320
783
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
145
780
163
IDs of loaded land-use and management files:
12
0.0
1

TEXTBOX
1955
210
2285
235
== Aggregated household output ==
17
105.0
1

TEXTBOX
2305
10
2455
31
== Monitors ==
17
105.0
1

INPUTBOX
755
560
825
620
links-color
105.0
1
0
Color

INPUTBOX
230
620
320
680
external_income
500.0
1
0
Number

BUTTON
695
165
775
210
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

PLOT
1615
240
1775
360
LUT-0-mean-yield
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

PLOT
1775
240
1935
360
LUT-0-mean-yield-gap
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

PLOT
1615
360
1775
480
LUT-1-mean-yield
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

PLOT
1615
480
1775
600
LUT-2-mean-yield
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

PLOT
1775
360
1935
480
LUT-1-mean-yield-gap
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

PLOT
1775
480
1935
600
LUT-2-mean-yield-gap
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

PLOT
1615
600
1775
720
LUT-3-mean-yield
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

PLOT
1615
720
1775
840
LUT-4-mean-yield
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

PLOT
1775
600
1935
720
LUT-3-mean-yield-gap
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

PLOT
1775
720
1935
840
LUT-4-mean-yield-gap
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

TEXTBOX
1620
210
1805
228
== LUT level output ==
17
105.0
1

BUTTON
1390
35
1472
68
color_age
go\nask patches [set pcolor scale-color red p_age 0 50]
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

PLOT
1940
680
2195
900
Household area
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
"median" 1.0 0 -2674135 true "" ""
"whisker.top" 1.0 0 -16777216 true "" ""
"whisker.bottom" 1.0 0 -16777216 true "" ""
"outlier" 1.0 2 -16777216 true "" ""

MONITOR
2300
85
2432
130
hh_area_mean (cells)
precision mean [h_area] of hhs 3
17
1
11

INPUTBOX
125
1045
240
1105
gr-road-map-id
jambi1
1
0
String

INPUTBOX
735
235
820
295
LUT-0-price-mu
1.9
1
0
Number

INPUTBOX
735
295
820
355
LUT-1-price-mu
11.0
1
0
Number

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
640
45
785
105
idrunnum
NIL
1
0
String

MONITOR
2300
130
2380
175
NIL
count lms
17
1
11

INPUTBOX
735
355
820
415
LUT-2-price-mu
0.0
1
0
Number

INPUTBOX
735
415
820
475
LUT-3-price-mu
0.0
1
0
Number

INPUTBOX
735
475
820
535
LUT-4-price-mu
0.0
1
0
Number

TEXTBOX
645
30
745
48
nlrx exchange:
11
0.0
1

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
