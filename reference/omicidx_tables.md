# List the tables in an OmicIDX connection

List the tables in an OmicIDX connection

## Usage

``` r
omicidx_tables(con)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md)
  object.

## Value

A tibble with columns `schema`, `table` and `type` (`"VIEW"` or
`"BASE TABLE"`), one row per table.

## Examples

``` r
con <- omicidx_connect()
omicidx_tables(con)
#> # A tibble: 17 × 3
#>    schema    table                  type      
#>    <chr>     <chr>                  <chr>     
#>  1 geometadb geo_supplemental_files VIEW      
#>  2 geometadb gpl                    VIEW      
#>  3 geometadb gse                    VIEW      
#>  4 geometadb gse_gpl                VIEW      
#>  5 geometadb gse_gsm                VIEW      
#>  6 geometadb gsm                    VIEW      
#>  7 main      db_creation_metadata   BASE TABLE
#>  8 sradb     experiment             VIEW      
#>  9 sradb     human_runs             VIEW      
#> 10 sradb     mouse_runs             VIEW      
#> 11 sradb     rnaseq_runs            VIEW      
#> 12 sradb     run                    VIEW      
#> 13 sradb     run_with_study         VIEW      
#> 14 sradb     sample                 VIEW      
#> 15 sradb     sra                    VIEW      
#> 16 sradb     study                  VIEW      
#> 17 sradb     wgs_runs               VIEW      
DBI::dbDisconnect(con)
```
