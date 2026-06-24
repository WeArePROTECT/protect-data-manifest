# PROTECT Data Manifest — Handoff to the Next Agent

| | |
|---|---|
| **From** | Claude (with Spencer Long), session of 2026-06-15 |
| **Status** | **v0 built, hardened, validated, and LIVE on a nightly cron.** 8 collections, all carded. Pipeline verified end-to-end and scheduled (2 AM UTC). Exhaustive card↔data accuracy audit complete (2026-06-15): all 8 cards checked file-by-file/column-by-column against the real data; 6 cards had mismatches, all fixed; manifest-only agent battery re-passed 8/8 with zero hallucinations. Cards still DRAFT pending owner review. |
| **Repo** | `/usr2/people/protect/protect-data-manifest` (= `/auto/sahara/namib/home/protect/protect-data-manifest`) |
| **This is the single source of truth for current state.** Read it fully before doing anything. | |

---

## 0. Get oriented (≈5 minutes)
Read in this order:
1. **This file.**
2. `README.md` — the project entry point.
3. `manifest/INDEX.md` — the catalog (what an agent reads first; grouped by team + facet index).
4. `manifest/LINKAGE.md` — the cross-collection join map.
5. `skill/SKILL.md` — the navigation protocol (how an agent uses the manifest).
6. Rationale: `docs/research/2026-06-15_catalog-landscape-and-design.md` and `docs/decisions/2026-06-15_audit-and-design-notes.md`.
7. Deferred items: `docs/decisions/notes_deferred.md`. Original plan: `docs/roadmap/protect_data_manifest_roadmap_v1.md` (partially superseded — see its Status section).
8. Full project history lives in Claude's memory at `…/.claude/projects/-auto-sahara-namib-home-protect/memory/project_data_manifest.md`.

---

## 1. The objective (why this exists)
Jake (after Adam & Alex) asked for a **PROTECT-wide manifest** a team member can point their Claude
agent at to find data, understand its structure, and see how datasets connect. His example: *"take the
ASMA collection and filter it for hemolytic activity, AMR gene predictions, and growth phenotypes."*
The recurring problem: finding PROTECT data depends on tribal memory and Slack pings, and many
scientists lack KBase-lakehouse access. **Goal:** an agent-readable catalog that points to data
**in place**, is world-readable (metadata only), and auto-refreshes so it never goes stale. This
supports the team's pneumonia research.

---

## 2. What was built (current state — v0)
- **8 collections, all with human cards**, under `manifest/collections/<id>/`. Each is a **data
  product** described by **two files**: `dataset.yaml` (crawler-generated machine facts — schema,
  sizes, access, freshness, subdir digests) + `CARD.md` (human narrative — meaning, join recipes,
  caveats, example questions). The standard is in `templates/README.md`.
- **The 8 collections** (id — team — what):
  - `patient_sample_isolate_linkage` — Arkin data team — **the canonical join hub** (v4 gold linkage, 5,182 rows; keys `ASMA_id`/`patient_id`/`sample_id`).
  - `integration_pipeline_outputs` — Arkin data team — **the warehouse**: cleaned + pre-joined tables (cleaned REDCap clinical, merged clinical⨝isolate⨝sample⨝patient, multiomics). Auto-follows the newest dated run.
  - `lakehouse_exports` — Arkin data team — dated snapshots staged to the KBase lakehouse.
  - `clinical_redcap_raw` — Conrad — raw REDCap clinical exports (**gated**).
  - `asma_genomics` — Styer — isolate genomics (AMR `amrfinder.tsv`, virulence `metaVF.tsv`, GapMind, `gtdbtk` taxonomy, QC). Has a federated owner manifest at `/usr2/people/alex.styer/protect/MANIFEST.md`.
  - `asma_phenotyping` — Kim (SYK) — growth/carbon/reporter/measured-AMR phenotypes.
  - `zengler_metagenomics_mind` — Zengler (Emma) — metaG/metaRS OGU feature tables + MIND (large).
  - `protect_sample_roster` — Zengler — cohort sample roster (samples originate from Conrad).
- **Tooling** (`crawler/`): `crawl.py` (descriptors), `build_index.py` (catalog), `freshness_report.py`
  (diff/triage), `run_pipeline.sh` (all three, for cron), config in `collections.yaml`.
- **Outputs:** `manifest/INDEX.md` (catalog), `manifest/LINKAGE.md` (join map), `manifest/FRESHNESS.md`
  (nightly triage), `skill/SKILL.md` (the skill).
- **Validation:** 12 fresh, manifest-only agent tests across two audit rounds — **zero hallucinations**;
  agents reliably locate data, give exact files/columns/joins, honor gated access, and honestly say
  "not found" when data is absent.

---

## 3. Key design decisions (don't undo these without good reason)
- **Catalog, not warehouse** — points to data in place; copies nothing.
- **Discovery decoupled from access** — metadata is world-readable; access status is recorded + routed, not granted.
- **Two files per collection** — the crawler owns/regenerates `dataset.yaml`; humans own `CARD.md`. Neither clobbers the other.
- **Federation** — link owner-maintained manifests (e.g. Alex's `MANIFEST.md`); don't re-describe them.
- **Naming** — collection ids lead with the stable **data domain**; team/owner/version/state are metadata; grouped by team. (So new data from a team is a new product, never a rename.)
- **Machine-verified freshness** — `last_crawled` + real source mtime, never a hand-typed date.
- Grounded in FAIR / Frictionless Data Package / Datasheets for Datasets / Data Mesh (see research doc).

---

## 4. How to run it
```
python3 crawler/crawl.py [--only <id>]   # regenerate dataset.yaml (all, or one collection)
python3 crawler/build_index.py           # regenerate manifest/INDEX.md
python3 crawler/freshness_report.py      # regenerate manifest/FRESHNESS.md + save snapshot
crawler/run_pipeline.sh                  # all three in order; logs to crawler/pipeline.log (for cron)
```
- **Environment:** python3 + PyYAML + openpyxl + pyarrow. **Do NOT use pandas** in the crawler — this
  env has a NumPy 1.x/2.x ABI conflict that makes pandas spew warnings; the lightweight readers avoid it.
- **Config:** add/edit collections in `crawler/collections.yaml`. Per-collection options: `team`,
  `domain`, `owner`, `tags`, `scan_depth`, `max_resources`, `exclude_dirs`, `resource_globs`,
  `deep_size`, `pick_latest_subdir`, `request_to`.

---

## 5. Gotchas & errors we found and FIXED (so they don't recur)
**The big class — cards asserting join keys that don't exist in the data.** Found via the agent
battery, verified against real schemas, and corrected:
- `clinical_redcap_raw` has **no `patient_id`** column — real keys are `subject_id` / `sampleid` / `record_id`.
- The **cleaned** clinical (`protect_redcap_clinical_clean` in the warehouse) keys on `subject_id` / `pro_sample_id`, **also not `patient_id`** — `patient_id` lives in the warehouse **merged / sample / multiomics** tables (use those to bridge).
- `zengler_metagenomics_mind` OGU tables carry `PRO###` as **column headers** (wide), not a key field; `PROTECT sample metadata.xlsx` has `sample_name` + `library_ID` + `patient_id` **directly**.
- `asma_genomics` has **two id systems**: `amrfinder`/`metaVF`/`checkm2` use `ASMA_id`; `gtdbtk`/QC use a sequencing `sample_id`. Their mapping is **unverified in-collection** (to confirm with Alex).
- Warehouse key names differ across files: **merged uses `pro_sample_id`, multiomics uses `sample_id`**.

**Other fixes:**
- The April-2026 `protect_directory_inventory` had a **stale path** (`alex.styer/ASMA` → actually `alex.styer/protect/ASMA`). Lesson: **verify against the live filesystem; don't trust prior docs.**
- `gtdbtk-summary.tsv` was missing from the descriptor (the ~4,940 per-isolate dirs ate the file cap) → fixed with `exclude_dirs: [isolates, gapseq, …]`.
- Gated clinical's `request_to` was vague → now names the Conrad team / dir owner / Spencer as broker (per-collection `request_to`).

**Standing gotchas (real, documented in cards + LINKAGE.md):**
- **Two different "sample_id"s:** cohort `PRO###` vs SYK's integer assay id — never cross-join on the wrong one.
- **Omics-only rows have blank `ASMA_id`** (163 of 5,182) — they won't match isolate-level joins.
- **"AMR" is two different things:** genomic gene predictions (`asma_genomics/amrfinder.tsv`) vs measured MICs (`asma_phenotyping` → `Antibiotic_resistance`).
- **Warehouse outputs vary by run;** use the newest (the crawler auto-follows via `pick_latest_subdir`). Not every run contains every table.
- **`candidate_keys` in `dataset.yaml` is a loose heuristic** (matches `*patient*`/`*sample*` substrings, e.g. `patient_type`) — the **CARD.md keys are authoritative**, not `candidate_keys`.

**Not our problem to fix (flag to owner):** `asma_phenotyping`'s `ASMA_phenotype_20251222.xlsx` has
corrupted headers (`SA_Reportermple_id`, `asSA_Reportery_start_date` — a botched find/replace). Per
Spencer, **we do not clean other people's data** — flag to SYK. Logged in `notes_deferred.md`.

**Exhaustive audit round (2026-06-15) — every card cross-checked file/column/sheet/count against the
real data via 8 read-only verification agents + direct checks. `integration_pipeline_outputs` and
`clinical_redcap_raw` were 100% accurate; the other 6 had errors, now FIXED:**
- `patient_sample_isolate_linkage`: **`patient_type` example values were fabricated** — card said "CF /
  non-CF bronchiectasis / healthy donor"; real values are `adult` / `pediatric` / `healthy_donor` (an
  age-band/donor axis — disease status is NOT in this column). `sampling_method` "fresh vs frozen
  sputum" was also wrong (real: `sputum` / `oral_rinse` / `oral_swab`); added real `sampling_site`
  values and the `HD<n>_<site>` sample_id form for healthy donors. Softened the "fully reproducible"
  build-notebook claim (the `.ipynb` is named in the docs but not on this filesystem).
- `lakehouse_exports`: **caveat claimed the export tables are "parquet/Delta nested below scan depth" —
  FALSE.** They are flat `.txt` (CSV) files at the top level (e.g. `protect_isolate_sample_patient_
  linkage.txt`), each export carrying a `MANIFEST.txt` (integration = "Silver Layer", 6 tables, 10,384
  rows). Zero parquet/Delta on disk. Corrected; removed `delta`/`parquet` from the keywords.
- `asma_genomics`: Nanopore subset understated as "~200–300" → real is **~445** (per `nanoplot-summary.tsv`).
- `asma_phenotyping`: "every assay sheet carries `ASMA_id`" was **overstated** — the multi-isolate
  `pairwise_interaction` and `Competition` sheets have no plain `ASMA_id`; they use per-bacterium
  columns (`bacterium_1_ASMA_id`/`bacterium_2_ASMA_id`; `ASMA_A_id`…`ASMA_E_id`). Corrected.
- `zengler_metagenomics_mind`: **`ogu_species.tsv` / `ogu_ko.tsv` / `cluster*_ko.tsv` are NOT in the
  base `features_subset10_metaG/` dir** — only in the `_manual` (and `_quickrecover`) variants. Card
  pointed species/KO queries at the base dir; corrected. Also clarified PRO### ids are a *prefix* of
  the OGU column headers (`PRO101_metaG_respiratory_custom_subset10_align`), not the whole token.
- `protect_sample_roster`: the `Sample` column was mislabeled as carrying the isolation-vs-omics flag —
  that flag is in the **`Omics`** column (`Isolation`/`Omics`); `Sample` is specimen type
  (`Sputum`/`Mouth Rinse`). Corrected.

---

## 6. Cards are DRAFT — pending owner review
All cards except `integration_pipeline_outputs` (Spencer owns it — authoritative) are marked **DRAFT
pending owner review**. Each carries explicit **"to verify"** flags (grep the cards for `to verify`).
Spencer chose to **harden first** — owners have **not** been pinged yet. Owners to consult later:
Alex (genomics, esp. `sample_id`↔`ASMA_id`), SYK (phenotyping canonical files), Emma (metagenomics
canonical feature tables + whether `sample_name == PRO###`), Conrad (clinical).

---

## 7. WHAT'S NEXT — priority order (Spencer's stated priorities)
1. ✅ **DONE (2026-06-15) — Cron go-live.** `run_pipeline.sh` was already `chmod +x`; ran manually
   end-to-end **twice**, exit 0 both times (~64s each, incl. Emma's tree), regenerating `INDEX.md` +
   `FRESHNESS.md` cleanly with **zero errors/warnings** in `crawler/pipeline.log`. Verified
   deterministic: between runs the only diff is each `dataset.yaml`'s `last_crawled` timestamp;
   freshness stays `0 new / 0 changed`. Crontab installed alongside `protect-data-listing`:
   `0 2 * * * /usr2/people/protect/protect-data-manifest/crawler/run_pipeline.sh`. (Note: both jobs
   fire at exactly 2 AM UTC — concurrent, functionally fine; offset by a few minutes if I/O contention
   ever matters.)
2. ✅ **DONE (2026-06-15) — Exhaustive accuracy audit.** All 8 cards cross-checked file/column/sheet/
   count against the real data (8 read-only verification agents + direct checks); 6 cards had mismatches,
   all fixed (see §5 "Exhaustive audit round"). Manifest-only battery re-run (8 fresh sealed agents):
   **8/8 correct, zero hallucinations**, honest "not found" on hemolytic activity, and every correction
   independently confirmed from the corrected manifest.
3. **Owner card review** — loop in Alex/SYK/Emma/Conrad to resolve the "to verify" flags. (Still
   pending — Spencer chose to harden first; owners NOT yet pinged.) Remaining unresolved "to verify"
   items the audit surfaced for owners: `sample_id`↔`ASMA_id` mapping for genomics QC/taxonomy (Alex);
   canonical feature-table among `_manual`/`_quickrecover` species variants (Emma); `sample_name`==`PRO###`
   (Emma); canonical workbook-per-assay + the corrupted `_20251222` headers (SYK); `subject_id`→`patient_id`
   mapping (Conrad).
4. **Roadmap v2** — a clean version folding in the naming scheme, federation, warehouse, and audit
   findings (with a change log), ready to show Jake/Adam.
5. **Deferred / v1+:**
   - ✅ **DONE (2026-06-15) — `dataset.yaml` is now the explicit recency catalog.** `crawl.py` records
     a per-resource **`mtime`** and per-subdirectory **`mtime`**, and computes **`latest_resource`**
     (newest data file by mtime) + **`latest_subdir`** (newest dated run/export, with archive folders
     like `previous_exports` excluded). Cards (clinical, lakehouse) and `skill/SKILL.md` now point at
     these fields for "what's newest" instead of inferring from filenames. NB: `mtime` ≠ filename date
     (e.g. `asma_phenotyping`'s most-recently-*modified* workbook is `_20250420`, not the newest-named
     one) — `mtime` is the honest "last changed." For heterogeneous collections (genomics, roster)
     `latest_resource`/`latest_subdir` are just "most-recently-modified" and aren't semantically
     special; only the dated-pile collections cite them.
   - ✅ **DONE (2026-06-22) — glob-scoped collections no longer false-flag.** `crawl.py` now derives a
     glob collection's `size` + `source_mtime_latest` from its matched resources (and skips the subdir
     digest) instead of walking the whole shared root — so `protect_sample_roster` (one CSV inside all
     of `Zengler_Lab/`) stopped getting "possibly-stale" flags from Emma's unrelated sibling activity.
   - **v1 candidates (roadmapped):** push notification (email/Slack) when the nightly freshness report
     shows any flag — so maintenance becomes push, not pull (Spencer's 2026-06-22 ask); the **discovery
     sweep** (scan `/usr2/people/protect` for un-registered data dirs); per-table schemas for the
     lakehouse `.txt` exports; tighten the `candidate_keys` heuristic; broader directory coverage;
     owner self-service `DATA_CARD`s; full owner card review (item 3).
   - **v2:** a human GUI / NL query service (Metabase / DataHub / MCP) + live lakehouse query bridge.

6. **Source control — repo prepped (2026-06-22).** Local git repo initialized at the repo root (branch
   `main`, initial commit, generated `pipeline.log`/`.last_snapshot.json` git-ignored), SSH remote set to
   `git@github.com:WeArePROTECT/protect-data-manifest.git`. SSH auth works (Spencer-Long). **Blocked only
   on creating the empty private repo** in the `WeArePROTECT` org (no `gh`/token on this host, so it's a
   GitHub-UI step); after that, `git push -u origin main`. Nightly auto-commit+push is a possible v1 add.

---

## 8. Rules & constraints (keep these)
- The crawler **never** writes into source data directories and **never** edits `CARD.md`.
- **Don't clean other people's data** — flag issues to the owner.
- **Docs/handoffs: facts only, no speculative predictions; use "to verify" items** (Spencer's standing preference).
- Discovery is open; access is a separate, recorded concern.
- Don't introduce pandas into the crawler (NumPy ABI conflict).
- **Cards carry only DURABLE facts — never hand-typed perishables.** A card must not state the newest/
  current file, an "as of <date>" currency claim, or current row/record/file counts/sizes for data
  that grows — those live in `dataset.yaml` (machine-refreshed nightly), and the card points to it.
  A hand-typed perishable goes stale silently and an agent will trust it; the nightly diff can't catch
  a wrong number inside prose. Rule codified in `templates/README.md` ("Curation rules for CARD.md").
  Only exception: counts/dates of an **immutable versioned artifact** (e.g. linkage v4 = 5,182 rows,
  built 2026-03-25). *(All 8 cards were de-perished on 2026-06-15 — clinical was the worst offender;
  warehouse/phenotyping/lakehouse/zengler/genomics also fixed.)*

---

## 9. File map
```
protect-data-manifest/
├── README.md                       entry point
├── HANDOFF.md                      ← this file
├── manifest/
│   ├── INDEX.md                    the catalog (agents start here)
│   ├── LINKAGE.md                  the join map
│   ├── FRESHNESS.md                nightly triage report
│   └── collections/<id>/           dataset.yaml (machine) + CARD.md (human) × 8
├── crawler/
│   ├── crawl.py  build_index.py  freshness_report.py  run_pipeline.sh
│   ├── collections.yaml            the curated collection config
│   └── .last_snapshot.json  pipeline.log   (generated)
├── templates/                      dataset.yaml.template, CARD.md.template, README.md (the standard)
├── skill/SKILL.md                  the dedicated "find PROTECT data" skill
└── docs/
    ├── roadmap/protect_data_manifest_roadmap_v1.md   (partially superseded; see its Status section)
    ├── research/2026-06-15_catalog-landscape-and-design.md
    └── decisions/2026-06-15_audit-and-design-notes.md  +  notes_deferred.md
```
Claude's persistent project memory (full history, decisions, dates):
`/usr2/people/spencerlong/.claude/projects/-auto-sahara-namib-home-protect/memory/project_data_manifest.md`
