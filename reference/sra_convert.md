# Convert between SRA, GEO, BioSample and BioProject accessions

The successor to `SRAdb::sraConvert()` and `GEOmetadb::geoConvert()`.
Accessions of any supported type, mixed freely, are mapped to the
requested types.

## Usage

``` r
sra_convert(con, in_acc, out_type = c("study", "sample", "experiment", "run"))

geo_convert(con, in_acc, out_type = c("gse", "gpl", "gsm"))
```

## Arguments

- con:

  A connection from
  [`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
  or an
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md).

- in_acc:

  character. Accessions to convert; `in_list` in
  `GEOmetadb::geoConvert()`.

- out_type:

  character. Accession types to return.

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
con <- omicidx_connect()
sra_convert(con, "SRP000001")
#> # A tibble: 83 × 4
#>    study     sample    experiment run      
#>    <chr>     <chr>     <chr>      <chr>    
#>  1 SRP000001 SRS000100 SRX000007  SRR000001
#>  2 SRP000001 SRS000100 SRX000006  SRR000008
#>  3 SRP000001 SRS000100 SRX000003  SRR000020
#>  4 SRP000001 SRS000100 SRX000005  SRR000025
#>  5 SRP000001 SRS000605 SRX000001  SRR000026
#>  6 SRP000001 SRS000100 SRX000004  SRR000032
#>  7 SRP000001 SRS000605 SRX000001  SRR000035
#>  8 SRP000001 SRS000100 SRX000003  SRR000038
#>  9 SRP000001 SRS000605 SRX000001  SRR000045
#> 10 SRP000001 SRS000605 SRX000002  SRR000055
#> # ℹ 73 more rows
geo_convert(con, "GSE164073", c("gsm", "run"))
#> # A tibble: 72 × 3
#>    run         gse       gsm       
#>    <chr>       <chr>     <chr>     
#>  1 SRR13332242 GSE164073 GSM4996084
#>  2 SRR13332244 GSE164073 GSM4996084
#>  3 SRR13332245 GSE164073 GSM4996084
#>  4 SRR13332247 GSE164073 GSM4996085
#>  5 SRR13332248 GSE164073 GSM4996085
#>  6 SRR13332249 GSE164073 GSM4996085
#>  7 SRR13332253 GSE164073 GSM4996086
#>  8 SRR13332255 GSE164073 GSM4996087
#>  9 SRR13332265 GSE164073 GSM4996089
#> 10 SRR13332268 GSE164073 GSM4996090
#> # ℹ 62 more rows
DBI::dbDisconnect(con)
```
