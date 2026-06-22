---
# Human-owned card. The crawler NEVER edits this file.
collection_id: asma_phenotyping
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by Sun-Young Kim (SYK)
last_reviewed: 2026-06-15
summary: Lab-measured phenotypes for the ASMA isolates — growth curves (BHI/SCFM), carbon & amino-acid utilization, PA reporter inhibition/competition assays, and measured antibiotic resistance. The phenotype half of the ASMA collection. Join to the rest of PROTECT via ASMA_id (NOT the local sample_id).
keywords: [phenotype, growth curve, growth, OD600, SCFM, BHI, carbon utilization, carbon source, sole carbon, carbon kinetics, amino acid utilization, reporter, PA reporter, inhibition, pairwise interaction, competition assay, antibiotic resistance, measured AMR, MIC, isolate stock list, ASMA_list, APL metadata, Sun-Young Kim, SYK]
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
- *"PA inhibition / who inhibits whom?"* → `ASMA_phenotype.xlsx [pairwise_interaction]` (bacterium vs PA reporter) and `ASMA_phenotype_20250420.xlsx [Competition]` (3-way community competition, `Inhibition_percent`).
- *"Where is isolate ASMA-#### physically stocked?"* → `ASMA_list.xlsx` (`stock_location`, `CP1_plate`, `growth_media`).

## Data dictionary (files & what they hold)
| File / sheet | Holds |
|---|---|
| `ASMA_phenotype.xlsx` → `growth_curve`, `positive_growth` | BHI growth curves (`cyc_*` OD600) |
| `ASMA_phenotype.xlsx` → `carbon_utilization` | OD per single carbon/amino-acid source |
| `ASMA_phenotype.xlsx` → `pairwise_interaction`, `inhibition_standard_control` | PA reporter inhibition assays |
| `ASMA_phenotype_20250420.xlsx` → `Growth_Curve_SCFM`, `Carbon_utilization_binary`, `Competition`, `Antibiotic_resistance` | SCFM growth, binary carbon, community competition, **measured AMR** |
| `ASMA_phenotype_20251209.xlsx`, `_20251222.xlsx` → `SCFM_growth_curve`, `carbon_utilization` | Newer growth + carbon (see Caveats re: `_20251222`) |
| `ASMA_carbon_kinetics_*.xlsx` (dated) → `drop_off`, `sole_carbon` | Carbon-source utilization **kinetics** time series (dated workbooks; use the newest — see `dataset.yaml`) |
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
