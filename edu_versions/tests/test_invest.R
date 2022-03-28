library(Refforts)
library(testthat)
library(nlrx)

## Set R random seed
set.seed(457348) # we dont need a seed, but util_gather_results(nl, outfile, seed, siminputrow) does


#to fix Temporary output file not found
#dir.create(t <- paste(tempdir(), Sys.getpid(), sep='-'), FALSE, TRUE, "0700")
#unixtools::set.tempdir(t)
#message(tempdir())

######################################
## Setup nl object:


#netlogopath <- file.path("/usr/users/beyer35/nl")



#netlogopath <- file.path("/home/ecomod/nl")

netlogopath <- file.path("/usr/users/beyer35/nl")
#netlogopath <- file.path("/usr/users/henzler1/nl")
#netlogopath <- file.path("/home/julia/netlogofolder")
netlogopath <- file.path("C:/Program Files (x86)/NetLogo 6.1.1")
netlogoversion <- "6.1.1"


if (file.exists(netlogopath)){
  print('netlogopath exists')
}else{
  stop('Please specify the folder that contains Netlogo')
}
#eigentlich solltest du hier nicht /home/julia davor schreiben muessen, da das dein working directory fuer Rstudio ist
modelpath <- file.path("01_EFForTS-ABM/EFForTS-ABM.nlogo")#/home/julia/
#modelpath <- file.path("01_EFForTS-ABM/tests/test_models/Python Basic Example.nlogo")
if (file.exists(modelpath)){
  print('modelpath exists')
}else{
  stop('Please specify the folder that contains the model')
}
#hier genauso
outpath <- file.path(".") #/home/julia/EFForTS-ABM/01_EFForTS-ABM/tests/output

if (file.exists(outpath)){
  print('outpath exists')
}else{
  stop('Please specify the folder that contains the outpath')
}


nl <- nl(nlversion = netlogoversion,
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 1024)


#dummy_list <- list(0)
#names(dummy_list) <- c("dummy_variable")
variable_list <- list("\"hundred-farmers3\"")#"\"server\"")#"general", 3478436
names(variable_list) <- c("which-map")#"which-machine?")#"rand-seed","dummy_variable", "biodiv_invest_objective")#, 
message("refforts output: ",get.abm.defaults()[3][1])
message("types: ",str(get.abm.defaults()[3]))
#message("manually typed in variable: ",variable_list[1])
#message("types: ", str(variable_list))
         
nl@experiment <- experiment(expname="test",
                           outpath=outpath,
                           repetition=1,
                           tickmetrics="true",
                           idsetup="test-setup", #setup-with-external-maps #test-invest # #do-nothingsetup
                           idgo="test-invest", #go-biodiversity #go #"do-nothing",#
                           #idrunnum = "idrunnum",
                           idfinal = "do-nothing",#write-lut-map #go
                           runtime=1,
                           #metrics=c(get.abm.metrics()),
                           constants = get.abm.defaults()#variable_list###dummy_list#
                           )


nl <- set.nl.constant(nl, "biodiv_invest_objective", "\"general\"")
#nl <- set.nl.constant(nl, "which-machine?", "\"server\"")
#nl <- set.nl.constant(nl, "which-machine?", "\"local-linux\"")


## Add simple simdesign
nl@simdesign <- simdesign_simple(nl, nseeds=1)
#print(nl)



## Run simulations:
message('starting netlogo simulation')
results <- run_nl_all(nl)
message('finished netlogo simulation')
## Attach output:
#setsim(nl, "simoutput") <- results

write_simoutput(nl, outpath = "01_EFForTS-ABM/tests")


## Result tests:

#testthat::test_that( habitat quality, ueberall 1)
