#' Function to preserve the experiment
#'
#' This function allows you to preserve the experiment, detecting new installed applications
#' and creating a relational database to store provenance information
#' @param con Connection to the porvenance database
#' @param prov_json Location of the prov.json file generated by the validate function
#' @keywords preserve, provenance
#' @export
#' @examples
#' preserve()
#' preserve(con = '~/prov.db', prov_json = './prov.json')
#/home/vagrant/R/x86_64-pc-linux-gnu-library/3.6
preserve <- function(con = '~/prov.db', prov_json = './prov_script/prov.json'){
  # Vagrant
  system('apt list --installed > ~/.new_installed.log; diff ~/.installed.log ~/.new_installed.log > ~/.diff.log')
  lines_diff <- system('wc -l ~/.diff.log')
  if (lines_diff > 0){
    diff <- read.csv('~/.diff.log', sep = " ", header = F)
    diff <- diff[diff$V5 == '[installed]',]
    diff <- diff[,2]
    packages <- gsub("\\/.*","",diff)
    packages <- paste('apt install -y ', packages, sep = "")
    vagrant_file <- readLines(con = system.file('Vagrantfile', package='reproduceR'))
    end_vagrant_file = which(vagrant_file == "  SHELL")
    for (p in 1:length(packages)){
     vagrant_file[end_vagrant_file] <- packages[p]
     end_vagrant_file = end_vagrant_file + 1
    }
    vagrant_file[end_vagrant_file] <- "  SHELL"
    vagrant_file[end_vagrant_file+1] <- "end"
    writeLines(vagrant_file, con = '~/Vagrantfile_edited')
  }
  # Create db
  lib <- c('proto', 'gsubfn', 'RSQLite', 'DBI', 'sqldf')
  lapply(lib, library, lib.loc='/usr/local/lib/R/site-library/', character.only = TRUE)
  #library(sqldf, lib.loc='/usr/local/lib/R/site-library/'); library(DBI, lib.loc='/usr/local/lib/R/site-library/')
  db <- dbConnect(SQLite(), dbname=con)
  schema_file <- system.file('db_schema.sql', package='reproduceR')
  dbSendQueries(db, sqlFromFile(schema_file))
  # Import info to db
  parserDB(db, prov_json)
  print('Finished')
}
