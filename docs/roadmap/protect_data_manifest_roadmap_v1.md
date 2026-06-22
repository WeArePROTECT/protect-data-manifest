# PROTECT Data Manifest
### Project Outline & Recommendation — v1

| | |
|---|---|
| **Author** | Spencer Long (Data Scientist, PROTECT) — drafted with Claude |
| **Audience** | Jake (requestor), Adam, Alex; broader PROTECT team and collaborators |
| **Date** | 2026-06-15 |
| **Status** | **v0 BUILT & validated (2026-06-15).** This v1 plan is partially superseded — see the Status & Change Log immediately below, and `HANDOFF.md` (repo root) for current truth. |
| **Related** | Jake's Slack request (2026-06-13); `protect-data-listing/`; `protect-platform-docs/`; `Arkin_Lab/sjlong/protect_directory_inventory/` (April 2026 prior inventory) |

---

## ⏱️ Status & Change Log (added 2026-06-15, end of day)

**v0 is built and validated.** The recommendation below (catalog-not-warehouse,
discovery-decoupled-from-access, federation, machine-verified freshness) was accepted and
implemented. **The single source of truth for current state is `HANDOFF.md`** (repo root). Changes
since this v1 was written:

- **Built:** repo at `/usr2/people/protect/protect-data-manifest`; **8 collections, all carded**; the
  two-file standard (`dataset.yaml` machine + `CARD.md` human); crawler + index generator + freshness
  report + pipeline runner; a dedicated skill; `LINKAGE.md` join map.
- **Naming scheme changed** (the section headings below predate it): collection ids now lead with the
  stable **data domain**, grouped by **team**; version/state are metadata. Current ids:
  `patient_sample_isolate_linkage`, `clinical_redcap_raw`, `asma_genomics`, `asma_phenotyping`,
  `zengler_metagenomics_mind`, `protect_sample_roster`, `lakehouse_exports`, `integration_pipeline_outputs`.
- **`alex.styer` path corrected** to `/usr2/people/alex.styer/protect/ASMA` (v1 had it wrong).
- **Warehouse added** (`integration_pipeline_outputs`) — resolved the cleaned-clinical gap.
- **Two accuracy-audit rounds** run (12 manifest-only agent tests, 0 hallucinations); a class of
  join-key bugs found and fixed (see `HANDOFF.md` §5).
- **Still open:** nightly cron go-live; full re-audit of every card's keys/columns; owner card review;
  a clean roadmap **v2** for the Jake/Adam review.

> The sections below are the **original v1 plan** — still useful for the *why* (rationale, prior art,
> the four paths, the deliverables), but read them alongside `HANDOFF.md`, which reflects what was
> actually built.

---

## TL;DR

Jake asked for a **PROTECT-wide manifest** that a team member can point their Claude agent at to understand what data exists, how it connects, and where to get it — with the concrete example of taking the ASMA collection and filtering it for hemolytic activity, AMR gene predictions, and growth phenotypes. This recurring "where is the data / who do I ask" problem is real and costs the team time every week.

**My recommendation: build a *catalog*, not a *warehouse*.** We create an agent-readable manifest that *points to data where it already lives* — it copies nothing. It is world-readable (the manifest holds only metadata; there is nothing sensitive in knowing what exists and what columns a file has), and it is **auto-refreshed** so it does not rot. Critically, we decouple **discovery** (open to everyone) from **access** (a separate permission question the catalog simply records and routes). This sidesteps the lakehouse-access bottleneck entirely: people can discover and understand data even before they can open every byte of it.

We are not starting from zero. We already have the "where" (`protect-data-listing`'s nightly filesystem crawl), a partial "what/how" (`protect-platform-docs`), and — importantly — a **prior April-2026 inventory** (`protect_directory_inventory`) that already worked out a domain flag taxonomy and a generating methodology. That prior inventory is also our cautionary tale: it is only two months old and already stale, which is exactly the failure mode this project is designed to prevent.

**What I'm asking of you:** review the phasing (v0 → v1 → v2) and the recommendation to *not* build a central data directory, and answer the Open Questions in Section 7 — especially Alex on including the genomic data in `/usr2/people/alex.styer/`, and Jake on where "hemolytic activity" data actually lives.

---

## 1. Background and Recap

### 1.1. What was requested
On 2026-06-13 (Slack), Jake — after discussion with Adam and Alex — asked for "some kind of PROTECT-wide manifest for all of our data where a team member could point their Claude to it and get a clear sense of data structures and how they connect." His worked example: *"take the ASMA collection and filter it for hemolytic activity, AMR gene predictions, and maybe growth phenotypes."*

### 1.2. The original rationale
PROTECT data is spread across lab/team directories under `/usr2/people/protect/` (Arkin, Conrad, Nizet, Zengler) plus personal workspaces (e.g., `/usr2/people/alex.styer/`). Today, finding data depends on tribal memory or asking someone over Slack/email. Cleaned/linked data is increasingly moving to the KBase Lakehouse — but **most scientists do not have Lakehouse access**, so even well-organized data there is hard for them to reach. A discovery layer must therefore meet people where they already are: on the filesystem, readable by their Claude agents.

### 1.3. What was done to produce this doc
A read-only investigation of the PROTECT tree confirmed the data topology, surfaced two existing assets that already do half the job, and recovered a prior cataloging attempt that had been forgotten. We then converged, through discussion, on the strategic shape of the solution (catalog-not-warehouse) and a maintenance model designed around the reality that Spencer is the sole data scientist maintaining all of this.

---

## 2. Findings

### 2.1. What already exists (we are not starting from scratch)

| Asset | What it is | Role | Limitation |
|---|---|---|---|
| `protect-data-listing/` | Nightly `tree -J` of `/usr2/people/protect` → 8.3 MB `tree.json`, served as a password-protected static web tree. Built for the ARPA-H Month-12 deliverable. | **WHERE** — every path, refreshed by cron. | Filenames only (content-blind); human web UI; no schema/size-meaning/links. |
| `protect-platform-docs/` | Docs-as-code repo (has its own SKILL.md). `metadata/`, `data-infrastructure/`, `platforms/`, `tools/`. | **WHAT + early HOW** — schemas, pipeline lineage. | Likely out of date; covers platforms/standards, not a per-dataset catalog. |
| `Arkin_Lab/sjlong/protect_directory_inventory/` | **Prior attempt at this exact project** (April 2026, Claude-generated, ARPA-H framing): per-lab inventories, master summary, linkage version history, duplicate detection, and a **domain flag taxonomy**. | **Proven methodology + tag scheme** we can reuse. | Already stale (~2 months) — points to old paths; deliberately skipped Emma/Vishant. |

### 2.2. The data topology (the "hot" collections people actually want)

| Collection | Location | Notes |
|---|---|---|
| Linked/bridged "warehouse" | `Arkin_Lab/protect_data/protect_data_integration_pipeline/pipeline_outputs/runs/<dated>` | Output **varies by run** (only what each run's use-case needed). Staged onward to the Lakehouse. |
| **Canonical join layer** | `Arkin_Lab/protect_data/patient_sample_isolate_linkage_data/…_v4/` | Patient ↔ sample ↔ isolate/genomic linkage. **v4 is canonical**; carries its own provenance docs. This is the backbone of "how data connects." |
| Lakehouse staging + schema | `Arkin_Lab/protect_data/protect_lakehouse_pipeline/` (`datasets/{integration,genome-analysis,phenotype,mind-analysis,formulation-screening}`, `data/exports`) | Source of truth for what has been pushed to KBase + its schema. |
| Raw clinical (REDCap) | `Conrad_Lab/metadata/RedCapDataExports/raw/` | Raw dumps. The sibling `pipeline_outputs/` here is a **deprecated** old cleaning method — clean REDCap now comes from the integration pipeline. |
| Zengler multi-omics / MIND | `Zengler_Lab/Emma/` (+ `Vishant/`) | Emma's directory holds the primary metaG/metaRS/MIND outputs. |
| Sample roster | `Zengler_Lab/120325PROTECTSamples.csv` | Consumed by the integration pipeline. |
| **Genomic half of ASMA** | `/usr2/people/alex.styer/ASMA/` (`amrfinder.tsv` = AMR, `gtdbtk/` = taxonomy, `metaVF.tsv` = virulence) | **Outside `/usr2/people/protect/`.** Alex Styer's personal dir (>700 GB genomics/sequencing). |
| Phenotype half of ASMA | `Arkin_Lab/SYK/` (`ASMA_phenotype.xlsx`, `ASMA_carbon_kinetics_*`, reporter/inhibition) | Growth curves, carbon utilization, PA inhibition/reporter assays. |
| **Excluded** | `Arkin_Lab/aparkin/arbitrary_gold/protect/.data-refinery` | Unverifiable personal scratch compile — left out of the catalog. |

### 2.3. Coverage analysis — and a check against Jake's own example

We have **WHERE** (filesystem crawl) and **partial WHAT** (platform-docs + the stale inventory). What is missing is the **glue**: the layer that ties *a path* → *its meaning, schema, owner, freshness, and join keys*, plus a **single agent entry point** and a **freshness mechanism**.

Mapping Jake's example onto the real data shows the demo is within reach — and surfaces one gap:

| Jake's filter | Where it lives | Status |
|---|---|---|
| Growth phenotypes | `Arkin_Lab/SYK/ASMA_phenotype.xlsx`, `ASMA_carbon_kinetics_*` | ✅ Located |
| AMR gene predictions | `/usr2/people/alex.styer/ASMA/amrfinder.tsv` | ✅ Located (drives the alex.styer scope decision) |
| Hemolytic activity | *not yet located* | ❓ **Open question for Jake** (see 7) |
| Joining across these | `patient_sample_isolate_linkage_data` v4 | ✅ Canonical join layer exists |

---

## 3. Recommendation

### 3.1. The strategic reframe
**A catalog of metadata that points to data in place — not a copy of the data.** Three principles:

1. **Catalog, not warehouse.** Copying data into a central directory duplicates storage and creates a sync obligation that *will* go stale (exactly what happened to the docs and the prior inventory) and a second source-of-truth problem. The catalog moves nothing.
2. **Discovery decoupled from access.** The manifest is metadata-only and world-readable. Whether you can *open* a given dataset is a separate permission status the catalog records ("lives at X; needs `protect-zengler`; ask Spencer"). We do not need to solve permissions to ship the manifest.
3. **Agent-first.** Optimize for "point your Claude at it" (structured, traversable, one clear entry point). Humans benefit for free; a clickable GUI comes later.

### 3.2. Paths considered

| Path | Approach | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A — Static manifest files + skill** | Root manifest + data cards + auto-crawl, read directly by Claude | No hosting/auth; rides existing filesystem access; fast to ship; agent-native | Not a queryable service; some manual curation | **Recommended for v0** |
| **B — MCP catalog server** | A server exposing search/query over the catalog ("find datasets with AMR predictions") | Powerful NL querying; scales to many datasets | Needs hosting + upkeep; more build | **v1 / v2** |
| **C — Catalog product / BI GUI** (OpenMetadata, DataHub, Metabase) | Hosted catalog or query GUI for humans | Rich UI, lineage, search; good for non-agent users | Re-introduces the *same* hosting + auth + provisioning bottleneck as the Lakehouse | **Later, human-audience phase** |
| **D — Central data warehouse directory** | Physically copy all "good" data into one readable dir | One place to look; solves access gap crudely | Storage duplication; sync/staleness burden on a one-person team; second source of truth; overlaps aparkin's refinery | **Rejected** |

**Honest tradeoff:** Path A is deliberately "second-class" relative to B/C — it is files and conventions, not a search engine, and the semantic layer needs human curation. We accept that for v0 because it ships value in weeks against zero infrastructure, and it is the natural substrate the later phases build on.

---

## 4. Proposed Deliverables

### 4.1. Manifest repo + agent entry point + dedicated skill *(primary)*
A **new dedicated repo** (working name `protect-data-manifest`) with a single `START_HERE` root manifest and its **own new skill** — so a team member literally points their Claude at it. (We will *link to* `protect-platform-docs` where useful and freshen only the pages we depend on; we will not repurpose its skill.)

### 4.2. Tier-1 auto-crawl — enriched inventory *(the freshness engine)*
Extend the existing crawler to emit volatile facts automatically on the nightly cron: path, size, file type, row/file counts, last-modified, **detection of new dated output dirs**, and **column headers/schema for tabular files** (headers only — no data rows, keeping it sensitivity-safe). This is the bulk of the manifest and it maintains itself.

### 4.3. Tier-2 curated data cards — the semantic layer
A standard data-card template (what it is, owner, access status, join keys, raw-vs-clean lineage, sensitivity). Seeded by reusing the prior inventory's content and **flag taxonomy** (`[PHENOTYPE]`, `[CARBON UTILIZATION]`, `[AMR]`, `[MIND]`, `[REPORTER]`, …) as faceted tags. Written once per collection; slow-changing.

### 4.4. Connection layer — join keys & lineage
A linkage map built on the **v4** `patient_sample_isolate_linkage_data` provenance: documents the shared keys (patient/subject, sample, isolate IDs) and the raw → integration-pipeline → Lakehouse lineage. This is what makes Jake's cross-dataset filtering possible.

### 4.5. Tier-3 owner self-service + freshness/diff report
A drop-in `DATA_CARD` template data owners place beside their own data (the crawler harvests it), plus a nightly **"what's new / undocumented / changed"** diff report — the only thing Spencer triages. This is how maintenance stays bounded for a one-person team.

### 4.6. Lakehouse bridge *(optional, late-v0 / v1)*
Describe Lakehouse-only tables (so people know what exists and can request the slice they need) by reading the existing schema/export metadata under `protect_lakehouse_pipeline/`.

---

## 5. Computational Sizing

| Component | Already exists? | Effort | Notes |
|---|---|---|---|
| Enriched crawler (4.2) | Partial — `protect-data-listing` has `tree -J` crawl + cron | Low–Med | Add size/type/count/mtime, dated-dir detection, schema headers |
| Schema/header extraction | New | Low | csv/tsv/xlsx/parquet headers only; no content |
| Root manifest + entry point (4.1) | New | Low | `START_HERE` + index |
| Dedicated skill (4.1) | New | Low | "find PROTECT data" skill pointing agents at the manifest |
| Data-card template + seed cards (4.3) | Partial — prior inventory + platform-docs supply content | Med | curate-once; reuse flag taxonomy |
| Connection/join-key doc (4.4) | Partial — v4 linkage provenance exists | Low–Med | document keys + lineage |
| Diff/freshness report (4.5) | New | Low | diff current crawl vs last snapshot |
| Lakehouse bridge (4.6) | Partial — schema under `protect_lakehouse_pipeline/` | Low | optional |

**Net:** v0 is mostly *assembly and enrichment of existing parts*, not green-field building. The genuinely new pieces (skill, entry point, diff report) are each small.

---

## 6. Roles and Timeline

| Owner | Deliverable | Why this person |
|---|---|---|
| Spencer | Crawler, root manifest, skill, seed cards, connection layer | Data scientist; owns the data infrastructure |
| Alex Styer | Confirm/curate cards for `alex.styer/ASMA/` genomic data | Owns the genomic half of ASMA |
| Emma (Zengler) | Card for `Emma/` multi-omics/MIND | Owns the data |
| Conrad team | Confirm canonical REDCap source; raw clinical card | Owns clinical metadata |
| SYK | Phenotype (ASMA) card | Owns the phenotype data |
| Jake / Adam | Review v0 demo against the ASMA use case | Requestors/consumers |

**Realistic timeline** (Spencer is part-time on this amid other duties):
- **v0** — agent-readable catalog, seeded hot collections, auto-crawl + skill, demo answering the ASMA case: **~1–2 weeks of focused effort.**
- **v1** — full data-card coverage across labs, connection layer, owner self-service cards, diff report: **~4–6 weeks.**
- **v2** — MCP query server and/or human GUI (Metabase/OpenMetadata), Lakehouse query bridge: **scoped after v1 lands.**

---

## 7. Open Questions — Input Requested

**For Alex Styer**
1. Your `/usr2/people/alex.styer/ASMA/` data (`amrfinder.tsv`, `gtdbtk/`, `metaVF.tsv`) is the genomic half of the ASMA collection. OK to catalog it (metadata only, pointing in place)? Any subdirs to exclude (e.g., the `seqcoast/` paths that returned permission-denied in the April inventory)? Would you keep a drop-in `DATA_CARD` current, or prefer Spencer curates from outside?

**For Jake**
2. Your example includes **"hemolytic activity"** — I can locate AMR and growth phenotypes, but not a hemolytic-activity dataset. Where does it live (or is it derived)?
3. Confirm **agent-first v0** is what you envisioned ("point your Claude at the manifest"), versus needing a clickable web view in the first cut.

**For the Conrad team / Spencer**
4. Confirm the `Conrad_Lab/.../RedCapDataExports/pipeline_outputs/` is **deprecated** and the integration-pipeline output is the canonical clean REDCap, so the catalog routes people correctly.

**For Adam (or whoever owns server access policy)**
5. Who owns the decision to **open server-wide read access** to the hot data dirs? This is the access lever — separate from the manifest, but it determines how often the catalog has to say "you can see it exists but can't open it yet."

**For Emma**
6. Would a drop-in `DATA_CARD` in your directory be something you'd maintain, or should Spencer curate Zengler/Emma cards centrally?

---

## 8. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| **Staleness** (the failure that killed the prior inventory) | Tier-1 auto-crawl on cron + nightly diff report; keep the manual surface area tiny |
| **One-person maintenance bottleneck** | Distribute description to data owners (Tier-3 cards); auto-crawl still covers the basics if owners don't |
| **Scope creep past v0** | Hard v0 seed-scope list (Section 2.2); everything else is v1 |
| **Access confusion** (people assume catalog = entitlement) | Catalog explicitly records access status + who to ask; never implies access |
| **`alex.styer/` is outside the tree and permissioned** | Confirm with Alex; crawl only readable subdirs; log permission-denied paths (as the April inventory did) |
| **Auto-crawl can't infer meaning** | Curate-once cards + flag taxonomy supply semantics; agents can still read raw schema for un-carded data |
| **Sensitive content leaking into a world-readable manifest** | Metadata-only rule: schema/column headers, never data rows; sensitivity review on cards (inherit platform-docs guidance) |

---

## 9. How to Give Feedback

Most useful right now: the **Open Questions in Section 7**, especially Alex on genomic scope and Jake on the hemolytic-activity location + agent-first confirmation. Also: **any hot data collection I've missed** in the Section 2.2 seed scope.

Reply in the Slack thread with Jake, or leave comments directly on this doc. Once the Section 7 questions are answered, I'll cut **v2 of this roadmap** (with a change log) and, on your go-ahead, start building v0.

---

## Appendix A — Confirmed v0 Seed Map

Paths verified 2026-06-15. Tier = which maintenance tier primarily covers it.

| Path | One-liner | Tier |
|---|---|---|
| `Arkin_Lab/protect_data/protect_data_integration_pipeline/pipeline_outputs/runs/<dated>` | Bridged/linked outputs; cleaned REDCap; varies by run | 1 (auto-detect dated dirs) + 2 |
| `Arkin_Lab/protect_data/patient_sample_isolate_linkage_data/…_v4/` | Canonical patient↔sample↔isolate join layer | 2 + 4 |
| `Arkin_Lab/protect_data/protect_lakehouse_pipeline/` | What's pushed to KBase + schema | 1 + 6 |
| `Conrad_Lab/metadata/RedCapDataExports/raw/` | Raw REDCap dumps (clean = integration pipeline) | 1 + 2 |
| `Zengler_Lab/Emma/` | metaG/metaRS/MIND multi-omics | 1 + 3 |
| `Zengler_Lab/120325PROTECTSamples.csv` | Sample roster consumed by the pipeline | 1 |
| `Arkin_Lab/SYK/` (ASMA phenotype) | Growth curves, carbon utilization, PA inhibition | 1 + 3 |
| `/usr2/people/alex.styer/ASMA/` | AMR (`amrfinder`), taxonomy (`gtdbtk`), virulence (`metaVF`) | 1 + 3 *(pending Alex)* |
| `Arkin_Lab/aparkin/arbitrary_gold/protect/.data-refinery` | **Excluded** — unverifiable scratch compile | — |

## Appendix B — Prior Art & Methodology References

- `Arkin_Lab/sjlong/protect_directory_inventory/prompts/library_prompt_protect_server_og.md` — the generating prompt; effectively a hand-written v0 crawler spec.
- `…/protect_directory_inventory/protect_server_inventory_summary.md` — master summary + flag taxonomy + linkage version history (v3.1 → v4.0 → v4.1).
- `…/protect_directory_inventory/zengler_data_directory_analysis/` — Emma deep-dive (+ `PROTECT_master_join_table_v1_0.csv`).
- `protect-data-listing/` — existing nightly `tree -J` crawler + cron (the freshness mechanism to extend).
- `protect-platform-docs/` — existing metadata/schema docs to link (and selectively freshen).
- **Flag taxonomy to reuse as facets:** `[PHENOTYPE DATA]`, `[CARBON UTILIZATION]`, `[NIF / NICHE INDEX]`, `[ACTIVE LEARNING]`, `[REPORTER DATA]`, `[MIND DATA]`, `[FORMULATION DATA]`, `[AMR]`, `[COMPUTATIONAL TOOL]`, `[MODEL ARTIFACT]`, `[ANALYSIS WORKFLOW]`.

## Appendix C — Glossary

- **Manifest / Catalog** — a structured index of *metadata about* data (where it is, what's in it, how to access it). Points to data; does not contain it.
- **Warehouse / Hub** — a location that physically holds copies of data. (Explicitly *not* what we're building.)
- **Data card** — a short standardized description of one dataset/collection (owner, schema, join keys, access status, lineage).
- **Join key / linkage** — the shared identifiers (patient, sample, isolate) that let datasets be filtered and combined across types.
- **Lakehouse** — the KBase data lake (MinIO + Delta Lake + Spark) where cleaned/linked data is increasingly staged; not yet broadly accessible to scientists.
- **Tier 1/2/3** — the maintenance model: auto-crawl (1), curate-once cards (2), owner self-service + diff report (3).
