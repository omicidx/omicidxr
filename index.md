# omicidxr ![](reference/figures/logo.png)

> **Access the OmicIDX omics metadata database from R**

The `omicidxr` package provides a convenient interface to query and
explore the OmicIDX metadata database, a comprehensive resource for
omics dataset metadata. Built on top of [DuckDB](https://duckdb.org/),
it enables fast, efficient queries on large-scale genomics metadata
**without downloading the entire database.**

For users of GEOmetadb and SRAdb, `omicidxr` offers a modern alternative
with cloud-native access, eliminating the need to manage large local
SQLite files.

Metadata coverage of over 40 million SRA experiments, 8 million GEO
samples, and 50 million Biosamples, all accessible via SQL or `dplyr`
syntax without any large downloads.

## ✨ Features

- 🚀 **Fast queries** powered by DuckDB’s columnar engine over remote
  Parquet
- ☁️ **Nothing to download** – queries fetch only the columns and rows
  they need
- 📌 **Version pinning** – the nightly `"latest"`, a dated build, or a
  citable monthly release
- 🔍 **Full SQL support** plus `dplyr`/`dbplyr` integration, with
  tab-completion of tables
- 🧬 **SRAdb/GEOmetadb successor** – the `sradb` and `geometadb` schemas
  follow those packages’ tables
- 📊 **Comprehensive schemas** covering SRA, GEO, BioSample and
  BioProject

## 📦 Installation

Install the development version from GitHub with `pak`:

``` r

install.packages("pak")
pak::pak("seandavi/omicidxr")
```

omicidxr needs the `duckdb` package. CRAN has `duckdb` binaries for
Windows and macOS; on Linux it compiles from source, which can take 20
minutes or more, unless your repository serves Linux binaries (for
example [Posit Public Package
Manager](https://packagemanager.posit.co/)).

## 🚀 Quick Start

``` r

library(omicidxr)

# Connect to the nightly build. A connection is a plain DuckDB DBI connection.
con <- omicidx_connect()

# What is there?
omicidx_tables(con)
omicidx_describe(con, "sradb.study")

# SQL
DBI::dbGetQuery(con, "
  SELECT study_type, count(*) AS n
  FROM sradb.study
  GROUP BY study_type
  ORDER BY n DESC
  LIMIT 5")

DBI::dbDisconnect(con)
```

### Tab-completable `dplyr` tables

[`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
returns every table as a lazy `dplyr` table, nested by schema, so
`db$sradb$<TAB>` completes table names:

``` r

db <- omicidx_db()
db                         # schemas, tables and row counts

db$sradb$experiment |>
  dplyr::filter(library_strategy == "RNA-Seq") |>
  dplyr::count(platform, sort = TRUE) |>
  dplyr::collect()

con <- attr(db, "con")     # the DBI connection behind it
```

### Choosing a version

| `version` | Source |
|----|----|
| `"latest"` (default) | the nightly build at `omicidx.cancerdatasci.org/data/latest/` |
| `"YYYY-MM-DD"` | a dated nightly build, kept for 30 days |
| `"YYYY-MM"` | the monthly HuggingFace release `seandavis/omicidx@YYYY-MM`; long term and citable |

Query `"latest"` and dated builds in place; they are served without rate
limits. Monthly releases are the archive: HuggingFace limits anonymous
requests to 3000 per 5 minutes per IP address, and a query can make
hundreds, so querying one in place fails with HTTP 429 under heavy use.
Copy a monthly release to a local DuckDB file instead (the copy waits
out the rate limit) and query that. A whole release is about 75 GB of
Parquet and a DuckDB file about 5 times larger, so copy only the tables
you need, such as the `geometadb` marts (about 4 GB of Parquet):

``` r

path <- omicidx_download(
    "2026-10", "omicidx-geometadb-2026-10.duckdb", tables = "geometadb"
)
con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
```

Setting `HF_TOKEN` to a HuggingFace access token raises the limit. On a
connection from
[`omicidx_connect()`](https://seandavi.github.io/omicidxr/reference/omicidx_connect.md),
`omicidx_release(con)` reports the `publish_date`, `transform_sha` and
`lake_snapshot_id` to cite.

## 📚 Main Functions

| Function | Description |
|----|----|
| `omicidx_connect(version)` | Connect to an OmicIDX release; returns a DuckDB DBI connection |
| `omicidx_release(con)` | The release a connection is on: version, publish date, build provenance, row counts |
| `omicidx_db(con)` | Lazy `dplyr` tables, nested by schema, for tab-completion |
| `omicidx_tables(con)` | List the tables in a connection |
| `omicidx_describe(con, table)` | Column names and types of a table |

### SRAdb and GEOmetadb helpers

| Function | Description | Replaces |
|----|----|----|
| `sra_convert(con, in_acc, out_type)` | Convert between SRA, GEO, BioSample and BioProject accessions | `SRAdb::sraConvert()` |
| `geo_convert(con, in_acc, out_type)` | The same, defaulting to GEO output types | `GEOmetadb::geoConvert()` |
| `sra_runs(con, in_acc)` | Runs, with download fields, for studies, experiments, samples or GSEs | `SRAdb::getSRAinfo()`; `listSRAfile()` (gives run accessions for the SRA Toolkit’s `prefetch`/`fasterq-dump`; file URLs are out of scope) |
| `geo_samples(con, gse)` | Samples and platforms of GEO series | joins of `gse_gsm`, `gsm`, `gpl` |
| `geo_characteristics(con, gsm)` | Sample characteristics as tag/value rows | parsing `characteristics_ch1` |
| `sra_search(con, query)`, `geo_search(con, query)` | `ILIKE` search of study and series titles and abstracts | `SRAdb::getSRA()` |

``` r

con <- omicidx_connect()
sra_convert(con, "GSM4996084", c("gse", "study", "run"))
sra_runs(con, "GSE164073")
geo_characteristics(con, "GSM4996084")
```

Migrating from SRAdb or GEOmetadb? See the “Migrating” section of the
[Getting Started
vignette](https://seandavi.github.io/omicidxr/articles/introduction.html).

## 🗄️ Database Schemas

- **`sradb`** – SRA `study`, `sample`, `experiment`, `run` and the
  joined `sra` table, in the shape of SRAdb’s tables, plus run subsets
  (`human_runs`, `mouse_runs`, `rnaseq_runs`, `wgs_runs`)
- **`geometadb`** – GEO `gse`, `gsm`, `gpl`, `gse_gsm`, `gse_gpl`, in
  the shape of GEOmetadb’s tables
- **`main`** – the base OmicIDX tables, where the release includes them
  (use
  [`omicidx_tables()`](https://seandavi.github.io/omicidxr/reference/omicidx_tables.md))

## 🤝 Contributing

Contributions are welcome! Here’s how you can help:

1.  **Report bugs** – [Open an
    issue](https://github.com/seandavi/omicidxr/issues) with a
    reproducible example
2.  **Suggest features** – Share your ideas in the [issue
    tracker](https://github.com/seandavi/omicidxr/issues)
3.  **Submit PRs** – Fork, create a feature branch, and submit a pull
    request
4.  **Improve docs** – Help make the documentation clearer

Please note that this project is released with a [Contributor Code of
Conduct](https://seandavi.github.io/omicidxr/CODE_OF_CONDUCT.md). By
participating in this project you agree to abide by its terms.

## 📄 License

MIT © Sean Davis

See [LICENSE.md](https://seandavi.github.io/omicidxr/LICENSE.md) for
full license text.

## 🙏 Acknowledgments

- [DuckDB](https://duckdb.org/) for the amazing analytical database
  engine
- The R community for packages like `dplyr`, `dbplyr`, and `DBI`

## 📬 Getting Help

- **Documentation**: <https://seandavi.github.io/omicidxr/>
- **Bug reports**: [GitHub
  Issues](https://github.com/seandavi/omicidxr/issues)
- **Questions**: Open a
  [discussion](https://github.com/seandavi/omicidx/discussions) or reach
  out via email
