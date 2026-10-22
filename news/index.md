# Changelog

## omicidxr 0.99.0

- Bioconductor submission.
- `omicidx_connect(version)` opens a DuckDB connection to an OmicIDX
  release: `"latest"`, a dated nightly build `"YYYY-MM-DD"` or a monthly
  release `"YYYY-MM"`. Nothing is downloaded up front, and DuckDB
  extensions are cached in `tools::R_user_dir("omicidxr", "cache")`
  rather than `~/.duckdb`.
- [`omicidx_release()`](https://seandavi.github.io/omicidxr/reference/omicidx_release.md)
  reports a connection’s release and its provenance from
  `manifest.json`.
- [`omicidx_tables()`](https://seandavi.github.io/omicidxr/reference/omicidx_tables.md),
  [`omicidx_describe()`](https://seandavi.github.io/omicidxr/reference/omicidx_describe.md)
  and
  [`omicidx_db()`](https://seandavi.github.io/omicidxr/reference/omicidx_db.md)
  list, describe and wrap the release’s tables as tab-completable lazy
  `dplyr` tables.
- SRAdb and GEOmetadb successors:
  [`sra_convert()`](https://seandavi.github.io/omicidxr/reference/sra_convert.md),
  [`geo_convert()`](https://seandavi.github.io/omicidxr/reference/sra_convert.md),
  [`sra_runs()`](https://seandavi.github.io/omicidxr/reference/sra_runs.md),
  [`geo_samples()`](https://seandavi.github.io/omicidxr/reference/geo_samples.md),
  [`geo_characteristics()`](https://seandavi.github.io/omicidxr/reference/geo_characteristics.md),
  [`sra_search()`](https://seandavi.github.io/omicidxr/reference/sra_search.md)
  and
  [`geo_search()`](https://seandavi.github.io/omicidxr/reference/sra_search.md).
