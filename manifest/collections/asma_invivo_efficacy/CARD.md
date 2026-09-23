---
# Human-owned card. The crawler NEVER edits this file.
collection_id: asma_invivo_efficacy
maintainer: Spencer Long (Arkin data team) — curation; Fatemeh Askarian (Nizet Lab) — source data
last_reviewed: 2026-09-23
summary: Mouse lung challenge experiments testing whether ASMA candidate strains engraft and protect against Pseudomonas aeruginosa PA14 (PROTECT Task 3.1), as an immutable raw drop plus regenerated tidy tables.
keywords: [in vivo, mouse, mice, animal model, Nizet, Askarian, Task 3.1, engraftment, PA14, challenge, CFU burden, clinical score, CBC, lung, intratracheal, CD-1, efficacy, histology, IACUC S00227M]
related: [asma_genomics, asma_phenotyping, zengler_metagenomics_mind, patient_sample_isolate_linkage]
---

# ASMA In Vivo Mouse Efficacy (Task 3.1)

> Machine schema, file list, sizes, and freshness live in the sibling `dataset.yaml`.
> This card holds the things a crawler can't know.

## What this is

Mouse experiments from the Nizet Lab (UC San Diego) testing the central Task 3.1
question: do ASMA candidate commensal strains take up residence in the mouse lung,
and do they protect the animal against a later *Pseudomonas aeruginosa* PA14
challenge.

The grain is **one animal**. This is the only PROTECT collection whose unit of
observation is an animal rather than an isolate, a sample, or a patient, which is
why it carries the `IN_VIVO` facet.

Each experiment instils ASMA strains intratracheally, challenges with PA14 24 h
later, and collects lung and blood at a fixed interval. Readouts are colony-forming
unit burden (on selective and non-selective media), a 0 to 5 clinical score, a
Hemavet CBC panel, and in two experiments a histology sample manifest.

## Why it exists / provenance

Delivered by Fatemeh Askarian to Spencer Long on 2026-08-06 as two Excel workbooks
and two protocol PDFs, covering Experiments 5 through 25. Experiments 1 to 4 were
Ribo-seq mouse-model optimisation and were deliberately excluded by the Nizet lab.
**There is no Experiment 12** in either the data or the protocols. Confirmed
2026-08-31: it was a PA dose-optimization study, superseded by Exp.13 which repeated
the optimization in the presence of ASMA#2260 engraftment, so the lab omitted it
deliberately. Not missing.

The collection root holds two things, and the distinction is load-bearing:

| Subtree | Role | Rule |
|---|---|---|
| `data_dump_8_7_26/` | The raw drop as received. System of record. | **Never edit.** Only additions to its `docs/` are allowed. |
| `invivo_curated/` | Tidy tables, protocol sidecars, review worklists. | Fully regenerated from the raw drop. Never hand-edit. |

`invivo_curated/` rebuilds deterministically:

```
cd /usr2/people/protect/Nizet_Lab/invivo_curated
python3 build/build_nizet_invivo.py && python3 build/validate.py
```

`build/validate.py` runs the integrity suite (referential integrity across all
foreign keys, the value/qualifier contract, unit declaration, date ordering). Treat
a build whose validation does not come back clean as unusable.

Read `data_dump_8_7_26/docs/HANDOFF_2026-08-11.md` before doing anything with this
collection. Live status is on Jira **PROTECT-9** (label `ws-nizet-invivo`); the lakehouse load,
`protect.invivo`, is **PROTECT-25** (`ws-nizet-invivo-ingest`).

## Table roles

`invivo_curated/tables/`, each as `.csv` and `.parquet`:

| Table | Grain | Holds |
|---|---|---|
| `strains` | one per strain | ASMA ID to species map, and each strain's role |
| `experiments` | one per experiment | title, strains used, dates, dose block, date provenance |
| `groups` | one treatment arm | mouse number range, normalised treatment, cage card |
| `mice` | one animal | group membership, exclusion status and reason |
| `measurements` | one animal x assay x analyte x medium | every reading, long format |
| `histology_samples` | one submitted sample | the histology manifests |

**The ASMA-to-species map exists only in the protocol PDFs**, nowhere in the
spreadsheets. `strains` is the machine-readable version of it, and is the reason the
PDFs are worth keeping alongside the workbooks. Same for the per-experiment dosing.

## How it connects (join keys)

- `asma_id` is the ASMA isolate number in **bare form** (`2260`, a co-culture
  `2260|3913`), on every table. **It does not join directly** to `asma_genomics` (Alex
  Styer's taxonomy spine) or `asma_phenotyping` (Sun-Young Kim's in vitro screens),
  which write `ASMA-2260`: split the pipe list and add the `ASMA-` prefix first, or the
  join silently returns nothing. With that, a strain's in vitro competition result and
  its in vivo protection result can be put side by side. (Corrected 2026-09-23: this
  line said the key joined directly; it never did, since the build wrote `ASMA2260`.)
- `mouse_uid` is synthesised by the build (`EXP##_M###`) because **mouse numbers
  restart at 1 in every experiment** and the source carries no globally unique
  animal identifier. It is stable across rebuilds. Do not expect the Nizet lab to
  recognise it.
- **There is no join to the Task 3.2 sequencing.** Four protocols (Exps 17, 18, 19,
  22) state that remaining lung homogenates went to the Zengler lab for
  culture-independent community analysis, but no mouse or sample identifier was
  recorded on either side. Connecting this collection to
  `zengler_metagenomics_mind` is therefore **not currently possible for any
  animal**. Recovering that bridge is the single highest-value outstanding ask of
  the Nizet lab. Do not assume a join exists because both collections mention the
  same experiments.
- There is no patient linkage. This is an animal model; it does not touch
  `patient_sample_isolate_linkage`.

## Example questions this answers

- *Which ASMA strains have been tested in a mouse, and against PA14 or alone?*
  `experiments.asma_strains` and `experiments.pa_challenge`, or `groups.treatment`.
- *Does strain X reduce PA burden in the lung?* Filter `measurements` to
  `assay == 'cfu_burden'`, `compartment == 'lung'`, **`selective_for == 'PA14'`**,
  then compare the PA-only arm against the ASMA+PA arm via `mice.group_id`. **Group
  by `unit` first**, see caveats. Do not filter on `medium == 'cetrimide'`: in Exps 7,
  8, 10, 11 and 13 PA was counted on LB + tetracycline, and that filter misses them.
- *Did strain X itself engraft?* Only the ASMA2260R reporter has a strain-selective
  count: `selective_for == 'ASMA2260R'` (Exp.24). For every other strain, compare the
  `non_selective` count (TSA/blood, or LB in Exps 5-13) between the PBS and engrafted
  groups, see caveats.
- *Were the animals sick?* `assay == 'clinical_score'`, 0 to 5, higher is worse.
  The scale is printed on the source sheets and reproduced verbatim in
  `invivo_curated/docs/DATA_DICTIONARY.md` (it is not in the protocol sidecars).
- *What was actually delivered, at what dose, on what schedule?*
  `experiments.delivered_dose_json` and the per-experiment YAML sidecars, which
  carry the IACUC number, anaesthesia, media, instruments and timings extracted
  from the protocol PDFs. **Apart from title, doses and dates the sidecars are the
  same for every experiment**, so do not read them as per-experiment facts.
- *Which animals should be left out?* `mice.excluded`, see caveats.

## Data dictionary (key columns)

Full column list is in `dataset.yaml`; the authoritative narrative dictionary is
`invivo_curated/docs/DATA_DICTIONARY.md`. The three that decide whether an analysis
is right:

- **`measurements.qualifier`** — the vocabulary that keeps a non-measurement from
  becoming a number. Domain: `measured`, `none_recovered` (plated, nothing grew),
  `not_assessed` (NA), `not_recorded` (blank in a populated column), `animal_dead`,
  `excel_error`, `note_in_cell`, `not_detected` (retained, does not occur in the
  current build). **`value` is populated for `measured`, and for `none_recovered`
  only in a linear CFU column.** A `none_recovered` row in a *log10* column carries
  no value, because log10(0) is undefined. Every other qualifier means there is no
  number, and `validate.py` enforces the whole contract.
- **`measurements.value_raw`** — the source cell verbatim, always retained, so any
  interpretation can be re-checked against what was actually written.
- **`experiments.date_status`** — whether an experiment's dates can be trusted.
  Domain: `confirmed_unambiguous` (read cleanly from the source),
  `quarantined_pending_confirmation` (contradictory or ambiguous, fields left
  null), `confirmed_by_investigator` and `partially_confirmed` (answered by the
  Nizet lab through `review/answers/`). `experiments.date_source` records which.

## Caveats & known issues

This collection is **curated but not yet resolved**. The tables are structurally
sound and validated; several values are still open questions with the source lab.
An analysis that ignores the following will produce wrong numbers.

1. **Blood CFU units are inconsistent between experiments.** Some sheets record raw
   `cfu_per_ml`, others `log10_cfu_per_ml`, under near-identical source headers.
   **Always group by `unit`.** Pooling them silently is a real and easy analysis
   error.
2. **RESOLVED 2026-08-31, but it still changes how you use the data.** In a CFU
   column, `ND`, `N/A`, blank and `0` all mean no colonies were recovered, and
   because the lab plates a dilution series aiming for 20-200 CFU per plate these
   are **actual measurements, not below-detection values**. There is no per-medium
   limit of detection to record. 255 rows now carry `qualifier == 'none_recovered'`.
   **The catch:** in a *log10* column such a result has no value, because log10(0)
   is undefined, so those rows carry a NULL `value` and the meaning lives in the
   qualifier. In a linear CFU column the value is a real `0`. Carrying the sentinel
   zeros as values was a live analysis error: the mean of `log10_cfu_per_g` was
   4.5251 before the fix and is 4.9076 after. If you need these animals on a log
   axis, choose a floor explicitly and say which you used.
3. **19 of 481 animals are excluded: 16 died and 3 were excluded by the
   investigator.** The source records a death five different ways (in the mouse
   cell, the Treatment column, a measurement cell, a column with no header, or a
   sentence below a block), and until 2026-09-23 the build marked only 7 of the 16.
   Every death excludes the animal, procedural ones included; the cause is kept in
   `exclusion_reason`. **Filter `mice.excluded == False`.** A naive export of the
   original workbooks silently readmits these animals.
4. **Non-selective plate counts are not strain-specific. CONFIRMED by the
   investigator 2026-08-31.** PBS control animals show real counts on TSA/blood
   agar, because that count is the background lung microbiome. Only the selective
   plates are organism-specific, and **the same antibiotic selects different
   organisms in different experiments**: LB + tetracycline counted PA in Exps 7, 8,
   10, 11 and 13, while a tetracycline plate counts the ASMA2260R reporter in
   Exp.24. `measurements.selective_for` states which, on every CFU row.
   Engraftment is assessed the way the Nizet lab does it: by comparing TSA/blood
   counts between the PBS group and the engrafted group, not by reading a
   non-selective count on its own.
5. **Most experiments' dates are quarantined.** A day/month locale swap was applied
   to some cells and not others, mixed with raw Excel serials and plain text, so
   there is no blanket rule. Contradictory dates are left null rather than guessed.
   Check `date_status` before using any date, and expect nulls.
6. **One experiment's CBC block is misaligned by one row** and is unusable until the
   source lab realigns it. An unlabelled row displaces every analyte label below it,
   so the values are attached to the wrong analytes. Orphaned values are preserved
   under analyte `__UNLABELED__`. The affected experiment is itemised in
   `invivo_curated/review/suspected_errors.csv`.
7. **Sheet titles are not trustworthy.** At least one experiment's title and
   "Strains" line are a stale copy from a different experiment. The build derives
   strains from the dose block and group table only, and flags any title that
   disagrees. Do not read strain identity off a sheet name.
8. **Suspected errors are flagged, never corrected.** Everything the build doubts is
   itemised in `invivo_curated/review/suspected_errors.csv` with a severity, and
   left unaltered in the tables. Corrections arrive from the source lab through
   `invivo_curated/review/answers/` and are applied by a rebuild.
9. **Several datasets referenced in the protocols were not delivered**: reporter
   luminescence, histopathology scores (manifests exist, results do not), LDH beyond
   one experiment, and the raw plate counts, dilution factors and lung weights behind
   the derived log10 values.

**Partially revised 2026-09-02** after the Nizet lab's replies of 2026-08-31.
Caveats 2 and 4 are now answered rather than open. Caveats 1 (blood units), 5
(quarantined dates) and 6 (the misaligned CBC block) are still outstanding.
Caveat 9 shrank: Experiment 12 was a PA dose-optimization study superseded by
Exp.13, deliberately omitted rather than lost. Treat the remaining caveats as
current.

**Revised 2026-09-23** after an extraction audit of every source cell
(`invivo_curated/docs/EXTRACTION_AUDIT_2026-09-23.md`, PROTECT-25). Everything the
build had extracted was exact, but it had skipped Experiment 18's entire CBC block
(450 readings), left 9 of 16 deaths unmarked, never applied one documented
exclusion, dropped 14 investigator notes and 2 challenge dates, and recorded nothing
about which organism a selective plate counted. All fixed; no extracted value
changed. New since then: the `source_annotations` table (every investigator note,
verbatim), and the columns `selective_for`, `asma_id`, `reporter_strain` and
`source_formula`. **Caveats 3 and 4 were corrected**: this card previously said the
buried exclusion was captured and that tetracycline meant the reporter.

## Recommended uses / not for

**Good for:** which ASMA strains and combinations have been tested in an animal;
relative PA burden between treatment arms within a single experiment; clinical
score comparisons; recovering what was actually dosed and on what schedule; linking
in vivo results back to isolate genomics and in vitro phenotyping through `asma_id`
(bare numbers here, `2260`; the genomics and phenotyping tables write `ASMA-2260`, so
add the prefix to join).

**Not for, yet:** pooling burden across experiments without checking `unit`; any
analysis that turns on the meaning of a zero or on a limit of detection;
time-series or cross-experiment chronology (most dates are quarantined); anything
using the misaligned CBC block; joining to Task 3.2 community sequencing, which has
no identifier bridge.

**Not a substitute for** the raw drop. When a number matters, `value_raw` and the
`source_cell` reference take you back to the exact cell.

## Access

Open on `thar` (world-readable). Group `protect-nizet`. Nothing here is
patient-derived, so it carries no clinical sensitivity. Mirrors
`dataset.yaml.access`.

The **source data is the Nizet Lab's**, and courtesy applies: it was shared for
PROTECT integration. Loop in Fatemeh Askarian before presenting or publishing
figures derived from it.

## Maintainer & cadence

Curation and the build: Spencer Long, Arkin data team. Source data: Fatemeh
Askarian, Nizet Lab, UC San Diego (faaskarian@health.ucsd.edu), cc Armin Kousha and
Sharon Yau.

Cadence is **per drop, not continuous**. Source Data 3 is expected from the Nizet
lab in October 2026; the build is designed to absorb it by re-running one script.
A recording template was offered to the source lab to keep later drops in a shape
that needs no reshaping; it lives in `Nizet_Lab/source_data_3_template/`.

Status, open questions and the definition of done are tracked on Jira **PROTECT-9**
(label `ws-nizet-invivo`), not in this card.
