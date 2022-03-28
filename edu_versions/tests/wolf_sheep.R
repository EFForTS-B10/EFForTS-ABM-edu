#dir.create(t <- paste(tempdir(), Sys.getpid(), sep='-'), FALSE, TRUE, "0700")
#unixtools::set.tempdir(t)

library(nlrx)
library(clustermq)

#set paths

netlogopath <- file.path("nl")
netlogoversion <- "6.1.1"


if (file.exists(netlogopath)){
  print('netlogopath exists')
}else{
  stop('Please specify the folder that contains Netlogo')
}

#modelpath <- file.path("/home/ecomod/nl/app/models/Sample Models/Biology/Wolf Sheep Predation.nlogo")
outpath <- file.path("EFForTS-ABM/01_EFForTS-ABM/tests/output")#/EFForTS-ABM/01_EFForTS-ABM/tests/

modelpath <- file.path("nl/app/models/Sample Models/Biology/Wolf Sheep Predation.nlogo")
#outpath <- file.path(".")#/EFForTS-ABM/01_EFForTS-ABM/tests/


if (file.exists(modelpath)){
  print('modelpath exists')
}else{
  stop('Please specify the folder that contains the model')
}


if (file.exists(outpath)){
  print('outpath exists')
}else{
  stop('Please specify the folder that contains the outpath')
}



#attach paths, set available memory for JAVA, set NetLogo version
nl <- nl(nlversion = netlogoversion,
         nlpath = netlogopath,
         modelpath = modelpath,
         jvmmem = 1024)

nl@experiment <- experiment(expname="wolf-sheep",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="setup",
                            idgo="go",
                            idfinal=NA_character_,
                            idrunnum=NA_character_,
                            runtime=10,
                            evalticks=seq(4,5),
                            metrics=c("count sheep", "count wolves", "count patches with [pcolor = green]"),
                            variables = list('initial-number-sheep' = list(min=50, max=150, qfun="qunif"),
                                             'initial-number-wolves' = list(min=50, max=150, qfun="qunif")),
                            constants = list("model-version" = "\"sheep-wolves-grass\"",
                                             "grass-regrowth-time" = 30,
                                             "sheep-gain-from-food" = 4,
                                             "wolf-gain-from-food" = 20,
                                             "sheep-reproduce" = 4,
                                             "wolf-reproduce" = 5,
                                             "show-energy?" = "false"))


#nl@simdesign <- simdesign_eFast(nl=nl, samples=10, nseeds=3)

nl@simdesign <-  simdesign_simple(nl, nseeds=1)

#results <- run_nl_all(nl)



#setsim(nl, "simoutput") <- run_nl_all(nl)




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
                        template = list(job_name = "wolfsheeptest", # define jobname
                                        log_file = "wolfsheeptest.log", # define logfile name
                                        queue = "medium",  # define HPC queue
                                        service = "normal", # define HPC service
                                        walltime = "16:00:00", # define walltime
                                        mem_cpu = "4000"),# define memory per cpu
                        log_worker = TRUE) 


message("show results")
print(results)

setsim(nl, "simoutput") <- results

message("show simoutput")
typeof(nl)

write_simoutput(nl, outpath = "EFForTS-ABM/01_EFForTS-ABM/tests/output")  
#i##################################

