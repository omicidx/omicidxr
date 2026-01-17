# Omicidx DuckDB Client (R6)

Omicidx DuckDB Client (R6)

Omicidx DuckDB Client (R6)

## Details

This is the main class for interacting with the OmicIDX data resource.
It provides methods for connecting to the Omicidx DuckDB database,
listing tables, retrieving `dplyr` table references, and executing SQL
queries.

The `OmicidxClient` class uses R6 to encapsulate the functionality for
connecting to and querying the Omicidx DuckDB database. It provides a
user-friendly interface for accessing the data stored in the database.

A typical workflow will involve:

- Creating a new OmicidxClient object using the `new()` method.

- Listing available tables using the
  [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)
  method.

- Accessing specific tables using the
  [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) method or by
  referencing tables in the `tbls` field.

If you need to execute custom SQL queries, you can use the `query()`
method.

The underlying DuckDB database is actually stored on an S3-compatible
object store, but the client abstracts away the details of connecting to
the database. The database does not need to be downloaded locally; the
data are also stored in the cloud and queried remotely via DuckDB.

If you want to persist the DuckDB instance locally (e.g., to cache query
results), you can provide a local file path when creating the
OmicidxClient object.

## Public fields

- `con`:

  A DuckDB connection object.

- `tbls`:

  A named list of lazy `dplyr` table references. Populated during
  initialization.

## Methods

### Public methods

- [`OmicidxClient$new()`](#method-OmicidxClient-new)

- [`OmicidxClient$connection()`](#method-OmicidxClient-connection)

- [`OmicidxClient$list_tables()`](#method-OmicidxClient-list_tables)

- [`OmicidxClient$table_names()`](#method-OmicidxClient-table_names)

- [`OmicidxClient$tbl()`](#method-OmicidxClient-tbl)

- [`OmicidxClient$query()`](#method-OmicidxClient-query)

- [`OmicidxClient$describe_table()`](#method-OmicidxClient-describe_table)

- [`OmicidxClient$execute()`](#method-OmicidxClient-execute)

- [`OmicidxClient$clone()`](#method-OmicidxClient-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new OmicidxClient.

#### Usage

    OmicidxClient$new(db_path = ":memory:")

#### Arguments

- `db_path`:

  character(1) Path passed to DuckDB as `dbdir`. The default is to use
  `":memory:"`.

#### Returns

A new `OmicidxClient` object.

------------------------------------------------------------------------

### Method `connection()`

Get the underlying DuckDB connection.

#### Usage

    OmicidxClient$connection()

#### Returns

A DuckDB connection object.

------------------------------------------------------------------------

### Method [`list_tables()`](https://omicidx.github.io/omicidxr/reference/list_tables.md)

List tables in the Omicidx database.

#### Usage

    OmicidxClient$list_tables(schema = NA, database = NA)

#### Arguments

- `schema`:

  character(1) Schema name to filter by. Use `NA` (default) for all
  schemas.

- `database`:

  character(1) Database name to filter by. Use `NA` (default) for all
  databases.

#### Returns

A tibble containing information about tables in the database.

------------------------------------------------------------------------

### Method `table_names()`

Get fully qualified table names as a named character vector.

#### Usage

    OmicidxClient$table_names(schema = NA, database = NA)

#### Arguments

- `schema`:

  character(1) Schema name to filter by. Use `NA` (default) for all
  schemas.

- `database`:

  character(1) Database name to filter by. Use `NA` (default) for all
  databases.

#### Returns

A named character vector of fully qualified table names.

------------------------------------------------------------------------

### Method [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)

Get a `dplyr` table reference for a specific table.

#### Usage

    OmicidxClient$tbl(table_name)

#### Arguments

- `table_name`:

  character(1) A table name (optionally schema-qualified) to reference.

#### Returns

A `dplyr` table reference.

------------------------------------------------------------------------

### Method `query()`

Execute an arbitrary SQL query (as a string) against the database.

#### Usage

    OmicidxClient$query(sql)

#### Arguments

- `sql`:

  character(1) A SQL string to execute via
  [`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html).

#### Returns

A data frame containing the query result.

------------------------------------------------------------------------

### Method `describe_table()`

Describe the schema of a specific table using the duckdb DESCRIBE
command.

#### Usage

    OmicidxClient$describe_table(table_name)

#### Arguments

- `table_name`:

  character(1) A table name (optionally schema-qualified) to describe.

#### Returns

A data frame containing the table schema.

------------------------------------------------------------------------

### Method `execute()`

Execute a SQL command against the database.

#### Usage

    OmicidxClient$execute(sql)

#### Arguments

- `sql`:

  character(1) A SQL string to execute via
  [`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html).

#### Returns

An integer indicating the number of rows affected.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    OmicidxClient$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
oidx <- OmicidxClient$new()
oidx$list_tables()
#> # A tibble: 36 × 6
#>    database schema    name                   column_names column_types temporary
#>    <chr>    <chr>     <chr>                  <list>       <list>       <lgl>    
#>  1 omicidx  geometadb geo_supplemental_files <chr [4]>    <chr [4]>    FALSE    
#>  2 omicidx  geometadb gpl                    <chr [15]>   <chr [15]>   FALSE    
#>  3 omicidx  geometadb gse                    <chr [20]>   <chr [20]>   FALSE    
#>  4 omicidx  geometadb gse_gpl                <chr [2]>    <chr [2]>    FALSE    
#>  5 omicidx  geometadb gse_gsm                <chr [2]>    <chr [2]>    FALSE    
#>  6 omicidx  geometadb gsm                    <chr [31]>   <chr [31]>   FALSE    
#>  7 omicidx  main      src_bioprojects        <chr [9]>    <chr [9]>    FALSE    
#>  8 omicidx  main      src_biosamples         <chr [19]>   <chr [19]>   FALSE    
#>  9 omicidx  main      src_geo_platforms      <chr [20]>   <chr [20]>   FALSE    
#> 10 omicidx  main      src_geo_samples        <chr [26]>   <chr [26]>   FALSE    
#> # ℹ 26 more rows
# tbl_ref <- oidx$tbl("some_table")
# oidx$query("SELECT * FROM some_table LIMIT 5")

# Get all table names
oidx$table_names()
#>         geometadb.geo_supplemental_files 
#>       "geometadb.geo_supplemental_files" 
#>                            geometadb.gpl 
#>                          "geometadb.gpl" 
#>                            geometadb.gse 
#>                          "geometadb.gse" 
#>                        geometadb.gse_gpl 
#>                      "geometadb.gse_gpl" 
#>                        geometadb.gse_gsm 
#>                      "geometadb.gse_gsm" 
#>                            geometadb.gsm 
#>                          "geometadb.gsm" 
#>                     main.src_bioprojects 
#>                   "main.src_bioprojects" 
#>                      main.src_biosamples 
#>                    "main.src_biosamples" 
#>                   main.src_geo_platforms 
#>                 "main.src_geo_platforms" 
#>                     main.src_geo_samples 
#>                   "main.src_geo_samples" 
#>                      main.src_geo_series 
#>                    "main.src_geo_series" 
#>   main.src_geo_series_with_rnaseq_counts 
#> "main.src_geo_series_with_rnaseq_counts" 
#>                  main.src_sra_accessions 
#>                "main.src_sra_accessions" 
#>                 main.src_sra_experiments 
#>               "main.src_sra_experiments" 
#>                        main.src_sra_runs 
#>                      "main.src_sra_runs" 
#>                     main.src_sra_samples 
#>                   "main.src_sra_samples" 
#>                     main.src_sra_studies 
#>                   "main.src_sra_studies" 
#>                     main.stg_bioprojects 
#>                   "main.stg_bioprojects" 
#>                      main.stg_biosamples 
#>                    "main.stg_biosamples" 
#>                   main.stg_geo_platforms 
#>                 "main.stg_geo_platforms" 
#>                     main.stg_geo_samples 
#>                   "main.stg_geo_samples" 
#>                      main.stg_geo_series 
#>                    "main.stg_geo_series" 
#>                 main.stg_sra_experiments 
#>               "main.stg_sra_experiments" 
#>                        main.stg_sra_runs 
#>                      "main.stg_sra_runs" 
#>                     main.stg_sra_samples 
#>                   "main.stg_sra_samples" 
#>                     main.stg_sra_studies 
#>                   "main.stg_sra_studies" 
#>                         sradb.experiment 
#>                       "sradb.experiment" 
#>                         sradb.human_runs 
#>                       "sradb.human_runs" 
#>                         sradb.mouse_runs 
#>                       "sradb.mouse_runs" 
#>                        sradb.rnaseq_runs 
#>                      "sradb.rnaseq_runs" 
#>                                sradb.run 
#>                              "sradb.run" 
#>                     sradb.run_with_study 
#>                   "sradb.run_with_study" 
#>                             sradb.sample 
#>                           "sradb.sample" 
#>                                sradb.sra 
#>                              "sradb.sra" 
#>                              sradb.study 
#>                            "sradb.study" 
#>                           sradb.wgs_runs 
#>                         "sradb.wgs_runs" 

# Get a description of a specific table
# This is the table "schema"
oidx$describe_table("stg_sra_studies")
#>             column_name                                           column_type
#> 1             accession                                               VARCHAR
#> 2                 alias                                               VARCHAR
#> 3                 title                                               VARCHAR
#> 4           description                                               VARCHAR
#> 5              abstract                                               VARCHAR
#> 6            study_type                                               VARCHAR
#> 7           center_name                                               VARCHAR
#> 8           broker_name                                               VARCHAR
#> 9  bioproject_accession                                               VARCHAR
#> 10        geo_accession                                               VARCHAR
#> 11          identifiers STRUCT(namespace VARCHAR, id VARCHAR, uuid VARCHAR)[]
#> 12           attributes                STRUCT(tag VARCHAR, "value" VARCHAR)[]
#> 13                xrefs                      STRUCT(db VARCHAR, id VARCHAR)[]
#> 14           pubmed_ids                                             VARCHAR[]
#>    null  key default extra
#> 1   YES <NA>    <NA>  <NA>
#> 2   YES <NA>    <NA>  <NA>
#> 3   YES <NA>    <NA>  <NA>
#> 4   YES <NA>    <NA>  <NA>
#> 5   YES <NA>    <NA>  <NA>
#> 6   YES <NA>    <NA>  <NA>
#> 7   YES <NA>    <NA>  <NA>
#> 8   YES <NA>    <NA>  <NA>
#> 9   YES <NA>    <NA>  <NA>
#> 10  YES <NA>    <NA>  <NA>
#> 11  YES <NA>    <NA>  <NA>
#> 12  YES <NA>    <NA>  <NA>
#> 13  YES <NA>    <NA>  <NA>
#> 14  YES <NA>    <NA>  <NA>

# create a table of SRA runs published per year
geo_series_by_year <- oidx$tbl('src_geo_series') |>
 dplyr::mutate(year = dplyr::sql("EXTRACT(YEAR FROM submission_date)")) |>
 dplyr::group_by(year) |>
 dplyr::summarise(count = dplyr::n())

# The result is a lazy dplyr table
geo_series_by_year
#> # Source:   SQL [?? x 2]
#> # Database: DuckDB 1.4.3 [unknown@Linux 6.11.0-1018-azure:R 4.5.2/:memory:]
#>     year count
#>    <dbl> <dbl>
#>  1  2001    14
#>  2  2002   124
#>  3  2003   671
#>  4  2004   986
#>  5  2005  1534
#>  6  2006  2391
#>  7  2007  3172
#>  8  2008  3706
#>  9  2009  5067
#> 10  2010  6401
#> # ℹ more rows

# use it just like any other dplyr table

if (requireNamespace("ggplot2", quietly = TRUE)) {
geo_series_by_year |> 
 ggplot2::ggplot(ggplot2::aes(x = year, y = count)) +
 ggplot2::geom_bar(stat="identity") +
 ggplot2::theme_minimal()
}


# or get the data as a data frame
geo_series_by_year_df <- geo_series_by_year |> dplyr::collect()
head(geo_series_by_year_df)
#> # A tibble: 6 × 2
#>    year count
#>   <dbl> <dbl>
#> 1  2001    14
#> 2  2002   124
#> 3  2003   671
#> 4  2004   986
#> 5  2005  1534
#> 6  2006  2391
```
