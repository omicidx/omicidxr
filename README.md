# omicidxr <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/omicidx/omicidxr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/omicidx/omicidxr/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![pkgdown-build](https://github.com/omicidx/omicidxr/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/omicidx/omicidxr/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

> **Access the OmicIDX omics metadata database from R**

The `omicidxr` package provides a convenient interface to query and explore the OmicIDX metadata database, a comprehensive resource for omics dataset metadata. Built on top of [DuckDB](https://duckdb.org/), it enables fast, efficient queries on large-scale genomics metadata **without downloading the entire database.**

For users of GEOmetadb and SRAdb, `omicidxr` offers a modern alternative with cloud-native access, eliminating the need to manage large local SQLite files.

Metadata coverage of over 40 million SRA experiments, 8 million GEO samples, and 50 million Biosamples, all accessible via SQL or `dplyr` syntax without any large downloads.

## ✨ Features

- 🚀 **Fast queries** powered by DuckDB's columnar engine over remote Parquet
- ☁️ **Nothing to download** – queries fetch only the columns and rows they need
- 📌 **Version pinning** – the nightly `"latest"`, a dated build, or a citable monthly release
- 🔍 **Full SQL support** plus `dplyr`/`dbplyr` integration, with tab-completion of tables
- 🧬 **SRAdb/GEOmetadb successor** – the `sradb` and `geometadb` schemas follow those packages' tables
- 📊 **Comprehensive schemas** covering SRA, GEO, BioSample and BioProject

## 📦 Installation

You can install the development version of omicidxr from GitHub:

``` r
# install.packages("pak")
pak::pak("omicidx/omicidxr")
```

Or using `remotes`:

``` r
# install.packages("remotes")
remotes::install_github("omicidx/omicidxr")
```

or using 'BiocManager':

``` r
# install.packages("BiocManager")
BiocManager::install("omicidx/omicidxr")
```

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

`omicidx_db()` returns every table as a lazy `dplyr` table, nested by
schema, so `db$sradb$<TAB>` completes table names:

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
|---|---|
| `"latest"` (default) | the nightly build at `omicidx.cancerdatasci.org/data/latest/` |
| `"YYYY-MM-DD"` | a dated nightly build, kept for 30 days |
| `"YYYY-MM"` | the monthly HuggingFace release `omicidx/omicidx@YYYY-MM`; long term and citable |

``` r
con <- omicidx_connect("2026-10")
```

Connecting to a monthly release takes about 30 seconds, since DuckDB
inspects each Parquet file while it creates the views.

## 📚 Main Functions

| Function | Description |
|----------|-------------|
| `omicidx_connect(version)` | Connect to an OmicIDX release; returns a DuckDB DBI connection |
| `omicidx_db(con)` | Lazy `dplyr` tables, nested by schema, for tab-completion |
| `omicidx_tables(con)` | List the tables in a connection |
| `omicidx_describe(con, table)` | Column names and types of a table |

## 🗄️ Database Schemas

- **`sradb`** – SRA `study`, `sample`, `experiment`, `run` and the joined `sra` table, in the shape of SRAdb's tables, plus run subsets (`human_runs`, `mouse_runs`, `rnaseq_runs`, `wgs_runs`)
- **`geometadb`** – GEO `gse`, `gsm`, `gpl`, `gse_gsm`, `gse_gpl`, in the shape of GEOmetadb's tables
- **`main`** – the base OmicIDX tables, where the release includes them (use `omicidx_tables()`)

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs** – [Open an issue](https://github.com/omicidx/omicidxr/issues) with a reproducible example
2. **Suggest features** – Share your ideas in the [issue tracker](https://github.com/omicidx/omicidxr/issues)
3. **Submit PRs** – Fork, create a feature branch, and submit a pull request
4. **Improve docs** – Help make the documentation clearer

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## 📄 License

MIT © Sean Davis

See [LICENSE.md](LICENSE.md) for full license text.

## 🙏 Acknowledgments

- [DuckDB](https://duckdb.org/) for the amazing analytical database engine
- The R community for packages like `dplyr`, `dbplyr`, and `DBI`

## 📬 Getting Help

- **Documentation**: [https://omicidx.github.io/omicidxr/](https://omicidx.github.io/omicidxr/)
- **Bug reports**: [GitHub Issues](https://github.com/omicidx/omicidxr/issues)
- **Questions**: Open a [discussion](https://github.com/omicidx/omicidx/discussions) or reach out via email