# Deferred Notes & Future Work

Things surfaced during the build that are **intentionally not being acted on now**. Captured so they
aren't forgotten.

## Not our data to clean (flag to owners, don't fix)
- **`ASMA_phenotype_20251222.xlsx` corrupted headers** (collection `asma_phenotyping`). The crawler
  captured `SA_Reportermple_id` (should be `sample_id`) and `asSA_Reportery_start_date` (should be
  `assay_start_date`) — consistent with a botched global find/replace of `"sa" → "SA_Reporter"`.
  This is **Sun-Young Kim's data**; per Spencer (2026-06-15) we do not clean other people's data.
  Action: mention to SYK when convenient; the SYK card flags `_20251209` as the safer recent file.

## Manifest gaps to close in a later pass
- **Crawler: per-table schema for the lakehouse `.txt` exports.** _(Mostly resolved — the crawler now
  descends subdirs via `scan_depth` / `exclude_dirs` / `pick_latest_subdir`: `asma_genomics` taxonomy
  & cluster files (`gtdbtk/`, `fastani/`, `mash/`) are schema-extracted, and the integration-pipeline
  `pipeline_outputs/runs/<dated>` is now the `integration_pipeline_outputs` collection.)_ Still
  deferred: `lakehouse_exports` lists the dated export directories but **shows 0 resources** — its
  tables are flat `.txt` files one level down that the crawler does not yet parse into per-table
  column schemas.
- **`request_to` for gated collections** should name a steward/owner, not "a member of group 'arkin'".
- **Candidate-keys heuristic** over-matches (e.g. `patient_type`, SYK's local `sample_id`). Cards
  override with authoritative keys; consider tightening the regex.
- **Derived phenotype metrics** (max-OD, growth rate, AUC, yes/no growth) don't exist anywhere; the
  manifest can only point at raw `cyc_*` timepoints. Note for a possible future derived-metrics product.

## Open questions still owed to people (from roadmap §7)
- **Jake:** where does "**hemolytic activity**" data live? Still unlocated — the manifest should be
  able to honestly answer "not found / ask Jake" rather than guess.
- **Adam / server admin:** who owns the decision to open server-wide read access to gated dirs.
- **Alex / SYK:** review their DRAFT cards for accuracy (join semantics, canonical files, naming).
