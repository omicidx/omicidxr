# List the tables in an OmicIDX connection

List the tables in an OmicIDX connection

## Usage

``` r
omicidx_tables(con)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
  object.

## Value

A tibble with columns `schema`, `table` and `type` (`"VIEW"` or
`"BASE TABLE"`), one row per table.

## Examples

``` r
con <- omicidx_connect()
omicidx_tables(con)
#> # A tibble: 29 × 3
#>    schema    table                  type      
#>    <chr>     <chr>                  <chr>     
#>  1 geometadb geo_supplemental_files VIEW      
#>  2 geometadb gpl                    VIEW      
#>  3 geometadb gse                    VIEW      
#>  4 geometadb gse_gpl                VIEW      
#>  5 geometadb gse_gsm                VIEW      
#>  6 geometadb gsm                    VIEW      
#>  7 main      bioprojects            VIEW      
#>  8 main      biosamples             VIEW      
#>  9 main      db_creation_metadata   BASE TABLE
#> 10 main      geo_platforms          VIEW      
#> # ℹ 19 more rows
DBI::dbDisconnect(con)
```
