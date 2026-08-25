---
# Human-owned card. The crawler NEVER edits this file.
collection_id: lakehouse_exports
maintainer: Spencer Long (Arkin Lab)
last_reviewed: 2026-08-19
summary: Dated snapshot exports of PROTECT tables staged to/from the KBase lakehouse (integration + mind-analysis namespaces). The window into what exists in the lakehouse for people who can't query it directly yet.
keywords: [lakehouse, KBase, data lake, exports, txt export tables, integration export, mind-analysis export, genome-analysis export, taxonomy, isolate taxonomy, GTDB, strain group, lakehouse tables, staged data, cleaned tables, silver layer, refinery bronze]
related: [patient_sample_isolate_linkage, zengler_metagenomics_mind]
---

# KBase Lakehouse Exports

> Machine facts and the **dated export subdirectories** live in the sibling `dataset.yaml`.

> ## ⛔ Do not use `protect_refinery_bronze` as a data source
>
> It is a **frozen, second-hand 2026-03-07 copy** of Adam Arkin's pre-existing refinery,
> ingested only so he could reach data he already had. It is uncurated, unrefreshed, and
> preserves his quirks verbatim (string-encoded numbers, misspellings, all-null columns,
> duplicate keys). Every table in it is superseded by a raw-sourced namespace.
>
> **Specifically, `dim_isolate` looks like an ASMA taxonomy table and must not be used as one.**
> Against Alex Styer's current file it has: `strain_group` agreeing on only **9 of 4,946**
> isolates (mash clustering was re-run since the snapshot), `total_contigs` **100% NULL**,
> `assembly_type`/`assembler` **missing**, and **22 duplicate `asma_id`**. Anyone who pulled
> strain groups from it has wrong strain groups.
>
> **Use `protect_genome_analysis.isolate_taxonomy` instead** — **live on the lakehouse since
> 2026-08-19**, verified (row counts + 17 smoke tests all passed). 4,927 isolates, one row each,
> `asma_id` unique. Column-by-column docs:
> `Arkin_Lab/sjlong/task_4_3_and_4_4/track_a/A2b_A3/a3_taxonomy_data_dictionary.md`.

## What this is
**Dated export snapshots** of PROTECT tables staged to the KBase lakehouse. This collection is the
**bridge for people without lakehouse access**: it lets them see *what has been pushed to the lake
and when*, even though they can't query the lakehouse directly yet. The exports are organized by
**namespace**, each staged as dated snapshot dirs:

| Namespace dir pattern | What it holds |
|---|---|
| `integration_export_<date>/` | integration namespace — the linked/cleaned ("Silver Layer") tables |
| `mind-analysis_export_<date>/` | mind-analysis namespace — Zengler MIND outputs |
| `phenotype_export_<date>/` | `protect_phenotype` — SYK phenotyping: `carbon_utilization`, `growth_curve_scfm`, `antibiotic_resistance` |
| `formulation_export_<date>/` | `protect_formulation` — SYK formulation exclusion screen: `competition_screen` |
| `genome-analysis_export_<date>/` | `protect_genome_analysis` — Alex Styer's ASMA taxonomy, **live 2026-08-19**: `isolate_taxonomy` (4,927, one per **isolate**, `asma_id` unique) + `genome_taxonomy` (5,725, one per **assembly**) |
| `refinery-bronze_export_<date>/` | `protect_refinery_bronze` — aparkin's frozen Bronze refinery: 23 tables, ~30.6M rows. **⛔ NOT A CURATED SOURCE — see the warning below** |
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
