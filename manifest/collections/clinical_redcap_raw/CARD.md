---
# Human-owned card. The crawler NEVER edits this file.
collection_id: clinical_redcap_raw
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by the Conrad team
last_reviewed: 2026-06-15
summary: Raw REDCap clinical exports from the Conrad team — the source of all PROTECT patient/clinical data. Dated full-database dumps + a data dictionary. GATED. For analysis, use the cleaned clinical from the integration pipeline, not these raw files.
keywords: [clinical, REDCap, patient data, clinical metadata, raw clinical, data dictionary, Conrad, patient records, CompleteDatabase, demographics, clinical outcomes]
related: [patient_sample_isolate_linkage, protect_sample_roster]
---

# Clinical — Raw REDCap Exports

> Machine schema, file list, and freshness live in the sibling `dataset.yaml`.

## What this is
**Raw REDCap clinical exports** — the **Conrad team is the source of all PROTECT patient/clinical
data** (clinicians who collect in the field). These are **dated full-database CSV dumps** (a new
`...CompleteDatabase.csv` lands periodically as the cohort grows) plus the REDCap **data dictionary**
(`dictionary/PROTECT_DataDictionary_*.csv`, which defines the clinical field set). For the current
file set and which dump is newest, read the sibling `dataset.yaml`: its **`latest_resource`** field
names the newest dump, and **`resources`** lists each file with its `mtime` + row count — all
machine-refreshed nightly; this card deliberately does not hard-code them.

## How it connects (join keys)
- ⚠️ **The raw exports do NOT contain a `patient_id` column.** Their actual keys are **`subject_id`**
  (patient-level), **`sampleid`** (sample-level), and `record_id`. The cohort hub uses an integer
  `patient_id`, so joining raw → hub needs a `subject_id`→`patient_id` mapping this collection does
  **not** provide — **to verify**, and another reason to prefer the cleaned product.
- ⚠️ **For cross-collection analysis, use the CLEANED clinical** produced by the integration pipeline
  (Stage 1 REDCap clean), **not these raw exports**. Raw is the source-of-record; cleaned (which
  is the joinable product → **`integration_pipeline_outputs`**: `protect_redcap_clinical_clean_*.csv`
  (cleaned clinical, keyed `subject_id`/`pro_sample_id`), with the cohort `patient_id` reachable via
  that collection's **merged** / sample tables.

## Example questions this answers
- *"Where is the raw clinical / REDCap data?"* → here (but it's **gated** — see Access).
- *"What clinical fields/variables exist?"* → `dictionary/PROTECT_DataDictionary_*.csv`.
- *"The cleaned clinical for joining to isolates/omics?"* → **not here** — integration-pipeline cleaned output.
- *"Most current clinical export?"* → `dataset.yaml` names it directly in **`latest_resource`** (the crawler resolves the newest dump by file mtime each night).

## Data dictionary (files)
| File pattern | Holds |
|---|---|
| `*_CompleteDatabase.csv` (dated) | Full raw REDCap database dump — one row per record; a new dated dump lands periodically, and the newest is the current export (see `dataset.yaml` for the set + counts) |
| `PROTECT_RawDataExport_*.csv`, `RedCap_*.csv` (earlier dates) | Earlier dated raw dumps (record counts grow over time) |
| `dictionary/PROTECT_DataDictionary_*.csv` | REDCap field/variable definitions (the clinical data dictionary) |

## Caveats & known issues
- **GATED** — this directory is not world-readable (group-restricted). The manifest can tell you it
  *exists* and its shape; reading the bytes needs access (see Access).
- **Raw, not cleaned** — one row per record; REDCap-wide and not analysis-ready. Use the pipeline's
  cleaned output for joins.
- **Patient data — treat as sensitive.** The manifest holds only column-level metadata, not records.
- Multiple dated dumps accumulate; record counts grow over time (see `dataset.yaml` `resources` for the current per-file counts).

## Access
**Gated** (`drwxrwx---`, group `arkin`). Who to ask: **the Conrad clinical team** (REDCap data owner;
dir owner `dibarramunoz`); **Spencer Long** (Arkin data) can help broker access. (Now set as
`request_to` in the descriptor.)

## Maintainer & cadence
Data owner: **Conrad team** (clinical). New raw dumps land periodically (~monthly). This card:
Spencer Long — **DRAFT pending Conrad review**.
