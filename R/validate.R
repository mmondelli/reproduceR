#' Function to run the experiment and collect provenance
#'
#' This function allows you to run your experiment using rdt
#' to collect provenance information.
#' It then creates a directory containing the orignal script and the collected provenance data
#' @param script Script to be executed. Defaults to 'script.R'
#' @keywords validate, provenance
#' @export
#' @examples
#' validate()
validate <- function(script='script.R', dir = '.'){
  library(rdt, lib.loc = '/usr/local/lib/R/site-library/')
  prov.run(script, dir)

  #preserve(script, paste0(dir, 'prov_dir'))

}
