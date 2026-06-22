# Audit & Design Notes — 2026-06-15

Working record for the PROTECT Data Manifest (`protect-data-manifest`). Captures the decisions reached in discussion, the pre-build audit against the live filesystem, and one significant discovery that refines the approach. Corrections here will be folded into **roadmap v2** (with a change log) rather than silently edited into v1.

## 1. Decisions locked (discussion, 2026-06-15)
- **Catalog, not warehouse** — metadata points to data in place; nothing copied. Central data directory rejected.
- **Discovery decoupled from access** — manifest is world-readable (metadata only); access status is *recorded and routed*, not granted.
- **New dedicated repo** at `/usr2/people/protect/protect-data-manifest` with its **own new skill**; link to `protect-platform-docs`, freshen only depended-on pages.
- **v0 = Claude-agent-first**; human GUI / Metabase later.
- **3-tier maintenance**: auto-crawl (volatile) → curate-once cards → owner self-service + nightly diff report.
- **Scope includes** `alex.styer`'s PROTECT genomic data. **Exclude** `aparkin/.data-refinery`.

## 2. Pre-build audit — verifying roadmap assumptions against the live tree

**Verified true:**
- `tree` present (`/usr/bin/tree`). But the existing `protect-data-listing` crawler is **custom Python** (`make_tree_json.py`) — names-only, scans `/usr2/people/protect` *only*. The README's "`tree -J`" claim is itself drift.
- **Canonical join layer confirmed:** `Arkin_Lab/protect_data/patient_sample_isolate_linkage_data/patient_sample_isolate_table_v4/` → `patient_sputum_asma_gold_linkage_table_v_4_0.csv` (501 KB) + `ASMA_Gold_Metadata_Documentation_v4_0.md` + QC report + update log.
- **Lakehouse exports confirmed:** `protect_lakehouse_pipeline/data/exports/` has dated export dirs + README; `datasets/{integration,genome-analysis,phenotype,mind-analysis,formulation-screening}`.
- **Conrad raw REDCap confirmed AND access-gated:** `drwxrwx---`, owner `dibarramunoz`/`arkin`/`users`; latest raw export `...5.21.2026...` (newer than the April inventory knew). A concrete "describe it, but access is gated" case.

**Corrections (stale in roadmap v1, inherited from the April inventory):**
- Alex's genomic ASMA data is at **`/usr2/people/alex.styer/protect/ASMA/`**, NOT `/usr2/people/alex.styer/ASMA/`. Current contents: `amrfinder.tsv` (8.9 MB, **AMR**), `metaVF.tsv` (28 MB, virulence), `gapmind-carbon-rules.tsv` (174 MB) + `gapmind-aa-rules.tsv` + `gapmind-manifest.tsv` (metabolic), `gtdbtk/` (taxonomy), `checkm2-summary.tsv`/`busco-summary.tsv` (QC), `fastani/` + `mash/` (clustering), `isolates/` (~4,940 per-isolate dirs), `gapseq/`, `PA/`, `PA-exploratory/`, `phage/`, `mucin/`, `phylogenies/`, `c-sources.xlsx`.

## 3. Significant discovery — Alex already maintains an owner-curated manifest
At **`/usr2/people/alex.styer/protect/MANIFEST.md`** (62 KB, last_updated **2026-06-15**) Alex maintains a sophisticated, agent-readable manifest of his entire PROTECT genomics workspace: YAML frontmatter (`project`/`description`/`root`/`last_updated`), a top-level directory map, per-directory and per-file descriptions, and documented Snakemake workflows/scripts. He also keeps a `CHANGELOG.md` ("record unexpected or third-party changes here"). He is an active Claude user (`.claude` projects incl. `ASMA/gapseq`).

**Why it matters:**
- It is the **Tier-3 owner-curated model already working in practice** — proven, current, authoritative, and richer than anything we'd generate from outside his directory.
- It is a **format precedent** we can standardize as *the* PROTECT manifest pattern (YAML frontmatter + structured markdown + `last_updated` + changelog).
- For the genomic half we should **harvest/link Alex's MANIFEST, not re-describe it.**

## 4. Resulting design refinement — federation
v0 manifest = a **federation** of per-directory/owner manifests (like Alex's) + an **auto-crawl** covering everything not yet owner-described + a **top-level entry point/index** that ties them together and to the v4 linkage layer. Cleaner than "Spencer describes everything," distributes maintenance to data owners, and matches the 3-tier model. The PROTECT `DATA_CARD`/manifest template will be modeled on Alex's pattern.

## 5. To fold into roadmap v2 (change log)
- Correct the `alex.styer` path (Sections 2.2/2.3, Appendix A, Open Questions).
- Add the **federation** refinement to Sections 3–4.
- Note Conrad raw REDCap is access-gated (the canonical access-status example).
- Add Alex's `MANIFEST.md` as both prior art and the **format precedent** (Appendix B).
- Reframe the Alex open question: not "will you adopt a DATA_CARD?" but "can we **standardize and harvest your existing MANIFEST.md**?"
