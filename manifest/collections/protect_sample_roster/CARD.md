---
# Human-owned card. The crawler NEVER edits this file.
collection_id: protect_sample_roster
maintainer: Spencer Long (Arkin Lab) — DRAFT, pending review by the Zengler team
last_reviewed: 2026-06-15
summary: The cohort sample-tracking roster — one row per collected PROTECT sample (patient, type, omics-vs-isolation designation, population, collection date). Roster file lives in Zengler's dir; the physical samples all originate from the Conrad clinical team. Feeds the integration pipeline.
keywords: [sample roster, sample tracking, PROTECT samples, sample registry, cohort samples, sample metadata, collection date, omics designation, isolation, PatientNumber, SampleID]
related: [patient_sample_isolate_linkage, clinical_redcap_raw, zengler_metagenomics_mind]
---

# PROTECT Sample Roster

> Machine schema and freshness live in the sibling `dataset.yaml`.

## What this is
The **cohort sample-tracking roster** (`*PROTECTSamples.csv`) — one row per collected PROTECT sample
with `SampleID`, `PatientNumber`, `SampleType`, `Omics` (designation), `Sample`, `PatientPopulation`,
`PatientStatus`, `CollectionDate`, and `Days Since First Collection`. It's the registry that tracks
which physical samples exist and how each is designated. **Feeds the integration pipeline.**

## Sample origin (provenance)
The **physical samples all originate from the Conrad clinical team** — clinicians who collect sputum
from patients in the field, then ship it on to Arkin Lab (bacterial isolation) or Zengler Lab (omics
sequencing). This **roster file is maintained in Zengler's directory**, but the samples themselves
are Conrad-collected.

## How it connects (join keys)
- `SampleID` → `patient_sample_isolate_linkage` hub `sample_id`; `PatientNumber` → `patient_id`.
- The **`Omics`** column carries the **isolation-vs-omics designation** (values `Isolation` / `Omics`)
  that the linkage table (v4) uses to split the cohort (isolation samples → ASMA isolates; omics
  samples → Zengler metaG). The **`Sample`** column is the specimen/material type (`Sputum` /
  `Mouth Rinse`), not the isolation-vs-omics flag.

## Example questions this answers
- *"How many PROTECT samples are there, and for which patients?"* → row count + `PatientNumber`.
- *"Is sample PRO### designated for omics or isolation?"* → the `Omics` column (`Isolation` / `Omics`).
- *"When was a sample collected / how long into the study?"* → `CollectionDate`, `Days Since First Collection`.
- *"What population/status is a patient?"* → `PatientPopulation`, `PatientStatus`.

## Caveats & known issues
- **This is a roster, not the canonical registry.** The cleaned canonical cohort registry is the
  linkage table (`patient_sample_isolate_linkage` v4), which is *built in part from* this roster.
  Teams sometimes keep their own rosters — *to verify with Zengler/clinical-coordination that this is
  the authoritative one*.
- Dated filename (`120325PROTECTSamples.csv`); newer versions may appear.

## Access
Open (world-readable). `/usr2/people/protect/Zengler_Lab/`.

## Maintainer & cadence
Roster maintained by the **Zengler team**; samples sourced from **Conrad**. This card: Spencer Long —
**DRAFT pending review**.
