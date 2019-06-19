#' Functions to create the provenance database
#'
#' This contains the necessary functions to create the database file based on
#' the model decribed on db_schema.sql
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
