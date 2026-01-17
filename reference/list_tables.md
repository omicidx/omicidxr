# List Tables in a DuckDB Connection

Retrieves a list of all tables available in a DuckDB connection, with
optional filtering by database and/or schema.

## Usage

``` r
list_tables(con, database = NA, schema = NA)
```

## Arguments

- con:

  A DuckDB database connection object created by
  [`connect_omicidx()`](https://omicidx.github.io/omicidxr/reference/connect_omicidx.md).

- database:

  A character string specifying the database name to filter by. If `NA`
  (default), all databases are included.

- schema:

  A character string specifying the schema name to filter by. If `NA`
  (default), all schemas are included.

## Value

A tibble containing information about tables in the database, with
columns for database, schema, table name, and other metadata.

## Examples

``` r
con <- connect_omicidx()
# List all tables
list_tables(con)
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

# Filter by schema
list_tables(con)
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
```
