########################################################################################
##                                                                                    ##
## Simple EFForTS-ABM Test with default parameterisation loaded from Refforts package ##
##                                                                                    ##
########################################################################################

## Install packages
#install.packages("nlrx")

## Load packages
library(nlrx)
library(testthat)

## Set R random seed
set.seed(457348)

## Define nl object
netlogopath <- file.path("C:/Program Files/NetLogo 6.1.1")
modelpath <- "01_EFForTS-ABM/EFForTS-ABM.nlogo"
outpath <- "03_Analyses/"

nl <- nl(nlversion = "6.1.1",
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 1024)

## Define experiment
nl@experiment <- experiment(expname="invest",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="setup-with-external-maps",
                            idgo="go",
                            runtime=50,
                            metrics=c("lut0.carbon","lut1.carbon",
                                      "lut0.price","lut1.price", 
                                      "lut0.fraction","lut1.fraction",
                                      "lut0.yield.sum","lut1.yield.sum","lut0.yield.mean","lut1.yield.mean",
                                      "hh.count","hh.count.immigrant",
                                      "hh.area.sum","hh.area.mean",
                                      "hh.consumption.sum","hh.consumption.mean",
                                      "p.sar",
                                      "p.tinput.sum","p.tinput.mean",
                                      "p.capitalstock.sum","p.capitalstock.mean"),
                            constants = list("reproducable?" = "FALSE", 
                                            "rnd-seed" = 3478436, 
                                            "which-map" = "\"hundred-farmers3\"", 
                                            "land-use-change-decision" = "\"only-one-field-per-year\"", 
                                            "sim-time" = 50, 
                                            "price_scenario" = "\"historical_trends\"", 
                                            "price-fluctuation-percent" = 10, 
                                            "historical_smoothing" = 0, 
                                            "LUT-0-folder" = "\"oilpalm\"", 
                                            "LUT-0-price" = 90, 
                                            "LUT-0-price-mu" = 1.9, 
                                            "LUT-0-price-sd" = 1.9, 
                                            "LUT-1-folder" = "\"rubber\"", 
                                            "LUT-1-price" = 1100, 
                                            "LUT-1-price-mu" = 11, 
                                            "LUT-1-price-sd" = 11,
                                            "consumption-on?" = "TRUE", 
                                            "consumption_base" = 1000, 
                                            "consumption_frac_cash" = 0.1, 
                                            "consumption_frac_wealth" = 0.05, 
                                            "heterogeneous-hhs?" = "TRUE", 
                                            "learning-spillover?" = "FALSE", 
                                            "setup-hh-network" = "\"hh-nw-n-nearest-neighbors\"", 
                                            "hh-nw-param1" = 10, 
                                            "hh-nw-param2" = 50, 
                                            "spillover-share" = 1, 
                                            "h_debt_years_max_bankrupt" = 5, 
                                            "landmarket?" = "TRUE", 
                                            "buyer_pool_n" = 10, 
                                            "immigrant_probability" = 0.5, 
                                            "land_price_increase" = 0.05, 
                                            "immigrant-xp-bonus" = "\"[0 0]\"", 
                                            "immigrant-wealth-factor" = 1, 
                                            "initial-wealth-distribution" = "\"log-normal\"", 
                                            "init-wealth-correction-factor" = 10, 
                                            "wealth-log-mean" = 7, 
                                            "wealth-log-sd" = 1, 
                                            "wealth-constant" = 10000, 
                                            "min-wealth" = 30, 
                                            "time-horizon" = 10, 
                                            "discount-rate" = 0.1, 
                                            "land_price" = 750, 
                                            "external_income" = 500, 
                                            "rent_rate_capital_lend" = 0.1, 
                                            "rent_rate_capital_borrow" = 0.15, 
                                            "rent_rate_land" = 0.1, 
                                            "hh_age_alpha" = 14.24, 
                                            "hh_age_lambda" = 0.31, 
                                            "hh_age_min" = 18, 
                                            "hh_age_max" = 80, 
                                            "age_generation" = 40, 
                                            "takeover_prob" = 0.5, 
                                            "ecol_biodiv_interval" = 1,
                                            "biodiv_birds" = "\"none\"",
                                            "biodiv_plants" = "\"SAR\"",
                                            "biodiv_invest_objective" = "\"generell\"",
                                            "allow-fallow?" = "FALSE", 
                                            "go-once-profiler?" = "FALSE", 
                                            "SHOW-OUTPUT?" = "FALSE", 
                                            "write-maps?" = "FALSE", 
                                            "write-hh-data-to-file?" = "FALSE", 
                                            "export-view?" = "FALSE", 
                                            "show-homebases?" = "TRUE", 
                                            "show-roads?" = "TRUE"))

## overwrite constants:
## In case you want to test other settings than the default parameterisation you can overwrite the constants of the experiment
## The Refforts function has a convenient function to do that:
## For example, in order to change the default map (hundred-farmers3) to the landmarkets1 map you can do:
## nl <- set.nl.constant(nl, "which-map", "\"landmarkets1\"")

nl <- set.nl.constant(nl, "reproducable?", "true")

## Add simple simdesign
nl@simdesign <- simdesign_simple(nl, nseeds=1)
print(nl)

## Run simulations:
results <- run_nl_all(nl)

## Attach output:
setsim(nl, "simoutput") <- results

## Result tests:

testthat::test_that("Number of Rows and variables", {
  testthat::expect_equal(nrow(nl@simdesign@simoutput), 50)
  testthat::expect_equal(ncol(nl@simdesign@simoutput), 87)
})
  
testthat::test_that("Steps and seed", {
  testthat::expect_equal(nl@simdesign@simoutput$`[step]`, seq(0,49))
  testthat::expect_equal(nl@simdesign@simoutput$`random-seed`, rep(nl@simdesign@simseeds, nl@experiment@runtime))
})

testthat::test_that("Results", {
  # testing two example outputs here:
  testthat::expect_equal(mean(nl@simdesign@simoutput$hh.count), 56.96)
  testthat::expect_equal(mean(nl@simdesign@simoutput$hh.area.mean), 41.75218)
})


