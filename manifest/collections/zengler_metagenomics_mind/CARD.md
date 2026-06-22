---
# Human-owned card. The crawler NEVER edits this file.
collection_id: zengler_metagenomics_mind
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by Emma Rooholfada (Zengler)
last_reviewed: 2026-06-22
summary: Emma's metagenomic (metaG) + metatranscriptomic (metaRS) analysis of PROTECT respiratory samples — OGU taxonomy/function feature tables across clustering thresholds, a custom respiratory reference DB, MAGs, and MIND-analysis inputs. The omics half of the cohort. Large and evolving; join to patients via sample id (PRO###), NOT ASMA_id.
keywords: [metagenomics, metaG, metatranscriptomics, metaRS, MIND, niche, OGU, operational genomic unit, feature table, KO, KEGG, functional abundance, taxonomy, species abundance, custom database, reference database, WoL, web of life, MAGs, bakta, ANI cluster, clustering, respiratory microbiome, omics, Emma, Rooholfada, Zengler]
related: [patient_sample_isolate_linkage, protect_sample_roster, clinical_redcap_raw]
---

# Zengler Metagenomics / MIND (Emma)

> Machine schema, the (capped) data-file list, and the **per-subdirectory digests** live in the
> sibling `dataset.yaml` (it records the current file count and how many were described). This is a
> **large, actively evolving** workspace — this card maps the structure so an agent can navigate it;
> defer to Emma for which outputs are final.

## What this is
Emma Rooholfada's (Zengler Lab, UCSD) **metagenomic and metatranscriptomic** analysis of PROTECT
respiratory (sputum) samples — the **omics half of the cohort** (the isolate halves are
`asma_genomics` and `asma_phenotyping`). Covers read processing, a custom respiratory reference
database, taxonomic + functional feature tables, MAGs, and inputs to the **MIND** analysis.

## How it connects (join keys)
- These are **per-sample feature matrices**: the OGU tables carry each sample's id as a **column
  header** in wide format (e.g. `PRO101_metaG_respiratory_custom_subset10_align` — the `PRO###` id is
  a *prefix* of the header, not the whole token), **not** a key field, and never use `ASMA_id`.
- The map `PROTECT sample metadata.xlsx` (sheets `Metagenomics` / `Metaribo-seq`) carries
  `sample_name`, `library_ID`, **and `patient_id` directly** — so omics → patient can go
  `sample_name` → `patient_id` via that file. To reach the cohort hub instead, match the `PRO###` /
  `sample_name` to the hub's `sample_id`. *(Whether `sample_name` == the hub's `PRO###` is to verify
  with Emma.)*
- See `manifest/LINKAGE.md` for the metagenomics-by-clinical-group recipe.

## Structure (the map)
| Subdir | What's there |
|---|---|
| `PRO_metaG/` | Metagenomics pipeline: `raw`→`trim`→`host_filtered`→`MAGs`; `custom/` = custom respiratory ref DB + taxonomy maps (`taxonomy_metadata*.tsv`, `refdb*.csv`, `bakta_kofam.tsv`) |
| `PRO_metaG/features_subset10_metaG*/` | **OGU feature tables** (taxonomy + KO function abundance). The base dir `features_subset10_metaG/` holds `ogu.tsv`, `ogu_orf.tsv`, `tax_func.tsv`, `tax_orf.tsv`, `tax_orf_ko.tsv`. The **`_manual`** variant additionally holds `ogu_species.tsv`, `ogu_ko.tsv`, `ogu_genome.tsv`, and `cluster95…99_ko.tsv` (+ `cluster99.5_ko.tsv`); **`_quickrecover`** is another variant. ⚠️ `ogu_species.tsv` / `ogu_ko.tsv` / `cluster*_ko.tsv` are **only in `_manual` / `_quickrecover`, not the base dir** |
| `PRO_metaRS/` | Metatranscriptomics — same OGU feature-table structure (expression instead of abundance) |
| `analysis_cluster95/`, `analysis_cluster97/` (+ `_prok`, `_prok_filt_genome{15,25,66}`, `_prok_filt_readbased{25,66}`) | Downstream analyses at different ANI cluster thresholds, prokaryote-only, and genome-/read-based filtering — **multiple exploratory variants** |
| `WoL_Subset50_analysis/` | Web-of-Life reference-genome-DB alignment (subset of 50) |
| `final_dataset_clean/` | **Appeared 2026-06-19 — looks like Emma's cleaned/finalized feature set** (the descriptor's `latest_subdir`): depth-filtered & CPM-normalized multiomics (`multiomics_clean_filtered_raw.tsv`, `multiomics_paired_*`, `pathway_multiomics_brite_cpm.tsv`, `uniref90_multiomics_filtered.tsv`), OGU tables (`ogu_species.tsv`, `ogu_ko.tsv`, `ogu_genome.tsv`, `ogu_cluster_95.tsv`), `sample_qc_status.tsv`, plus `qc/`, `sparcc_PApos/`, `trikafta_de/`. **Likely the canonical cleaned output — to confirm with Emma.** |
| `custom_database/` | The custom reference-DB build (64 files) |
| `analysis3/`, `misc/`, `tmp_kofam/` | Misc / scratch |

## Example questions this answers
- *"Taxonomic / species abundance per sample?"* → `ogu.tsv` (OGU abundance, in the base `features_subset10_metaG/` dir); for species-level, `ogu_species.tsv` — which lives in `features_subset10_metaG_manual/` (and `_quickrecover/`), **not** the base dir.
- *"Functional (KO/KEGG) abundance per sample?"* → `tax_func.tsv` / `tax_orf_ko.tsv` (base dir); `ogu_ko.tsv` and `cluster*_ko.tsv` are in the `_manual` variant dir.
- *"Metatranscriptomics / expression?"* → `PRO_metaRS/` (same feature-table layout).
- *"Assembled genomes / MAGs?"* → `PRO_metaG/MAGs/` (`all_bakta.tsv`).
- *"MIND analysis outputs?"* → in the cluster-analysis dirs *(exact final location to verify with Emma)*.
- *"Which patients do these omics samples map to?"* → `PROTECT sample metadata.xlsx` (`sample_name` → `patient_id` **directly**).
- *"Is there a cleaned / final feature set (not the exploratory variants)?"* → `final_dataset_clean/` (cleaned multiomics + OGU tables + QC; appeared 2026-06-19) — likely canonical, **to confirm with Emma**.

## Caveats & known issues
- **Large and exploratory — but a likely-canonical set now exists.** A new **`final_dataset_clean/`**
  dir appeared 2026-06-19 (the descriptor's `latest_subdir`) and looks like Emma's cleaned/finalized
  feature set — **to confirm with Emma** that it supersedes the exploratory `features_subset10_*`
  variants. Until confirmed, the many parallel variants (cluster 95 vs 97, prokaryote-only, several
  filtering thresholds) remain; don't assume the newest-named dir is canonical.
- **Subdir digests are shallow** (immediate children only) and the crawler describes a capped subset
  of the data files (the descriptor states the current count) — deeper files exist. For full
  internals, defer to Emma.
- **`subset10` scope** (a 10-sample subset?) — *to verify with Emma*.
- **No owner manifest found.** Unlike `asma_genomics`, there's no `MANIFEST.md` here, so this card +
  the crawl are the primary catalog. Recommend Emma adopt an owner manifest / `DATA_CARD`.

## Access
Open (world-readable). `/usr2/people/protect/Zengler_Lab/Emma`.

## Maintainer & cadence
Data owner: **Emma Rooholfada** (Zengler Lab). Actively growing. This card: Spencer Long —
**DRAFT pending Emma's review**, especially canonical feature tables, MIND location, and the
sample→patient key columns.
