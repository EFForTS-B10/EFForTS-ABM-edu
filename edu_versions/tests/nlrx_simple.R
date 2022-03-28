########################################################################################
##                                                                                    ##
## Simple EFForTS-ABM Test with default parameterisation loaded from Refforts package ##
##                                                                                    ##
########################################################################################

## Install packages
#devtools::install_github("nldoc/Refforts")
#install.packages("nlrx")

## Load packages
library(Refforts)
library(nlrx)
library(testthat)

## Set R random seed
set.seed(457348)

## Define nl object
#netlogopath <- file.path("../../../netlogofolder")
#netlogopath <- file.path("netlogofolder")
netlogopath <- file.path("C:/Program Files (x86)/NetLogo 6.1.1")
#netlogopath <- file.path("/home/ecomod/NetLogo 6.1.1")
netlogoversion <- "6.1.1"


if (file.exists(netlogopath)){
  print('exists')
}else{
  stop('Please specify the folder that contains Netlogo')
}

#modelpath <- file.path("../EFForTS-ABM.nlogo")
#modelpath <- "../EFForTS-ABM.nlogo"

modelpath <- "C:/Users/JuliaHenzler/Documents/5_GitHub/EFForTS-ABM/01_EFForTS-ABM/EFForTS-ABM.nlogo"

outpath <- file.path("EFForTS-ABM/03_Analyses/")

nl <- nl(nlversion = netlogoversion,
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
                            metrics=get.abm.metrics(),
                            constants = get.abm.defaults())

## overwrite constants:
## In case you want to test other settings than the default parameterisation you can overwrite the constants of the experiment
## The Refforts function has a convenient function to do that:
## For example, in order to change the default map (hundred-farmers3) to the landmarkets1 map you can do:
## nl <- set.nl.constant(nl, "which-map", "\"landmarkets1\"")

## Set random-seed to reproducable
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
  testthat::expect_equal(ncol(nl@simdesign@simoutput), 89)
})
  
testthat::test_that("Steps and seed", {
  testthat::expect_equal(nl@simdesign@simoutput$`[step]`, seq(0,49))
  testthat::expect_equal(nl@simdesign@simoutput$`random-seed`, rep(nl@simdesign@simseeds, nl@experiment@runtime))
})

testthat::test_that("Results", {
  # testing two example outputs here:
  testthat::expect_equal(mean(nl@simdesign@simoutput$hh.count), 77.7, tolerance=0.05)
  testthat::expect_equal(mean(nl@simdesign@simoutput$hh.area.mean), 21.5, tolerance=0.05)
})


