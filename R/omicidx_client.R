#' List Tables in a DuckDB Connection
#'
#' Retrieves a list of all tables available in a DuckDB connection,
#' with optional filtering by database and/or schema.
#'
#' @importFrom DBI dbGetQuery
#' @importFrom tibble as_tibble
#' @importFrom dplyr filter
#'
#' @param con A DuckDB database connection object
#'   created by [omicidx_connect()].
#' @param database A character string specifying the database name to filter by.
#'   If `NA` (default), all databases are included.
#' @param schema A character string specifying the schema name to filter by.
#'   If `NA` (default), all schemas are included.
#'
#' @return A tibble containing information about tables in the database,
#'   with columns for database, schema, table name, and other metadata.
#'
#' @examples
#' con <- omicidx_connect()
#' # List all tables
#' list_tables(con)
#'
#' # Filter by schema
#' list_tables(con)
#'
#' @export
list_tables <- function(con, database = NA, schema = NA) {
  tbls <- tibble::as_tibble(DBI::dbGetQuery(con, "SHOW ALL TABLES;"))
  if (!is.na(database)) {
    tbls <- tbls |> dplyr::filter(database == database)
  }
  if (!is.na(schema)) {
    tbls <- tbls |> dplyr::filter(schema == schema)
  }

  tbls
}




#' Omicidx DuckDB Client (R6)
#' 
#' This is the main class for interacting with the OmicIDX data resource.
#' It provides methods for connecting to the Omicidx DuckDB database,
#' listing tables, retrieving `dplyr` table references, 
#' and executing SQL queries.
#'
#' @importFrom R6 R6Class
#' @importFrom DBI dbGetQuery dbExecute dbDisconnect
#' @importFrom tibble as_tibble
#' @import duckdb
#' @import dbplyr
#' @details 
#' The `OmicidxClient` class uses R6 to encapsulate
#' the functionality for connecting to and querying the Omicidx
#' DuckDB database. It provides a user-friendly interface for
#' accessing the data stored in the database.
#' 
#' A typical workflow will involve:
#' 
#' - Creating a new OmicidxClient object using the `new()` method.
#' - Listing available tables using the `list_tables()` method.
#' - Accessing specific tables using the `tbl()` method or by referencing tables
#'   in the `tbls` field.
#' 
#' If you need to execute custom SQL queries, you can use the `query()`
#' method.
#' 
#' The underlying DuckDB database is actually stored on an S3-compatible
#' object store, but the client abstracts away the details of connecting
#' to the database. The database does not need to be downloaded locally;
#' the data are also stored in the cloud and queried remotely via DuckDB.
#' 
#' @examples
#' oidx <- OmicidxClient$new()
#' oidx$list_tables()
#' # tbl_ref <- oidx$tbl("some_table")
#' # oidx$query("SELECT * FROM some_table LIMIT 5")
#' 
#' # Get all table names
#' oidx$table_names()
#' 
#' # Get a description of a specific table
#' # This is the table "schema"
#' oidx$describe_table("stg_sra_studies")
#' 
#' # create a table of SRA runs published per year
#' geo_series_by_year <- oidx$tbl('src_geo_series') |>
#'  dplyr::mutate(year = dplyr::sql("EXTRACT(YEAR FROM submission_date)")) |>
#'  dplyr::group_by(year) |>
#'  dplyr::summarise(count = dplyr::n())
#' 
#' # The result is a lazy dplyr table
#' geo_series_by_year
#' 
#' # use it just like any other dplyr table
#' 
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#' geo_series_by_year |> 
#'  ggplot2::ggplot(ggplot2::aes(x = year, y = count)) +
#'  ggplot2::geom_bar(stat="identity") +
#'  ggplot2::theme_minimal()
#' }
#' 
#' # or get the data as a data frame
#' geo_series_by_year_df <- geo_series_by_year |> dplyr::collect()
#' head(geo_series_by_year_df)
#'
#' @export
OmicidxClient <- R6::R6Class(
  "OmicidxClient",
  public = list(
    #'@field con A DuckDB connection object.
    con = NULL,

    #' @field tbls A named list of lazy `dplyr` table references.
    #' Populated during initialization.
    tbls = NULL,
    
    #' @description
    #' Create a new OmicidxClient.
    #' @return A new `OmicidxClient` object.
    #'
    #' @param version character(1) OmicIDX release; see [omicidx_connect()].
    initialize = function(version = "latest") {
      self$con <- omicidx_connect(version)
      self$tbls <- list()
    },

    #' @description
    #' Get the underlying DuckDB connection.
    #' @return A DuckDB connection object.
    connection = function() {
      self$con
    },

    #' @description
    #' List tables in the Omicidx database.
    #'
    #' @return A tibble containing information about tables in the database.
    #' @param schema character(1) Schema name to filter by. Use `NA` (default)
    #' for all schemas.
    #' @param database character(1) Database name to filter by. Use `NA`
    #' (default) for all databases.
    list_tables = function(schema = NA, database = NA) {
      list_tables(self$con, database, schema)
    },


    #' @description
    #' Get fully qualified table names as a named character vector.
    #' 
    #' @return A named character vector of fully qualified table names.
    #' @param schema character(1) Schema name to filter by. Use `NA` (default)
    #' for all schemas.
    #' @param database character(1) Database name to filter by. Use `NA`
    #' (default) for all databases.
    table_names = function(schema = NA, database = NA) {
      tbls <- self$list_tables(schema, database)
      vec <- paste(tbls$schema, tbls$name, sep = ".")
      names(vec) <- vec
      vec
    },

    #' @description
    #' Get a `dplyr` table reference for a specific table.
    #'
    #' @return A `dplyr` table reference.
    #' @param table_name character(1) A table name (optionally schema-qualified)
    #' to reference.
    tbl = function(table_name) {
      if (missing(table_name)) {
        stop("table_name is required")
      }
      if (table_name %in% self$tbls) {
        return(self$tbls[[table_name]])
      }
      self$tbls[[table_name]] <- dplyr::tbl(self$con, table_name)
      return (self$tbls[[table_name]])
    },

    #' @description
    #' Execute an arbitrary SQL query (as a string) against the database.
    #' @return A data frame containing the query result.
    #' @param sql character(1) A SQL string to execute via [DBI::dbGetQuery()].
    query = function(sql) {
      DBI::dbGetQuery(self$con, sql)
    },

    #' @description
    #' Describe the schema of a specific table 
    #' using the duckdb DESCRIBE command.
    #' 
    #' @return A data frame containing the table schema.
    #' @param table_name character(1) A table name 
    #' (optionally schema-qualified)
    #' to describe.
    describe_table = function(table_name) {
      if (missing(table_name)) {
        stop("table_name is required")
      }
      self$query(paste0("DESCRIBE ", table_name, ";"))
    },

    #' @description
    #' Execute a SQL command against the database.
    #'
    #' @param sql character(1) A SQL string to execute via [DBI::dbExecute()].
    #' @return An integer indicating the number of rows affected.
    execute = function(sql) {
      DBI::dbExecute(self$con, sql)
    }
  ),

  private = list(
    finalize = function() {
      DBI::dbDisconnect(self$con, shutdown = TRUE)
    }
  )
)
