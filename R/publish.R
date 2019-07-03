#' Function to publish the experiment on zenodo
#'
#' This function allows you to publish your experiment in Zenodo.
#' It gathers the provenance files and database, the experiment bundled with packrat
#' and the Vagrant file with the system specifications to reproduce the experiment.
#' @param token User token (must be created in Zenodo).
#' @param title Title of the publication on Zenodo. It can be edited on the Zenodo platform after publication.
#' @param description Description of the publication on Zenodo. It can be edited on the Zenodo platform after publication.
#' @param uploadType Upload type on Zenodo. It can be edited on the Zenodo platform after publication.
#' @param pubType Publication type on Zenodo. It can be edited on the Zenodo platform after publication.
#' @param creatorFirstname Creator firstname. It can be edited on the Zenodo platform after publication.
#' @param creatorLastname Creator lastname It can be edited on the Zenodo platform after publication.
#' @param license Publication license. It can be edited on the Zenodo platform after publication.
#' @param bundle Path to compressed file containig the experiment (generated with packrat).
#' @param prov_dir Path to the provenance directory.
#' @keywords publish, zenodo
#' @export
#' @examples
#' publish()

publish <- function(token, title = 'My publication title',
                    description = 'My description',
                    uploadType = 'publication', pubType = '',
                    creatorFirstname = 'Creator first name',
                    creatorLastname = 'Creator last name',
                    license = 'mit',
                    bundle,
                    prov_dir,
                    prov_db = '~/prov.db'){
  #install_github("eblondel/zen4R")
  require(zen4R, lib.loc = '/usr/local/lib/R/site-library/')
  require(digest)

  time_md5 <- digest(as.character(Sys.time()), "md5", serialize = FALSE)
  experiment <- paste0('~/experiment_',time_md5)

  #Compressing files
  system(paste0('cd ~; mkdir ',experiment,'; cp ~/Vagrantfile_edited ',experiment,'/Vagrantfile'))
  system(paste0('cp -r ',bundle,' ',experiment))
  system(paste0('cp -r ',prov_dir,' ',experiment))
  system(paste0('cp -r ',prov_db,' ',experiment))
  system(paste0('tar -zcvf ',experiment,'.tar.gz ', experiment))

  zenodo <- ZenodoManager$new(token = token, logger = "DEBUG")
  myrec <- zenodo$createEmptyRecord()
  myrec$setTitle(title)
  myrec$setDescription(description)
  myrec$setUploadType(uploadType)
  myrec$setPublicationType("article")
  myrec$addCreator(firstname = creatorFirstname, lastname = creatorLastname, affiliation = "Independent")
  myrec$setLicense(license)
  myrec <- zenodo$depositRecord(myrec)
  zenodo$uploadFile(paste0(experiment,'.tar.gz'), myrec$id)
  myrec_files <- zenodo$getFiles(myrec$id)
  zenodo$publishRecord(myrec$id)
}
