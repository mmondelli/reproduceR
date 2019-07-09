#' Function to pack the experiment
#'
#' This function allows you to package your experiment using packrat.
#' It then creates a Vagrantfile and starts a VM containing the experiment.
#' @param pack_project Path to experiment directory. Defaults to '.'.
#' @keywords pack
#' @export
#' @examples
#' pack()

pack <- function(pack_project = '.'){
  if(!is.null(names(sessionInfo()$otherPkgs))){
    lapply(paste('package:',names(sessionInfo()$otherPkgs),sep=""), detach, character.only=TRUE, unload=TRUE)
  }
  print("Copying default VagrantFile to the experiment directory")
  #system(paste0('cp VagrantFile ', pack_project))
  default_vagrant <- system.file('Vagrantfile', package='reproduceR')
  system(paste0('cp ',default_vagrant, ' ', pack_project))
  print("Packing the project - this will take a few minutes.")
  library(packrat)
  packrat::init(project = pack_project, infer.dependencies = T, restart = F)
  print("Compressing project")
  packrat::bundle(overwrite = T)
  print("Vagrant up - this will take a few minutes")
  system(paste0('cd ',pack_project,'; vagrant up --provision'))
}
