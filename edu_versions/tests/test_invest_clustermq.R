#dir.create(t <- paste(tempdir(), Sys.getpid(), sep='-'), FALSE, TRUE, "0700")
#unixtools::set.tempdir(t)
#message(tempdir())

list.files('~')


library(Refforts)
library(testthat)
library(clustermq)
library(nlrx)

## Set R random seed
set.seed(457348) # we dont need a seed, but util_gather_results(nl, outfile, seed, siminputrow) does

#netlogopath <- file.path("/usr/users/henzler1/nl")
netlogopath <- file.path("/usr/users/beyer35/nl")
#netlogopath <- file.path("/home/julia/netlogofolder")
netlogoversion <- "6.1.1"


if (file.exists(netlogopath)){
  print('netlogopath exists')
}else{
  stop('Please specify the folder that contains Netlogo')
}
#eigentlich solltest du hier nicht /home/julia davor schreiben muessen, da das dein working directory fuer Rstudio ist
modelpath <- file.path("01_EFForTS-ABM/EFForTS-ABM.nlogo")#/home/julia/

if (file.exists(modelpath)){
  print('modelpath exists')
}else{
  stop('Please specify the folder that contains the model')
}
#hier genauso
outpath <- file.path("01_EFForTS-ABM/tests/") #/home/julia/EFForTS-ABM/01_EFForTS-ABM/tests/output

if (file.exists(outpath)){
  print('outpath exists')
}else{
  stop('Please specify the folder that contains the outpath')
}

nl <- nl(nlversion = netlogoversion,
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 1024)

nl@experiment <- experiment(expname="test",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="test-invest", #setup-with-external-maps
                            idgo="do-nothing",#test-invest #go-biodiversity
                            idrunnum = "idrunnum",
                            idfinal = "do-nothing",#write-lut-map
                            runtime=1,
                            #metrics=c(get.abm.metrics()),
                            constants = get.abm.defaults())


nl <- set.nl.constant(nl, "biodiv_invest_objective", "\"general\"")
nl <- set.nl.constant(nl, "which-machine?", "\"server\"")


## Add simple simdesign
nl@simdesign <- simdesign_simple(nl, nseeds=1)
#print(nl)






## Prepare jobs and execute on the HPC:
maxjobs.hpc <- 2
njobs <- min(nrow(nl@simdesign@siminput) * length(nl@simdesign@simseeds), maxjobs.hpc)
siminputrows <- rep(seq(1:nrow(nl@simdesign@siminput)), length(nl@simdesign@simseeds))
rndseeds <- rep(nl@simdesign@simseeds, each=nrow(nl@simdesign@siminput))

simfun <- function(nl, siminputrow, rndseed, writeRDS=FALSE)
{
  library(nlrx)
  res <- run_nl_one(nl = nl, siminputrow = siminputrow, seed = rndseed)#, writeRDS = writeRDS
  return(res)
}


message(tempdir())




### RUN:
results <- clustermq::Q(fun = simfun,
                        siminputrow = siminputrows,
                        rndseed = rndseeds,
                        const = list(nl = nl,
                                     writeRDS = TRUE),
                        export = list(),
                        seed = 42,
                        n_jobs = njobs,
                        template = list(job_name = "test_invest_clustermq", # define jobname
                                        log_file = "test_invest_clustermq.log", # define logfile name
                                        queue = "medium",  # define HPC queue
                                        service = "normal", # define HPC service
                                        walltime = "1:00:00", # define walltime
                                        mem_cpu = "4000"),# define memory per cpu
                        log_worker = TRUE) 


setsim(nl, "simoutput") <- results

write_simoutput(nl, outpath = "01_EFForTS-ABM/tests/output")
