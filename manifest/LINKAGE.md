# PROTECT Linkage Layer — the join map

How PROTECT collections connect. The whole point of the manifest is enabling cross-dataset
questions ("AMR per patient", "phenotype by clinical outcome", "metagenomics for CF vs non-CF"),
and every one of those routes through the **gold linkage hub**.

> Agents: read this when a question spans more than one collection. Pair it with each collection's
> `CARD.md` ("How it connects") and `dataset.yaml` (exact columns).

## The hub
**`patient_sample_isolate_linkage`** — `patient_sputum_asma_gold_linkage_table_v_4_0.csv`
(5,182 rows). Carries the three identifiers that reach everything else:

| Key | Grain | Reaches |
|---|---|---|
| `ASMA_id` | one bacterial isolate | genomics, phenotype, isolate stock |
| `patient_id` (int) | one patient | clinical (REDCap, via the integration pipeline) |
| `sample_id` (`PRO###`) | one collected sample | metagenomics / omics, sample roster |

## Join map (collection → hub)
| Collection | Join on | → hub key | Cardinality | Notes |
|---|---|---|---|---|
| `asma_genomics` (`amrfinder.tsv`, `metaVF.tsv`, GapMind, QC) | `ASMA_id` / `isolate_id` | `ASMA_id` | **many → 1** (many gene/pathway rows per isolate) | aggregate (presence/absence) before per-patient joins |
| `asma_phenotyping` (growth, carbon, reporter, measured AMR) | `ASMA_id` | `ASMA_id` | **many → 1** (repeat assays per isolate/date) | **do NOT join on SYK's local `sample_id`** — it's an assay id, not `PRO###` |
| `zengler_metagenomics_mind` (metaG / MIND) | `sample_name` / `PRO###` header | `sample_id` | per-sample (wide) | OGU tables carry `PRO###` as **column headers**; `PROTECT sample metadata.xlsx` maps `sample_name`→`patient_id` **directly**. *sample_name==PRO### to verify* |
| `protect_sample_roster` (`*PROTECTSamples.csv`) | `SampleID` | `sample_id` | per-sample | `PatientNumber`→`patient_id`; the sample tracking roster |
| `clinical_redcap_raw` (clinical) | `subject_id` / `sampleid` | needs map → `patient_id` | per-patient/visit | **gated**; raw has **no `patient_id`** col (keys: `subject_id`, `sampleid`, `record_id`). The integer `patient_id` comes from the warehouse **merged / sample** tables — even the *cleaned* REDCap keys only on `subject_id`/`pro_sample_id` |

## Shortcut: the data may already be joined
Before re-joining anything, check **`integration_pipeline_outputs`** (the warehouse) — it already
contains pre-joined tables: `protect_clinical_isolate_sample_patient_merged_*` (clinical ⨝ isolate ⨝
sample ⨝ patient, 4,405 rows) and `protect_multiomics_isolate_sample_patient_integration_*` (241
samples). The **cleaned clinical** keyed on `patient_id` is there too (`protect_redcap_clinical_clean_*`).

## Canonical recipes
- **Genomic AMR per patient:** aggregate `amrfinder.tsv` per `ASMA_id` → hub (`ASMA_id`→`patient_id`).
- **Phenotype per patient:** pick an assay date in `asma_phenotyping`, join on `ASMA_id` → hub.
- **AMR + growth per patient (Jake's example):** `asma_genomics` (AMR, `ASMA_id`) ⨝ hub ⨝
  `asma_phenotyping` (growth, `ASMA_id`); read `patient_id`/`patient_type` from the hub.
- **Metagenomics by clinical group:** `zengler_metagenomics_mind` (`sample_id`) ⨝ hub
  (`sample_id`→`patient_id`) ⨝ cleaned clinical.

## Gotchas (read before joining)
- **`ASMA_id` is the universal isolate key.** When in doubt, route isolate-level data through it.
- **Two different "sample_id"s exist.** The cohort `sample_id` is `PRO###` (hub, omics, roster).
  SYK's phenotype `sample_id` is an unrelated integer assay id — never cross-join on it.
- **Omics-only rows have blank `ASMA_id`** (163 of 5,182) — they won't match isolate-level joins (expected).
- **AMR is two different things:** genomic *gene predictions* (`asma_genomics/amrfinder.tsv`) vs
  measured *resistance phenotype* (`asma_phenotyping` → `Antibiotic_resistance`).
- **Clinical access is gated.** The manifest can tell you clinical *exists* and its shape, but raw
  REDCap is `gated`; the cleaned, joinable version comes from the integration pipeline.
- **Clinical reaches `patient_id` only via the warehouse.** Raw REDCap keys on `subject_id` /
  `sampleid` / `record_id`; the *cleaned* REDCap keys on `subject_id` / `pro_sample_id`. The integer
  `patient_id` appears in the warehouse **merged / sample / multiomics** tables — use those to bridge.
- **Genomics has two id systems.** `amrfinder`/`metaVF`/`checkm2` use `ASMA_id`; `gtdbtk`/QC use a
  sequencing `sample_id`. Their mapping is unverified in-collection — confirm with Alex.

_Maintained by hand (semantic). To verify items are flagged above and in the per-collection cards._
