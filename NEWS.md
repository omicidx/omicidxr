# omicidxr 0.99.0

* Bioconductor submission.
* `omicidx_connect(version)` opens a DuckDB connection to an OmicIDX
  release: `"latest"`, a dated nightly build `"YYYY-MM-DD"` or a monthly
  release `"YYYY-MM"`. Nothing is downloaded up front, and DuckDB
  extensions are cached in `tools::R_user_dir("omicidxr", "cache")`
  rather than `~/.duckdb`.
* `omicidx_release()` reports a connection's release and its provenance
  from `manifest.json`.
* `omicidx_tables()`, `omicidx_describe()` and `omicidx_db()` list,
  describe and wrap the release's tables as tab-completable lazy `dplyr`
  tables.
* SRAdb and GEOmetadb successors: `sra_convert()`, `geo_convert()`,
  `sra_runs()`, `geo_samples()`, `geo_characteristics()`,
  `sra_search()` and `geo_search()`.
