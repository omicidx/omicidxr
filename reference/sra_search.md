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
series (`geo_search()`: from `geometadb.gse`).

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
geo_search(con, "glioblastoma", limit = 5)
#> # A tibble: 5 × 7
#>   gse       title          type  submission_date summary bioprojects sra_studies
#>   <chr>     <chr>          <lis> <date>          <chr>   <list>      <list>     
#> 1 GSE95386  TRIM24 is an … <chr> 2017-02-27      "Aberr… <chr [1]>   <chr [1]>  
#> 2 GSE96682  Prospective I… <chr> 2017-03-16      "Chara… <chr [1]>   <chr [1]>  
#> 3 GSE99180  CD133hi, Notc… <chr> 2017-05-22      "CD133… <chr [1]>   <chr [1]>  
#> 4 GSE165286 MicroRNA-138 … <chr> 2021-01-21      "Micro… <chr [1]>   <chr [1]>  
#> 5 GSE86511  Genome-wide c… <chr> 2016-09-07      "MYC d… <chr [1]>   <chr [1]>  
DBI::dbDisconnect(con)
# }
```
