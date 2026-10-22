# Search SRA studies or GEO series by text

Case-insensitive substring search (SQL `ILIKE`) over SRA study titles
and abstracts, or GEO series titles and summaries. The successor to
`SRAdb::getSRA()` for finding studies; it is a plain pattern match, not
a ranked full-text search.

## Usage

``` r
sra_search(con, query, limit = 100L)

geo_search(con, query, limit = 100L)
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md).

- query:

  character(1). Text to find. `%` matches any run of characters and `_`
  any single character, so `"single cell%glioma"` finds both phrases in
  that order.

- limit:

  integer(1). Maximum number of rows to return.

## Value

A tibble of matching studies (`sra_search()`: from `sradb.study`) or
series (`geo_search()`: from `geometadb.gse`). In `geo_search()`
results, `type`, `bioprojects` and `sra_studies` are list-columns, since
a series can have several of each; use
[`tidyr::unnest_longer()`](https://tidyr.tidyverse.org/reference/unnest_longer.html)
to get one row per value.

## Examples

``` r
con <- omicidx_connect()
sra_search(con, "single cell%glioma", limit = 5)
#> # A tibble: 5 × 7
#>   study_accession study_title              study_type study_abstract center_name
#>   <chr>           <chr>                    <chr>      <chr>          <chr>      
#> 1 ERP144083       Longitudinal scRNA-Seq … Transcrip… Longitudinal … DKTK Clini…
#> 2 SRP042161       Single cell RNA-seq of … Transcrip… We report tra… GEO        
#> 3 SRP060524       Single cell RNA-seq ana… Transcrip… To understand… GEO        
#> 4 SRP067604       Single cell transcripto… Transcrip… Radiation is … GEO        
#> 5 SRP081644       An automatec microwell … Other      We report an … GEO        
#> # ℹ 2 more variables: bioproject_accession <chr>, geo_accession <chr>
series <- geo_search(con, "glioblastoma", limit = 5)
if (requireNamespace("tidyr", quietly = TRUE)) {
    tidyr::unnest_longer(series[c("gse", "sra_studies")], "sra_studies")
}
#> # A tibble: 5 × 2
#>   gse       sra_studies
#>   <chr>     <chr>      
#> 1 GSE95386  SRP100743  
#> 2 GSE96682  SRP101987  
#> 3 GSE99180  SRP107791  
#> 4 GSE165286 SRP302777  
#> 5 GSE86511  SRP087437  
DBI::dbDisconnect(con)
```
