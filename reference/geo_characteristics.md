# Characteristics of GEO samples

The `characteristics_ch1` and `characteristics_ch2` tag/value pairs of
each sample, one row per pair. In GEOmetadb these were one
`;\t`-separated string per channel.

## Usage

``` r
geo_characteristics(con, gsm)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md).

- gsm:

  character. GEO sample accessions.

## Value

A tibble with columns `gsm`, `channel` (1 or 2), `tag` and `value`.

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
geo_characteristics(con, c("GSM4996084", "GSM4996085"))
#> # A tibble: 6 × 4
#>   gsm        channel tag        value   
#>   <chr>        <int> <chr>      <chr>   
#> 1 GSM4996084       1 tissue     cornea  
#> 2 GSM4996084       1 infection  mock    
#> 3 GSM4996084       1 time point 24 hours
#> 4 GSM4996085       1 tissue     cornea  
#> 5 GSM4996085       1 infection  mock    
#> 6 GSM4996085       1 time point 24 hours
DBI::dbDisconnect(con)
# }
```
