# Describe the columns of an OmicIDX table

Describe the columns of an OmicIDX table

## Usage

``` r
omicidx_describe(con, table)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md)
  object.

- table:

  character(1). A table name, schema-qualified as in `"sradb.study"`.
  Unqualified names are looked up in `main`.

## Value

A tibble with one row per column: `column_name`, `column_type` and
`null` (whether the column may hold `NULL`s).

## Examples

``` r
# \donttest{
con <- omicidx_connect()
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpl0TUWk/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
omicidx_describe(con, "sradb.study")
#> # A tibble: 14 × 3
#>    column_name          column_type null 
#>    <chr>                <chr>       <chr>
#>  1 study_id             BIGINT      YES  
#>  2 study_alias          VARCHAR     YES  
#>  3 study_accession      VARCHAR     YES  
#>  4 study_title          VARCHAR     YES  
#>  5 study_type           VARCHAR     YES  
#>  6 study_abstract       VARCHAR     YES  
#>  7 broker_name          VARCHAR     YES  
#>  8 center_name          VARCHAR     YES  
#>  9 center_project_name  VARCHAR     YES  
#> 10 study_description    VARCHAR     YES  
#> 11 study_attribute      VARCHAR     YES  
#> 12 bioproject_accession VARCHAR     YES  
#> 13 geo_accession        VARCHAR     YES  
#> 14 pubmed_ids           VARCHAR[]   YES  
DBI::dbDisconnect(con)
# }
```
