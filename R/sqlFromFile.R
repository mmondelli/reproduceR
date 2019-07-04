#' Function to read sql from file
#'
#' This contains the function that will read the sql file
#' with instructions to create the database and split into
#' various sql instructions. (DBI::dbSendQuery() does not accept multiple instructions)
#' @param con Connection to the provenance database
#' @param file File with the schema definition (sql file)
#' @keywords database, sql, creation
#' @export

sqlFromFile <- function(file){
  require(stringr)
  sql <- readLines(file)
  sql <- unlist(str_split(paste(sql, collapse=" "),";"))
  sql <- sql[grep("^ *$", sql, invert=T)]
}
