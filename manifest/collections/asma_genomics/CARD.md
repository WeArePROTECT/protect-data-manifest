---
# Human-owned card. The crawler NEVER edits this file.
collection_id: asma_genomics
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by Alex Styer
last_reviewed: 2026-06-15
summary: Genomic characterization of the ~4,900 ASMA bacterial isolates (mostly P. aeruginosa) — assemblies, taxonomy, AMR gene predictions, virulence factors, metabolic-pathway predictions, and QC. The genomic half of the ASMA collection. Join to the rest of PROTECT via ASMA_id.
keywords: [genome, genomics, assembly, annotation, AMR, amrfinder, antibiotic resistance genes, resistance gene predictions, virulence, metaVF, virulence factors, gapmind, metabolic pathways, GTDB, taxonomy, gtdbtk, checkm2, busco, genome QC, Pseudomonas aeruginosa, PA, isolate genomes, strain clusters, ANI, fastani, mash, prophage, phage]
related: [patient_sample_isolate_linkage, asma_phenotyping, zengler_metagenomics_mind]
---

# ASMA Bacterial Genomics (Alex Styer)

> Machine schema, file list, sizes, and freshness live in the sibling `dataset.yaml`.
> **Richest source:** Alex maintains his own detailed, daily-updated manifest at
> `/usr2/people/alex.styer/protect/MANIFEST.md` (federated; see `dataset.yaml.owner_manifest`).
> This card is the catalog-level summary; defer to Alex's manifest for assembly/annotation internals.

## What this is
Genomic characterization of the **ASMA isolate collection** — ~4,900 bacterial isolates (primarily
*Pseudomonas aeruginosa*) cultured from CF and non-CF bronchiectasis patient sputum. Each isolate has
short-read assembly + annotation; a subset also have Nanopore long reads / hybrid assemblies (those
isolates appear in `nanoplot-summary.tsv` — see the descriptor for the current set). This is the
**genomic half of the ASMA collection** (the phenotype half is
`asma_phenotyping`).

## Why it exists / provenance
Produced by Alex Styer's Snakemake pipelines (assembly: fastp → SPAdes → BUSCO/CheckM2; annotation:
Bakta → 16S → AMRFinder → MetaVF → GapMind). Aggregated per-isolate results are compiled to the
collection-root TSVs below. Authoritative build details: Alex's `MANIFEST.md`.

## How it connects (join keys)
- **`ASMA_id`** is the universal isolate key — it ties every genomic table here to the
  `patient_sample_isolate_linkage` hub (→ `patient_id`, `sample_id`) and to `asma_phenotyping`.
- GapMind tables use **`isolate_id`** (same identifier as `ASMA_id`).
- QC / taxonomy tables (`gtdbtk`, fastqc, nanoplot) carry a sequencing **`sample_id`**, while
  `amrfinder` / `metaVF` / `checkm2` carry **`ASMA_id`**. The `sample_id`↔`ASMA_id` relationship is
  **not clearly documented in-collection** (`gtdbtk/assembly-manifest.tsv` maps `genome_id`↔`sample_id`,
  *not* to `ASMA_id`) — **to verify with Alex** before joining taxonomy/QC to isolate-level data.
- ⚠️ **Cardinality:** `amrfinder.tsv`, `metaVF.tsv`, and the GapMind tables are **many rows per
  `ASMA_id`** (one per gene hit / pathway rule). **Aggregate before joining** (e.g. pivot AMR to
  gene presence/absence per isolate) or a join to per-patient data will fan out badly. `checkm2-*`
  and `busco-summary` are ~one row per assembly.

## Example questions this answers
- *"What AMR resistance genes does each isolate carry?"* → `amrfinder.tsv` (AMRFinderPlus gene calls), key `ASMA_id`; filter on `Element symbol` / `Class` / `Subclass`.
- *"Which isolates carry which virulence factors?"* → `metaVF.tsv`, key `ASMA_id` (+ `gene_id`).
- *"What's the taxonomy / species of an isolate?"* → `gtdbtk/gtdbtk-summary.tsv` (one row per assembly; GTDB lineage in the **`classification`** column, keyed on `sample_id`). Bacterial-only output: `gtdbtk/classify/gtdbtk.bac120.summary.tsv`.
- *"How good is the genome assembly for isolate X?"* → `checkm2-summary.tsv` (completeness/contamination), `busco-summary.tsv`.
- *"Which carbon/amino-acid pathways are genomically present?"* → `gapmind-carbon-rules.tsv` / `gapmind-aa-rules.tsv`, key `isolate_id`.
- *"AMR per patient"* → aggregate `amrfinder.tsv` per `ASMA_id` ⨝ `patient_sample_isolate_linkage` (`ASMA_id`→`patient_id`).

## Data dictionary (key files)
| File | Holds | Key |
|---|---|---|
| `amrfinder.tsv` | AMR **gene predictions** (AMRFinderPlus); one row per hit | `ASMA_id` |
| `metaVF.tsv` | Virulence-factor BLAST hits | `ASMA_id`, `gene_id` |
| `gapmind-carbon-rules.tsv`, `gapmind-aa-rules.tsv` | Genomic metabolic-pathway completeness (carbon / amino-acid biosynthesis) | `isolate_id` |
| `checkm2-summary.tsv` / `checkm2-all.tsv` | Assembly QC (completeness, contamination, N50, …) | `ASMA_id` |
| `busco-summary.tsv` | BUSCO assembly completeness | `ASMA_id` |
| `fastqc-summary.tsv`, `nanoplot-summary.tsv` | Read QC (short / long read) | `sample_id` |
| `c-sources.xlsx` | Carbon-source reference (formulae, SCFM recipe) | — |
| `gtdbtk/gtdbtk-summary.tsv` | GTDB taxonomy (`classification` lineage), one row per assembly | `sample_id` |
| `gtdbtk/classify/gtdbtk.bac120.summary.tsv` | Bacterial-only GTDB-Tk summary | `user_genome` |
| `fastani/ani-clusters.csv`, `mash/clusters.csv` | Strain clustering (ANI / mash groups) | per-genome |
| `isolates/ASMA-{id}/` (excluded from file-listing) | Per-isolate assemblies + annotations | `ASMA_id` |

## Caveats & known issues
- **AMR appears in two collections — don't confuse them.** Here, `amrfinder.tsv` = *genomic AMR
  gene predictions*. Measured antibiotic-resistance *phenotype* (MICs) lives in `asma_phenotyping`
  (`ASMA_phenotype_20250420.xlsx`, `Antibiotic_resistance` sheet). Pick the one the question means.
- **Per-isolate trees are intentionally not file-described.** The crawler now descends into the
  analysis subdirs (`gtdbtk/`, `fastani/`, `mash/`, `PA-exploratory/`, …), but **excludes** the
  ~4,940 `isolates/` dirs and `gapseq/` (far too many files to catalog individually). For per-isolate
  internals, see Alex's `MANIFEST.md`.
- Cardinality (see above) — aggregate gene/pathway tables before per-patient joins.

## Access
Open (world-readable), but **outside the core PROTECT tree** at `/usr2/people/alex.styer/protect/ASMA`.

## Maintainer & cadence
Data owner: **Alex Styer** (Arkin Lab), who actively maintains `MANIFEST.md` + a `CHANGELOG.md`.
This catalog card: Spencer Long — **DRAFT pending Alex's review** for accuracy of join semantics and
the `sample_id`→`ASMA_id` mapping.
