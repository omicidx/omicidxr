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
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md).

- gsm:

  character. GEO sample accessions.

## Value

A tibble with columns `gsm`, `channel` (1 or 2), `tag` and `value`.

## Examples

``` r
con <- omicidx_connect()
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
```
