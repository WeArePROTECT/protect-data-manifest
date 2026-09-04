---
# Human-owned card. The crawler NEVER edits this file.
collection_id: asma_phenotyping
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by Sun-Young Kim (SYK)
last_reviewed: 2026-09-04
summary: Lab-measured phenotypes for the ASMA isolates — growth curves (BHI/SCFM), carbon & amino-acid utilization, PA reporter inhibition/competition assays, and measured antibiotic resistance. The phenotype half of the ASMA collection. IMPORTANT — the `Competition` sheet is the Task-2.1 in-vitro FORMULATION exclusion screen (1–5-member SynComs vs 8 pathogen reporters, computed Inhibition_percent). Join to the rest of PROTECT via ASMA_id (NOT the local sample_id).
keywords: [phenotype, growth curve, growth, OD600, SCFM, BHI, carbon utilization, carbon source, sole carbon, carbon kinetics, amino acid utilization, reporter, PA reporter, inhibition, pairwise interaction, competition assay, formulation, formulation screen, in vitro exclusion, competitive exclusion, SynCom, community formulation, Inhibition_percent, PA14, PAO1, VAP pathogen, antibiotic resistance, measured AMR, MIC, isolate stock list, ASMA_list, APL metadata, Sun-Young Kim, SYK]
related: [patient_sample_isolate_linkage, asma_genomics]
---

# ASMA Phenotype (SYK)

> Machine schema, file list, sizes, and freshness live in the sibling `dataset.yaml` (24 sheets
> across the workbooks below). This card is the human guide to *which file holds what*.

## What this is
Lab-measured **phenotypes** for the ASMA isolates, produced by Sun-Young Kim (SYK). Covers growth,
carbon/amino-acid utilization, *Pseudomonas aeruginosa* reporter inhibition/competition assays, and
measured antibiotic resistance — the **phenotype half of the ASMA collection** (the genomic half is
`asma_genomics`). Lives at `/usr2/people/protect/Arkin_Lab/SYK`.

**This collection also holds the core FORMULATION data.** The `Competition` sheet in the
`ASMA_phenotype_*.xlsx` workbooks is the **Task-2.1 in-vitro formulation exclusion screen**: 1–5-member
SynCom communities (`ASMA_A_id`…`ASMA_E_id`) co-cultured with a fluorescent pathogen reporter
(`Reporter_id` — 8 reporters incl. PA14, PAO1, clinical PA, and VAP-expansion AB/KP/SA), readout =
computed `Inhibition_percent`. That is why this collection carries the `FORMULATION` facet even though
its id leads with "phenotyping." **Both are now LIVE on the KBase lakehouse (2026-09-03).** The `Competition` screen is
`protect.formulation.competition_screen` (28,928 rows); the carbon/growth/AMR assays are
`protect.phenotype` (12 tables, 20,353 rows). Spec, recon and retrospective:
`protect_lakehouse_pipeline/datasets/_runs/formulation_push_20260903/`. Namespace READMEs, each
leading with what will bite you: `protect_lakehouse_pipeline/datasets/{formulation-screening,phenotype}/README.md`.

⚠ **Everything in `protect.phenotype` is `preliminary`** by SYK's own note: raw measurements with
no QC pass applied, and outliers observed among biological replicates with no agreed exclusion
criteria. No filtering is applied on the lakehouse.

## How it connects (join keys)
- **Join to the rest of PROTECT on `ASMA_id`** → the `patient_sample_isolate_linkage` hub →
  `patient_id` / `sample_id`, and → `asma_genomics`. Single-isolate assay sheets carry `ASMA_id`
  directly; the **multi-isolate interaction/competition sheets instead use per-bacterium id columns**
  (`pairwise_interaction`: `bacterium_1_ASMA_id` / `bacterium_2_ASMA_id`; `Competition`:
  `ASMA_A_id` / `ASMA_B_id` / `ASMA_C_id` …) — there is no plain `ASMA_id` column on those sheets.
- ⚠️ **Accuracy trap:** the local **`sample_id` (integer) is an assay/plate id, NOT the cohort
  `sample_id` (`PRO###`)** in the linkage table. **Do not join cross-collection on `sample_id`** —
  use `ASMA_id`. The crawler's `candidate_keys` lists `sample_id`; ignore it for cross-collection joins.
- ⚠️ **Cardinality:** the same `ASMA_id` recurs across assay dates and sheets (repeat assays);
  `assay_start_date` distinguishes runs. Pick a date or aggregate before a per-patient join.

## Example questions this answers
- *"Growth phenotype of the ASMA isolates?"* → growth curves: `ASMA_phenotype.xlsx [growth_curve]` (BHI) and the SCFM curves in `ASMA_phenotype_20250420.xlsx [Growth_Curve_SCFM]` / `ASMA_phenotype_20251209.xlsx` / `_20251222.xlsx [SCFM_growth_curve]`. Columns `cyc_1…cyc_193` are raw OD600 timepoints (see Caveats — no derived metric).
- *"Which carbon sources can isolate X use?"* → `ASMA_phenotype.xlsx [carbon_utilization]` (OD per single carbon/amino-acid source) or `ASMA_phenotype_20250420.xlsx [Carbon_utilization_binary]`; time-series kinetics in the dated `ASMA_carbon_kinetics_*.xlsx` workbooks (use the newest — `dataset.yaml` lists the current set).
- *"Measured antibiotic resistance (MICs)?"* → `ASMA_phenotype_20250420.xlsx [Antibiotic_resistance]` (KAN/CHL/CB/TET/STR/SPE/GEN). **This is measured phenotype — for genomic AMR gene predictions use `asma_genomics/amrfinder.tsv`.**
- *"PA inhibition / who inhibits whom?"* → `ASMA_phenotype.xlsx [pairwise_interaction]` (bacterium vs PA reporter) and the `Competition` sheet (see next).
- *"Which formulations exclude the pathogen in vitro / by how much?"* → the **`Competition`** sheet in the newest `ASMA_phenotype_*.xlsx` (Task-2.1 exclusion screen): `ASMA_A_id`…`ASMA_E_id` define the 1–5-member SynCom, `Reporter_id` the pathogen (PA14/PAO1/clinical-PA/AB/KP/SA), `Inhibition_percent` the readout. On the lakehouse as `protect.formulation.competition_screen`, live 2026-09-03.
- *"Where is isolate ASMA-#### physically stocked?"* → `ASMA_list.xlsx` (`stock_location`, `CP1_plate`, `growth_media`).

## Data dictionary (files & what they hold)
| File / sheet | Holds |
|---|---|
| `ASMA_phenotype.xlsx` → `growth_curve`, `positive_growth` | BHI growth curves (`cyc_*` OD600) |
| `ASMA_phenotype.xlsx` → `carbon_utilization` | OD per single carbon/amino-acid source |
| `ASMA_phenotype.xlsx` → `pairwise_interaction`, `inhibition_standard_control` | PA reporter inhibition assays |
| `ASMA_phenotype_20250420.xlsx` (2025-era) → `Growth_Curve_SCFM`, `Carbon_utilization_binary`, `Competition`, `Antibiotic_resistance` | SCFM growth, binary carbon, **formulation exclusion screen** (Task 2.1; 1–5-member SynComs vs pathogen reporters → `Inhibition_percent`), **measured AMR** (MIC) |
| `ASMA_phenotype_20251209.xlsx`, `_20251222.xlsx` → `SCFM_growth_curve`, `carbon_utilization` | Newer growth + carbon (see Caveats re: `_20251222`) |
| ⚠️ **Newest workbook (mid-2026, e.g. `ASMA_phenotype_20260714.xlsx`) restructured the sheets** | plate-format split + version suffixes: growth = `Growth_Curve_SCFM_384` / `Growth_Curve_single_384` / `Growth_Curve_single_96` / `Growth_Curve_dropoff_384`; AMR = `Antibiotic_resistance_v1` / `_v2`; endpoints = `Carbon_utilization_endpoint_v1`, `Growth_endpoint`; `Competition` retained. **The bare sheet names above are 2025-era only** — check `dataset.yaml` (`latest_resource`) for the current file's exact sheets |
| `ASMA_carbon_kinetics_*.xlsx` (dated) → `drop_off`/`sole_carbon` (older); `drop_off_384well` / `single_carbon_384well` / `single_carbon_96well` (since `_20260623`) | Carbon-source utilization **kinetics** time series (use the newest — see `dataset.yaml`) |
| `ASMA_list.xlsx` | Isolate stock list (`ASMA_id` → location/plate/media) |
| `APL_metadata.xlsx` | APL-named isolate metadata (`patient_id`, `sputum_id`, `APL_id`) — *relationship to ASMA naming to verify with SYK* |

## Caveats & known issues
- **Raw timepoints, no derived growth metric.** Growth curves are `cyc_*` OD600 matrices; there is
  **no precomputed max-OD / growth-rate / AUC / yes-no-growth** anywhere here. Compute it yourself.
- **Multiple dated workbooks; canonical file per assay is not labeled.** Dated workbooks accumulate
  as assays are run; the descriptor (`dataset.yaml`) lists the current set and freshness — **use the
  newest dated file per assay type**, except where the known issue below says otherwise. Which
  workbook is *authoritative* per assay is unlabeled — *to verify with SYK*.
- **Known data-quality issue (SYK's data — not ours to fix):** `ASMA_phenotype_20251222.xlsx` has
  corrupted column headers (`SA_Reportermple_id` for `sample_id`, `asSA_Reportery_start_date` for
  `assay_start_date`) — consistent with a botched global find/replace. Prefer `_20251209` until SYK
  confirms/fixes. Logged in `docs/decisions/notes_deferred.md`.
- **`sample_id` is a local assay id, not the cohort sample** (see join keys).

## Access
Open (world-readable). `/usr2/people/protect/Arkin_Lab/SYK`.

## Maintainer & cadence
Data owner: **Sun-Young Kim (SYK)**, Arkin Lab. New dated workbooks appear as assays accumulate.
This catalog card: Spencer Long — **DRAFT pending SYK's review**, especially "canonical file per
assay" and the APL↔ASMA naming relationship.
