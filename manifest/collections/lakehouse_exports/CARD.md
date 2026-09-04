---
# Human-owned card. The crawler NEVER edits this file.
collection_id: lakehouse_exports
maintainer: Spencer Long (Arkin Lab)
last_reviewed: 2026-09-04
summary: Dated snapshot exports of PROTECT tables staged to/from the KBase lakehouse, across nine live namespaces. The window into what exists in the lakehouse for people who can't query it directly yet. As of 2026-09-03 this includes the SOW Task-2.1 formulation exclusion screen, SYK's phenotyping, the ASMA stock registry, and the strain-level decision card.
keywords: [lakehouse, KBase, data lake, exports, formulation, competition screen, exclusion screen, SynCom, phenotype, growth curve, hemolysis, antibiotic resistance, AMR genes, virulence factors, ASMA stock list, FREP plate map, decision card, unified sheet, shortlist, txt export tables, integration export, mind-analysis export, genome-analysis export, taxonomy, isolate taxonomy, GTDB, strain group, lakehouse tables, staged data, cleaned tables, silver layer, refinery bronze, genomedepot, eggNOG, KEGG, browser tables, NAMESPACES.md]
related: [patient_sample_isolate_linkage, zengler_metagenomics_mind, asma_phenotyping, asma_genomics]
---

# KBase Lakehouse Exports

> Machine facts and the **dated export subdirectories** live in the sibling `dataset.yaml`.

> ## ⛔ Do not use `protect.refinery_bronze` as a data source
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
> **Use `protect.genome_analysis.isolate_taxonomy` instead** — **live on the lakehouse since
> 2026-08-19**, verified (row counts + 17 smoke tests all passed). 4,927 isolates, one row each,
> `asma_id` unique. Column-by-column docs:
> `protect_lakehouse_pipeline/datasets/genome-analysis/docs/data_dictionary.md`.

> ## ⛔ `protect.integration` destroys clinical data, and the repair did not fix it
>
> `pd.read_csv` reads the string `'None'` as missing. In PROTECT's REDCap data `'None'` is a
> **real clinical category** meaning *confirmed on no antibiotics* / *no CFTR modulator*, which
> is not the same as unknown. PROTECT-11 guarded four reads and closed; it was not enough,
> because `stage1_redcap_clean.py:312` reads the raw export unguarded and is **upstream of all
> four**. In `airway_clearance` the source column has **no genuinely missing values at all**, so
> **100% of its NULLs are destroyed data**. Lowercase `'none'` survives and `'None'` does not.
>
> Four more defects of the same shape are open: columns declared `BOOLEAN` that hold `Yes`/`No`,
> free text, or undecoded REDCap codes. **Treat every categorical in this namespace as suspect
> until PROTECT-12 closes.** Full analysis:
> `protect_lakehouse_pipeline/docs/na_coercion_sweep_2026-08-28.md`.

> ## ⚠ `protect.curated` is DERIVED. Not one column in it is a measurement.
>
> The Formulation Unified Data Sheet. Values are **aggregated to strain grain and cut by
> team-owned thresholds**; a column there answers *"what did we decide"*, not *"what was
> measured"*. Every gate and cutoff is a **provisional default the biologists own**, not a
> finding. **A blank cell means "not screened yet", not "no result".** `is_candidate = True`
> means *"not a known pathogen"*, **NOT** *"safety cleared"*.
>
> **For the measurements go to `protect.phenotype`, `protect.formulation`,
> `protect.genome_analysis`.**
>
> Gwyn Hutchinson's tissue data is **deliberately excluded** pending her sign-off (PROTECT-5):
> `silver_tissue` is absent and `gold_unified_sheet` carries 31 columns, not the sheet's 33.

> ## ⚠ In `isolate_amr_genes` and `isolate_virulence_factors`, `'NA'` is a VALUE, not a null
>
> Both files encode **"this isolate was screened and NOTHING was found"** as a placeholder row
> whose every field except `asma_id` is the literal string `NA`: **943 rows in amrfinder** (943
> distinct isolates, 19% of the 4,923 present) and **2,911 in metaVF**. Those rows are the only
> record that the isolate was screened at all, which is a different fact from being absent.
> **Do not filter them as junk.**
>
> Separately, in `protein_id` **empty and `'NA'` are not synonyms**: `'NA'` (943) is the
> placeholder, `NULL` (1,059) is a **real hit with no callable protein**.
>
> Numeric-looking columns (`start`, `stop`, `pct_identity_to_reference`, …) are **STRING**
> because they carry that `'NA'`. Typing them numerically nulls exactly those rows.

> ## ⚠ A blank hemolysis call means "not determined", not "negative"
>
> `protect.phenotype.hemolysis_screen.beta_hemolysis_24h` has 1,168 calls over 1,638 rows.
> **167 of the blanks are rows where `growth = 'N'`** — no growth, so no call was possible; the
> rest were read only at 48h/72h. **Counting `= 'N'` as "safe" misreads 470 of 1,638 rows.**

## What this is
**Dated export snapshots** of PROTECT tables staged to the KBase lakehouse. This collection is the
**bridge for people without lakehouse access**: it lets them see *what has been pushed to the lake
and when*, even though they can't query the lakehouse directly yet. The exports are organized by
**namespace**, each staged as dated snapshot dirs:

| Namespace dir pattern | What it holds |
|---|---|
| `integration_export_<date>/` | `protect.integration` — the linked/cleaned tables |
| `mind-analysis_export_<date>/` | `protect.mind` — Zengler MIND outputs. ⚠ built from a **superseded April 2026 vintage**; refresh tracked as PROTECT-17 |
| `phenotype_export_<date>/` | `protect.phenotype` — **live 2026-09-03**, 12 tables / 20,353 rows. SYK bench assays (growth endpoint, growth curves, antibiotic resistance v1+v2, carbon utilization) + Cassie Reyes's hemolysis screen and its re-screen |
| `formulation_export_<date>/` | `protect.formulation` — **live 2026-09-03**, `competition_screen`, **28,928 rows**. The SOW Task-2.1 in-vitro exclusion screen: 0–5-member SynComs vs 8 pathogen reporters |
| `reference_export_<date>/` | `protect.reference` — **live 2026-09-03**, `asma_stock_list` (3,972 isolates + freezer location) and `asma_frep_plate_map` (784 wells) |
| `curated_export_<date>/` | `protect.curated` — **live 2026-09-03**, 17 tables / 19,081 rows. The Formulation Unified Data Sheet. ⚠ **DERIVED, not measurements** — see the warning below |
| `genome-analysis_export_<date>/` | `protect.genome_analysis` — **live 2026-08-19**: `isolate_taxonomy` (4,927, one per **isolate**, `asma_id` unique) + `genome_taxonomy` (5,725, one per **assembly**) |
| `genome-features_export_<date>/` | `protect.genome_analysis`, **added 2026-09-03**: `isolate_amr_genes` (34,082), `isolate_virulence_factors` (172,263), `isolate_ani_clusters` (599). ⚠ **`'NA'` is a VALUE here** — see below |
| `genome-sequences_export_<date>/` | `protect.genome_analysis` — `contig_sequences`, 7,785,073 rows |
| *(not staged here)* | `protect.genomedepot` — 39 `browser_*` tables mirrored from the GenomeDepot MariaDB. **Its exports stage from a different directory**, so they do not appear in this collection. **Refreshed 2026-09-04**: 46,321,767 → 92,916,568 rows, the growth entirely **functional annotation** (eggNOG, KEGG, GO, COG, CAZy, TC). ⚠ **Any GenomeDepot function analysis predating 2026-09-04 saw almost no annotation data** — `browser_eggnog_description` was 91 rows and is now 30,359 |
| `refinery-bronze_export_<date>/` | `protect.refinery_bronze` — aparkin's frozen Bronze refinery. **⛔ NOT A CURATED SOURCE — see the warning below** |
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
  **Read the `protect.integration` warning above before using it for anything clinical.**
- *"What's been pushed to the lakehouse, and when?"* → the dated export subdirs (`dataset.yaml` `subdirectories`).
- *"MIND analysis in the lakehouse?"* → the newest `mind-analysis_export_<date>/`. ⚠ superseded vintage; PROTECT-17.
- *"Where is the formulation / exclusion screen?"* → `protect.formulation.competition_screen`, 28,928 wells, live 2026-09-03. The SOW Task-2.1 deliverable.
- *"Which strains beat PA, and are they safe?"* → `protect.curated.gold_unified_sheet` for the decision card, `protect.curated.formulation_shortlist` for the ranked list. **Both derived — read the warning above.**
- *"Where is a strain physically stored?"* → `protect.reference.asma_stock_list`.
- *"Which isolates carry AMR genes?"* → `protect.genome_analysis.isolate_amr_genes`. **Read the `'NA'` warning above first.**

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

**Per-namespace documentation** now lives beside the code, one README per namespace, each leading
with what will bite a reader: `protect_lakehouse_pipeline/datasets/<name>/README.md`. The run
record for the 2026-09-03 formulation push, including every `dump_path` and the verification
result, is `protect_lakehouse_pipeline/datasets/_runs/formulation_push_20260903/README.md`.
**The complete index of what is on the lakehouse** — every namespace, table, row count, layer
and status, indexed both namespace-to-directory and directory-to-namespace — is
`protect_lakehouse_pipeline/NAMESPACES.md`. It covers `protect.genomedepot` too, which does not
stage through this collection.

The binding rule for **which namespace a new dataset belongs in** is
`protect_lakehouse_pipeline/docs/lakehouse_ingestion_ruleset.md` §4b-bis. The rule for **where a
dataset's code and documents live** is §10 of the same file (PROTECT-18, 2026-09-04).
