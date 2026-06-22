---
# Human-owned card. The crawler NEVER edits this file.
collection_id: integration_pipeline_outputs
maintainer: Spencer Long (Arkin data team)
last_reviewed: 2026-06-15
summary: The integration pipeline's dated-run outputs — the cleaned + linked "warehouse" tables. Holds the canonical CLEANED REDCap clinical, cleaned Conrad micro/sample data, the merged clinical⨝isolate⨝sample⨝patient table, and the multiomics integration. The analysis-ready, joined PROTECT data. Newest run is current; outputs vary by run.
keywords: [cleaned clinical, cleaned REDCap, clinical clean, merged table, clinical isolate sample patient merged, multiomics integration, integrated data, platinum, warehouse, pipeline outputs, pipeline runs, cleaned microbiology, cleaned sample metadata, analysis-ready, joined data, integration pipeline]
related: [patient_sample_isolate_linkage, clinical_redcap_raw, asma_genomics, asma_phenotyping, zengler_metagenomics_mind]
---

# Integration Pipeline Outputs (the warehouse)

> Machine schema + the **per-run subdirectory digest** live in the sibling `dataset.yaml`. The
> crawler auto-describes the **newest run** (`pick_latest_subdir`) and digests all runs.

## What this is
The outputs of the **PROTECT data integration pipeline** — the cleaned and linked **"warehouse"** of
PROTECT data. Each dated run under `pipeline_outputs/runs/<MM_DD_YY>/` is one pipeline execution; the
**newest run is current** — the crawler auto-describes it (`pick_latest_subdir`); see the sibling
`dataset.yaml` for which dated run that currently is. This is the **analysis-ready, joined** layer —
if you want clean/linked data, start here rather than re-cleaning raw sources.

> ⚠️ **Outputs vary by run.** The pipeline emits only what each run's use-case needed, so not every
> run contains every table. The catalog auto-follows the newest run; older runs are kept for history.

## How it connects (join keys)
Most warehouse tables are standardized to the cohort keys — **`patient_id`**, **`sample_id`** /
`pro_sample_id`, and **`ASMA_id`**. One exception worth knowing:
- **`protect_redcap_clinical_clean_*.csv`** (the canonical cleaned clinical) keys on **`subject_id`**
  + **`pro_sample_id`** (patient×visit grain) — it does **not** carry the integer `patient_id`. To get
  clinical keyed on the cohort `patient_id`, use the **merged** table (`patient_id` + `pro_sample_id` +
  `ASMA_id`) or `protect_conrad_sample_data_clean` (`sample_id` + `patient_id`) as the bridge.
- The merged and multiomics tables are **pre-joined** and carry `patient_id` directly — often you
  don't need to re-join through the hub at all (see `manifest/LINKAGE.md`).

## Products in this collection (latest run)
> Row counts vary by run and are **not** hand-listed here — read the sibling `dataset.yaml` (it
> describes the current newest run, with per-file row counts). This table is the durable map of
> *which* tables exist and their join keys.

| File (in the newest run dir) | What it is | Keys |
|---|---|---|
| `protect_redcap_clinical_clean_*.csv` | **Cleaned REDCap clinical** (use this, not raw) | `subject_id`, `pro_sample_id` — **no `patient_id`** (bridge via merged/sample tables) |
| `protect_conrad_sample_data_clean_*.csv` | Cleaned Conrad sample metadata | `patient_id`, `sample_id` |
| `protect_conrad_micro_data_clean_*.csv` | Cleaned Conrad microbiology data | `patient_id` |
| `protect_clinical_isolate_sample_patient_merged_*.csv` | **Merged** clinical ⨝ isolate ⨝ sample ⨝ patient | `ASMA_id`, `patient_id`, `pro_sample_id` |
| `protect_multiomics_isolate_sample_patient_integration_*.csv` | Multiomics integration ("platinum") | `sample_id`, `patient_id` |
| `protect_multiomics_..._conrad_integration_*.csv` | Multiomics integration + Conrad metadata | as above |
| `protect_pipeline_qa_report_*.md`, `protect_pipeline_run_log_*` | QA report + run logs | — |

## Example questions this answers
- *"Where's the cleaned clinical I can join on `patient_id`?"* → `protect_redcap_clinical_clean_*.csv`.
- *"Is there one table linking clinical + isolate + sample + patient?"* → `protect_clinical_isolate_sample_patient_merged_*.csv` — already joined (one row per clinical⨝isolate⨝sample⨝patient record; count in `dataset.yaml`).
- *"Multiomics integrated per sample?"* → `protect_multiomics_isolate_sample_patient_integration_*.csv` (one row per integrated sample).
- *"Cleaned microbiology / sample metadata?"* → `protect_conrad_micro_data_clean_*` / `protect_conrad_sample_data_clean_*`.
- *"What did the latest pipeline run produce, and when?"* → newest dated run + its `protect_pipeline_qa_report_*.md`.

## Caveats & known issues
- **Use the newest run.** The crawler auto-points at it; if you browse the dir, pick the latest dated
  folder. Older runs are historical snapshots.
- **Outputs vary by run** (see above) — confirm the table you want exists in the run you're using.
- **This is the canonical cleaned/linked source.** The `lakehouse_exports` are staged *downstream* of
  these; the `patient_sample_isolate_linkage` hub's Stage-0 copy also originates here.
- **Key-name note:** multiomics tables use `sample_id`; the merged table uses `pro_sample_id` for the
  same sample grain; the cleaned clinical uses `subject_id`/`pro_sample_id` (no `patient_id`). Mind the
  column name when joining across warehouse files.

## Access
Open (world-readable). `…/protect_data_integration_pipeline/pipeline_outputs/runs/`.

## Maintainer & cadence
**Spencer Long / Arkin data team** (pipeline owner — this card is authoritative, not a draft). New
dated run per pipeline execution. Pipeline docs: `…/protect_data_integration_pipeline/docs/`.
