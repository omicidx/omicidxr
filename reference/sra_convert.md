# Convert between SRA, GEO, BioSample and BioProject accessions

The successor to `SRAdb::sraConvert()` and `GEOmetadb::geoConvert()`.
Accessions of any supported type, mixed freely, are mapped to the
requested types.

## Usage

``` r
sra_convert(con, in_acc, out_type = c("study", "sample", "experiment", "run"))

geo_convert(con, in_list, out_type = c("gse", "gpl", "gsm"))
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://omicidx.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://omicidx.github.io/omicidxr/reference/omicidx_db.md).

- in_acc:

  character. Accessions to convert.

- out_type:

  character. Accession types to return.

- in_list:

  character. Accessions to convert, as in `GEOmetadb::geoConvert()`.

## Value

A tibble with one column per input type present and per `out_type`, with
one row per distinct combination. `NA` where an accession has no link of
that type.

## Details

Supported types: SRA `study` (SRP/ERP/DRP), `sample` (SRS/ERS/DRS),
`experiment` (SRX/ERX/DRX) and `run` (SRR/ERR/DRR); `biosample`
(SAMN/SAMEA/SAMD); `bioproject` (PRJNA/PRJEB/PRJDB); and GEO `gse`,
`gsm` and `gpl`. SRA accessions are linked through runs (`sradb.sra`),
so experiments without runs are not found, and GEO samples link to SRA
through their SRA experiment. Converting a GPL returns every sample on
that platform, which can be large.

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
sra_convert(con, "SRP000001")
#> # A tibble: 83 × 4
#>    study     sample    experiment run      
#>    <chr>     <chr>     <chr>      <chr>    
#>  1 SRP000001 SRS000100 SRX000007  SRR000001
#>  2 SRP000001 SRS000100 SRX000006  SRR000002
#>  3 SRP000001 SRS000605 SRX000002  SRR000004
#>  4 SRP000001 SRS000100 SRX000004  SRR000006
#>  5 SRP000001 SRS000100 SRX000006  SRR000008
#>  6 SRP000001 SRS000605 SRX000002  SRR000017
#>  7 SRP000001 SRS000100 SRX000003  SRR000020
#>  8 SRP000001 SRS000100 SRX000006  SRR000022
#>  9 SRP000001 SRS000605 SRX000002  SRR000023
#> 10 SRP000001 SRS000100 SRX000005  SRR000025
#> # ℹ 73 more rows
geo_convert(con, "GSE164073", c("gsm", "run"))
#> # A tibble: 72 × 3
#>    run         gse       gsm       
#>    <chr>       <chr>     <chr>     
#>  1 SRR13332242 GSE164073 GSM4996084
#>  2 SRR13332243 GSE164073 GSM4996084
#>  3 SRR13332244 GSE164073 GSM4996084
#>  4 SRR13332245 GSE164073 GSM4996084
#>  5 SRR13332247 GSE164073 GSM4996085
#>  6 SRR13332248 GSE164073 GSM4996085
#>  7 SRR13332249 GSE164073 GSM4996085
#>  8 SRR13332250 GSE164073 GSM4996086
#>  9 SRR13332252 GSE164073 GSM4996086
#> 10 SRR13332253 GSE164073 GSM4996086
#> # ℹ 62 more rows
DBI::dbDisconnect(con)
# }
```
