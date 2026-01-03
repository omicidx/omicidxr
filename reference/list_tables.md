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
#> # A tibble: 8 × 6
#>   database schema  name                  column_names column_types temporary
#>   <chr>    <chr>   <chr>                 <list>       <list>       <lgl>    
#> 1 omicidx  sources v_src_geo_platforms   <chr [20]>   <chr [20]>   FALSE    
#> 2 omicidx  sources v_src_geo_samples     <chr [26]>   <chr [26]>   FALSE    
#> 3 omicidx  sources v_src_geo_series      <chr [26]>   <chr [26]>   FALSE    
#> 4 omicidx  sources v_src_sra_accessions  <chr [21]>   <chr [21]>   FALSE    
#> 5 omicidx  sources v_src_sra_experiments <chr [28]>   <chr [28]>   FALSE    
#> 6 omicidx  sources v_src_sra_runs        <chr [17]>   <chr [17]>   FALSE    
#> 7 omicidx  sources v_src_sra_samples     <chr [13]>   <chr [13]>   FALSE    
#> 8 omicidx  sources v_src_sra_studies     <chr [17]>   <chr [17]>   FALSE    

# Filter by schema
list_tables(con)
#> # A tibble: 8 × 6
#>   database schema  name                  column_names column_types temporary
#>   <chr>    <chr>   <chr>                 <list>       <list>       <lgl>    
#> 1 omicidx  sources v_src_geo_platforms   <chr [20]>   <chr [20]>   FALSE    
#> 2 omicidx  sources v_src_geo_samples     <chr [26]>   <chr [26]>   FALSE    
#> 3 omicidx  sources v_src_geo_series      <chr [26]>   <chr [26]>   FALSE    
#> 4 omicidx  sources v_src_sra_accessions  <chr [21]>   <chr [21]>   FALSE    
#> 5 omicidx  sources v_src_sra_experiments <chr [28]>   <chr [28]>   FALSE    
#> 6 omicidx  sources v_src_sra_runs        <chr [17]>   <chr [17]>   FALSE    
#> 7 omicidx  sources v_src_sra_samples     <chr [13]>   <chr [13]>   FALSE    
#> 8 omicidx  sources v_src_sra_studies     <chr [17]>   <chr [17]>   FALSE    
```
