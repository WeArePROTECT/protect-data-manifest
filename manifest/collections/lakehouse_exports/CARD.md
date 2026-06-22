---
# Human-owned card. The crawler NEVER edits this file.
collection_id: lakehouse_exports
maintainer: Spencer Long (Arkin Lab)
last_reviewed: 2026-06-15
summary: Dated snapshot exports of PROTECT tables staged to/from the KBase lakehouse (integration + mind-analysis namespaces). The window into what exists in the lakehouse for people who can't query it directly yet.
keywords: [lakehouse, KBase, data lake, exports, txt export tables, integration export, mind-analysis export, lakehouse tables, staged data, cleaned tables, silver layer]
related: [patient_sample_isolate_linkage, zengler_metagenomics_mind]
---

# KBase Lakehouse Exports

> Machine facts and the **dated export subdirectories** live in the sibling `dataset.yaml`.

## What this is
**Dated export snapshots** of PROTECT tables staged to the KBase lakehouse. This collection is the
**bridge for people without lakehouse access**: it lets them see *what has been pushed to the lake
and when*, even though they can't query the lakehouse directly yet. The exports are organized by
**namespace**, each staged as dated snapshot dirs:

| Namespace dir pattern | What it holds |
|---|---|
| `integration_export_<date>/` | integration namespace — the linked/cleaned ("Silver Layer") tables |
| `mind-analysis_export_<date>/` | mind-analysis namespace — Zengler MIND outputs |
| `previous_exports/` | archived earlier snapshots |

> The **current dated export dirs and their dates** live in the sibling `dataset.yaml`: each entry in
> `subdirectories` carries its `mtime`, and **`latest_subdir`** names the newest export snapshot
> (archive folders excluded) — read it for which snapshots exist now; this card doesn't hard-code them.

## How it connects (join keys)
- The integration export contains the linked/cleaned tables, which carry the same keys as the
  linkage hub (`ASMA_id` / `patient_id` / `sample_id`). The mind-analysis export carries Zengler
  MIND outputs (sample-keyed). For source-of-truth filesystem versions, see the upstream
  integration-pipeline outputs and `zengler_metagenomics_mind`.

## Example questions this answers
- *"Is there a cleaned/joined PROTECT table already in the lakehouse?"* → yes — the newest
  `integration_export_<date>/` snapshot (see `dataset.yaml` `subdirectories` for the current one).
- *"What's been pushed to the lakehouse, and when?"* → the dated export subdirs (`dataset.yaml` `subdirectories`).
- *"MIND analysis in the lakehouse?"* → the newest `mind-analysis_export_<date>/`.

## Caveats & known issues
- **Table-level schemas inside the exports aren't catalogued yet.** Each export's tables are flat,
  delimited **`.txt` (CSV)** files at the top level of the export dir — e.g.
  `protect_isolate_sample_patient_linkage.txt`, `protect_clinical_isolate_merged.txt`,
  `protect_redcap_clinical_clean.txt` (the mind-analysis export holds `mind_*.txt` tables) — directly
  readable with `head`. The crawler currently records the export directories and file-type counts but
  does **not** yet parse each table's columns (a planned enhancement). Each export also carries a
  **`MANIFEST.txt`** listing its tables, row counts, sizes, MD5s, and the pipeline source-run dirs it
  was built from — read it for that export's current table inventory and row counts.
- **Snapshots are point-in-time, not live** — each export is frozen at its staging date (see
  `dataset.yaml` `subdirectories` for the current export dates).

## Access
Open (the export staging directory is world-readable). Note: *querying the live lakehouse* is a
separate capability most scientists don't have — that's the access gap this collection exists to bridge.

## Maintainer & cadence
**Spencer Long / Arkin data team.** New exports appear when tables are (re)staged to the lake.
