---
# Human-owned card. The crawler NEVER edits this file.
collection_id: patient_sample_isolate_linkage
maintainer: Spencer Long (Arkin Lab)
last_reviewed: 2026-06-15
summary: Canonical patient↔sample↔isolate join layer for all of PROTECT (5,182 rows); the crosswalk you route through to combine any two PROTECT datasets, via ASMA_id / patient_id / sample_id.
keywords: [gold linkage table, gold metadata table, ASMA gold, join table, master join, crosswalk, registry, patient sample isolate mapping, ASMA_id mapping, cohort registry, linkage]
related: [asma_genomics, asma_phenotyping, zengler_metagenomics_mind, clinical_redcap_raw, protect_sample_roster]
---

# Patient–Sample–Isolate Gold Linkage (v4)

> Machine schema, file list, sizes, and freshness live in the sibling `dataset.yaml`.
> This card holds the things a crawler can't know.

## What this is
The **canonical join layer for the entire PROTECT project** — the single registry that ties
patient-, sample-, and isolate-level data together. One row per record across **5,182 rows**
(5,019 bacterial-isolation records + 163 omics-only samples), spanning the full enrolled PROTECT
cohort. If you need to combine *any* two PROTECT datasets (clinical ⨝ genomic ⨝ phenotype), you
route through this table.

## Why it exists / provenance
v4.0 (built 2026-03-25, "Gold" — all 13 QC checks passed) extends the immutable **v3.1**
isolation-only table by appending **163 omics-only samples** (Zengler/Emma metaG samples that were
sequenced but never sent for bacterial isolation), making it the first table to cover the *whole*
cohort, not just isolation activity. Built by `patient_sputum_asma_isolate_gold_metadata_v3_0.ipynb`
from three sources: the immutable v3.1 table (carried forward byte-for-byte), the PROTECT_Samples
tracking sheet, and Emma Rooholfada's metaG sample metadata. Effectively **Stage 0** of the data
integration pipeline. Full provenance: `ASMA_Gold_Metadata_Documentation_v4_0.md` in the
collection root.

## How it connects (join keys)
This is the point of the table. Three keys reach the rest of PROTECT:

| Key | Joins to | Example collections |
|---|---|---|
| `ASMA_id` | **isolate**-level data | `asma_genomics` (AMR `amrfinder.tsv`, virulence `metaVF.tsv`, taxonomy `gtdbtk`), `asma_phenotyping` |
| `patient_id` | **patient / clinical** data | Conrad REDCap clinical (via the integration pipeline's cleaned output) |
| `sample_id` | **sample / omics** data | `zengler_metagenomics_mind`, `protect_sample_roster` |

> Note: `dataset.yaml.candidate_keys` is a *heuristic* and currently also lists `patient_type`
> (matched on the substring "patient"). The **authoritative** join keys are the three above. This
> is exactly why the human card exists alongside the machine descriptor. Full cross-collection map:
> see [`manifest/LINKAGE.md`](../../LINKAGE.md).

## Example questions this answers
- *"What patient and sample does isolate ASMA-#### come from?"* → look up `ASMA_id` in this table; read `patient_id`, `sample_id`, `patient_type`.
- *"I have AMR calls (`amrfinder.tsv`) — how do I tie them to patients?"* → join `asma_genomics` → this table on `ASMA_id`, then read `patient_id`. (This is the genomic half of Jake's ASMA example.)
- *"Take the ASMA collection and filter by AMR + growth phenotype, per patient."* → `asma_genomics` (AMR via `ASMA_id`) ⨝ this table (`ASMA_id`→`patient_id`/`sample_id`) ⨝ `asma_phenotyping` (growth, via `ASMA_id`).
- *"Which isolates are from the adult vs pediatric vs healthy-donor populations?"* → filter `patient_type` (values: `adult` / `pediatric` / `healthy_donor`).
- *"How many omics-only samples are in the cohort, and which patients?"* → rows with blank `ASMA_id`; read `sample_id` / `patient_id`.
- *"Give me one registry of the full cohort (isolation + omics)."* → this table (v4) is it.

## Data dictionary (key columns)
| Column | Meaning |
|---|---|
| `ASMA_id` | Isolate identifier assigned at bacterial culturing. **Blank for omics-only rows** (no isolate). |
| `patient_id` | Integer patient identifier (the cross-cohort patient key). |
| `sample_id` | Sample identifier; the omics/sample key. Patient samples use `PRO<n>` (e.g. `PRO101`); healthy-donor samples use `HD<n>_<site>` (e.g. `HD1_tongue`, `HD1_throat`). |
| `patient_type` | Patient population — actual values are `adult`, `pediatric`, `healthy_donor` (an age-band / donor-status axis; **not** a CF vs non-CF disease label — disease status lives in the clinical data). *Not* a join key. |
| `sampling_method` | Sample material / collection method — actual values: `sputum`, `oral_rinse`, `oral_swab`. |
| `sampling_site` | Anatomical / collection site — actual values: `lower_respiratory_tract`, `oral_cavity`, `tongue`, `throat`. |
| `isolation_media` | Culture media used. **Blank for omics-only rows.** |
| `stock_plate`, `stock_well` | Physical stock location of the isolate. **Blank for omics-only rows.** |
| `sk_notes` | Free-text curation notes (sparse; mostly blank — hence the crawler's `unknown` type). |

## Caveats & known issues
- **Omics-only rows (163) have `ASMA_id`, `isolation_media`, `stock_plate`, `stock_well` blank** —
  they were never cultured. Don't treat a blank `ASMA_id` as missing data; it means "omics sample."
- **Isolation vs omics is mutually exclusive** by cohort design (0 overlap).
- **v3.1 is preserved separately** as the canonical *isolation-only* reference (5,019 rows). Use v4
  unless you specifically need the isolation-only view.
- The integration pipeline also emits a copy of this linkage as a Stage-0 output; **this directory
  is the authoritative source**.

## Recommended uses / not for
- **Use it** as the backbone to join PROTECT datasets across patient/sample/isolate grain.
- **Not** a source of clinical values, phenotypes, or genomic calls themselves — it's the *map*;
  join outward to the collection that holds those.

## Access
Open (world-readable). Lives at `collection_root` (see `dataset.yaml`); provenance docs (full
documentation, QC report, update log) sit alongside the CSV in the same directory.

## Maintainer & cadence
Spencer Long (Arkin Lab). Versioned and rebuilt when the cohort changes (v3.1 → v4.0). The
authoritative source is this directory. The v3.0 build notebook
(`patient_sputum_asma_isolate_gold_metadata_v3_0.ipynb`) is named in the provenance documentation
(it is not shipped alongside the CSV in this directory).
