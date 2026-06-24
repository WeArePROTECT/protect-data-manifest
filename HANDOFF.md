# PROTECT Data Manifest — Handoff to the Next Agent

| | |
|---|---|
| **From** | Claude (with Spencer Long), sessions of 2026-06-15 → 2026-06-23 |
| **Status** | **v0 COMPLETE — live, version-controlled, and rolled out to the team.** 8 collections all carded; nightly cron (2 AM UTC); exhaustive card↔data audit done (6 cards fixed; manifest-only battery 8/8, zero hallucinations); cards de-perished to durable-facts-only; `dataset.yaml` is now a machine recency catalog. On GitHub at **`WeArePROTECT/protect-data-manifest`** (private). Team announced via Slack + onboarding guide on 2026-06-23. **Cards still DRAFT pending owner review — that's the main v1 gate.** What's left to build: see §7. |
| **Repo** | `/usr2/people/protect/protect-data-manifest` (= `/auto/sahara/namib/home/protect/protect-data-manifest`); GitHub: `git@github.com:WeArePROTECT/protect-data-manifest.git` (private, branch `main`) |
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
- **Version control + team rollout:** the project is a **git repo** pushed to
  `WeArePROTECT/protect-data-manifest` (private, branch `main`). A scientist-facing onboarding guide
  lives at `docs/PROTECT_Data_Manifest_User_Guide.docx`; the team was announced via Slack + that guide
  on 2026-06-23.
- **Post-v0 hardening (this session):** all 8 cards **de-perished** (durable facts only — perishables
  defer to `dataset.yaml`; rule in `templates/README.md` + §8); `dataset.yaml` gained a machine
  **recency catalog** (`mtime` / `latest_resource` / `latest_subdir`); glob-collection false-flag fix.

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

## 7. Status recap & WHAT'S NEXT

### v0 — COMPLETE, live, version-controlled, rolled out (sessions 2026-06-15 → 06-23)
- ✅ **Cron live** — `0 2 * * * /usr2/people/protect/protect-data-manifest/crawler/run_pipeline.sh`
  (2 AM UTC, alongside `protect-data-listing`). Verified deterministic; only per-run diff is `last_crawled`.
- ✅ **Exhaustive accuracy audit** — all 8 cards vs the real data (8 verification agents + direct checks);
  6 cards fixed (§5); manifest-only battery **8/8, zero hallucinations**.
- ✅ **De-perishing + durability rule** — cards hold only DURABLE facts; perishables live in
  `dataset.yaml`; rule codified in `templates/README.md` + §8.
- ✅ **Recency catalog** — `crawl.py` records per-resource & per-subdir `mtime` and computes
  `latest_resource` + `latest_subdir` (archive dirs excluded). NB: `mtime` ≠ filename date; only
  dated-pile collections (clinical/lakehouse/warehouse) cite these — for heterogeneous collections
  (genomics/roster) they're just "most-recently-modified."
- ✅ **Glob-collection false-flag fix** — glob collections (e.g. `protect_sample_roster`) derive `size`
  + `source_mtime_latest` from matched resources, not the whole shared root (stopped roster being
  flagged by Emma's unrelated sibling activity).
- ✅ **GitHub** — repo at **`WeArePROTECT/protect-data-manifest`** (private), branch `main`, pushed.
  Generated `pipeline.log` / `.last_snapshot.json` git-ignored.
- ✅ **Team rollout (2026-06-23)** — Slack announcement + scientist onboarding guide
  `docs/PROTECT_Data_Manifest_User_Guide.docx` (covers connecting Claude to the server, installing the
  skill via the skill-creator, asking for data, a worked example).

### WHAT WE STILL NEED TO BUILD

**① Owner card review — the MAIN GATE (start here).** All cards except `integration_pipeline_outputs`
are DRAFT. Loop in each owner to sign off and resolve their "to verify" flags; when a card is validated,
drop "DRAFT pending owner review" from its maintainer line. Open items by owner:
- **Alex (genomics):** the `sample_id`↔`ASMA_id` mapping for the QC/taxonomy tables.
- **Emma (metagenomics):** is `final_dataset_clean/` the canonical set? (it appeared 2026-06-19; the
  card already points at it as likely-canonical, to confirm) and does `sample_name == PRO###`?
- **SYK (phenotyping):** canonical workbook per assay type; the corrupted `_20251222` headers.
- **Conrad (clinical):** the `subject_id` → `patient_id` mapping.

**② v1 build items:**
- **Push notifications** (email/Slack) when the nightly freshness report shows any flag — so maintenance
  becomes push, not pull. *(Spencer's explicit v1 ask.)*
- **Discovery sweep** — scan `/usr2/people/protect` for sizable data dirs not yet in `collections.yaml`.
  The one real blind spot: the crawler only watches **registered** roots, so brand-new data products go
  unseen until someone registers them.
- **Nightly auto-commit + push** — keep the GitHub repo current without manual commits (the generated
  `dataset.yaml`/`INDEX.md`/`FRESHNESS.md` churn on each crawl; today they need a manual commit).
- **Per-table lakehouse schemas** — the export `.txt` tables are listed as dirs but their columns aren't parsed.
- **Tighten `candidate_keys`** heuristic (it over-matches; the CARD.md keys are authoritative).
- **Broader directory coverage** + **owner self-service `DATA_CARD`s** (Tier-3, for owners who want to maintain their own).
- **Roadmap v2 doc** — clean version for Jake/Adam (naming scheme + federation + warehouse + audit, with a change log).

**③ v2 vision:** a human-facing layer — NL query service (MCP) and/or a GUI (Metabase / DataHub), plus a
live lakehouse query bridge — for non-agent users and richer search.

### Git workflow (for the next agent)
It's a git repo: `origin = git@github.com:WeArePROTECT/protect-data-manifest.git` (SSH auth works as
Spencer-Long; **no `gh` CLI / API token on this host**). **Commit + push when you change things**, and
end commit messages with the `Co-Authored-By: Claude …` trailer. Generated `pipeline.log` /
`.last_snapshot.json` are git-ignored; the generated catalog (`dataset.yaml` / `INDEX.md` /
`FRESHNESS.md`) **is** tracked, so it shows as modified after each nightly crawl until committed — the
nightly auto-commit above would resolve that.

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
protect-data-manifest/            (git repo → WeArePROTECT/protect-data-manifest, private)
├── README.md                       entry point
├── HANDOFF.md                      ← this file
├── .gitignore                      ignores generated pipeline.log + .last_snapshot.json
├── manifest/
│   ├── INDEX.md                    the catalog (agents start here)
│   ├── LINKAGE.md                  the join map
│   ├── FRESHNESS.md                nightly triage report
│   └── collections/<id>/           dataset.yaml (machine) + CARD.md (human) × 8
├── crawler/
│   ├── crawl.py  build_index.py  freshness_report.py  run_pipeline.sh
│   ├── collections.yaml            the curated collection config
│   └── .last_snapshot.json  pipeline.log   (generated; git-ignored)
├── templates/                      dataset.yaml.template, CARD.md.template, README.md (the standard)
├── skill/SKILL.md                  the dedicated "find PROTECT data" skill
└── docs/
    ├── PROTECT_Data_Manifest_User_Guide.docx   team onboarding guide (shared 2026-06-23)
    ├── roadmap/protect_data_manifest_roadmap_v1.md   (partially superseded; see its Status section)
    ├── research/2026-06-15_catalog-landscape-and-design.md
    └── decisions/2026-06-15_audit-and-design-notes.md  +  notes_deferred.md
```
Claude's persistent project memory (full history, decisions, dates):
`/usr2/people/spencerlong/.claude/projects/-auto-sahara-namib-home-protect/memory/project_data_manifest.md`
