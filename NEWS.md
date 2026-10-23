# omicidxr 0.99.0

* Bioconductor submission.
* Network reads are bounded: `omicidx_connect()` sets DuckDB's
  `http_timeout` (30 s) and retries each request up to 4 times with
  backoff, including on HTTP 429, and a failed connect names the release
  URL and suggests what to do (#16). `omicidx_download()` retries for up
  to 6 minutes so a copy of a monthly release waits out HuggingFace's
  rate limit.
* Monthly releases use `HF_TOKEN`, if set, for HuggingFace's higher
  signed-in rate limit. `?omicidx_connect`, the README and the vignette
  recommend querying `"latest"` or dated builds in place and downloading
  monthly releases with `omicidx_download()`.
* The vignette and tests use `"latest"` rather than HuggingFace, so
  builds do not fail on HuggingFace's rate limit.
* `omicidx_connect(version)` opens a DuckDB connection to an OmicIDX
  release: `"latest"`, a dated nightly build `"YYYY-MM-DD"` or a monthly
  release `"YYYY-MM"`. Nothing is downloaded up front, and DuckDB
  extensions are cached in `tools::R_user_dir("omicidxr", "cache")`
  rather than `~/.duckdb`.
* `omicidx_release()` reports a connection's release and its provenance
  from `manifest.json`.
* `omicidx_download(version, path, tables)` copies a release, or only the
  chosen tables or schemas, into a local DuckDB file for offline use,
  checked against `manifest.json` row counts. It reports the size of the
  Parquet it will read before it starts.
* `omicidx_tables()`, `omicidx_describe()` and `omicidx_db()` list,
  describe and wrap the release's tables as tab-completable lazy `dplyr`
  tables.
* SRAdb and GEOmetadb successors: `sra_convert()`, `geo_convert()`,
  `sra_runs()`, `geo_samples()`, `geo_characteristics()`,
  `sra_search()` and `geo_search()`.
