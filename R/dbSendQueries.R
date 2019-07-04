#' Function to send sql queries to the provenance database
#'
#' This contains the function to send sql queries to create
#' the provenance database on the model decribed on db_schema.sql.
#' @param con Connection to the provenance database
#' @param sql SQL query
#' @keywords database, sql, creation
#' @export

dbSendQueries <- function(con, sql){
  send <- function(sql, con){ DBI::dbSendQuery(con,sql) }
  lapply(sql, send, con)
}
