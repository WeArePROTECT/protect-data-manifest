# PROTECT Data-Product Standard (the rules)

Every collection in the manifest is a **data product** described by **two files**, kept in this
repo under `manifest/collections/<id>/`:

| File | Owner | Purpose |
|---|---|---|
| `dataset.yaml` | **Crawler** (auto-generated) | Machine-readable facts: paths, sizes, formats, column names + inferred types, access (from permissions), and machine-verified freshness. Regenerated every run — never hand-edit. |
| `CARD.md` | **Human** (curate-once) | Meaning a crawler can't derive: what it is, provenance, join keys, caveats, uses, access routing. The crawler never touches this. |

This clean split is the whole point: auto-generated facts and human knowledge never overwrite
each other.

## Why two files — and why they live here, not in the data directories
- Data stays **in place**; we never write into lab/owner directories (many are gated or read-only).
  The descriptor + card live in *our* repo and point at `collection_root`.
- Grounded in real-world standards (see `docs/research/`): Frictionless Data Package (machine
  descriptor + Table Schema), Datasheets for Datasets / Google Data Cards (the human card), FAIR
  (rich machine-readable, access-independent metadata), and Data Mesh federated governance
  (the platform owns the standard; domains own their products).

## Global rules — what makes a data product conformant
1. Has a conformant `dataset.yaml` (crawler-generated) **and** a non-empty `CARD.md`.
2. Freshness is **machine-verified** (`last_crawled` + `source_mtime_latest`) — never only a
   self-reported date.
3. `access.status` is set from real filesystem permissions; gated products name who to ask.
4. Carries at least one tag from the controlled facet taxonomy below.
5. Non-conformant or **stale** products are surfaced in the nightly diff report — not silently trusted.

## Curation rules for `CARD.md` — keep it durable (don't restate machine facts)
The card holds knowledge that does **not** change when new data lands; the descriptor holds the
facts that do. A card must **never hand-type a perishable fact** — it goes stale silently, and an
agent will then trust the stale card as ground truth (the nightly diff can flag a stale *descriptor*,
but it cannot catch a wrong hand-typed number buried in card prose). The crawler refreshes
`dataset.yaml` every night; the card is curate-once.

**Belongs ONLY in `dataset.yaml` — never restate in the card:**
- which file is *newest* / *current* / *most recent*, and any "as of <date>" currency claim;
- row / record / file counts and sizes for data that **grows or changes**;
- the current dated-run / dated-export / dated-dump **instance** names;
- anything the crawler already emits (paths, schema, freshness, access status).

**Belongs in `CARD.md` — durable:**
- what the data *is* and means, its provenance, and its join keys;
- the value **domain** of a categorical column (e.g. `patient_type` ∈ {adult, pediatric,
  healthy_donor}) — a domain is stable even as row counts grow;
- which file holds which *kind* of content (role → file), sheet/column meaning, and caveats;
- durable **rules** like "use the newest dated run" — state the rule, not which instance is newest;
- counts/dates **only** for an *immutable, versioned* artifact (e.g. "v4.0, 5,182 rows, built
  2026-03-25"), where the number is a defining property of a frozen version, not a moving target.

**When currency matters, point — don't restate.** Write "see the `resources` / `freshness` in the
sibling `dataset.yaml` for the current file set and recency," not "the newest file is X (N records)."
The descriptor makes this easy: every resource and subdirectory carries an `mtime`, and the crawler
computes **`latest_resource`** (the newest data file by mtime) and **`latest_subdir`** (the newest
dated run/export, archive folders excluded) — point a card at those fields. If you find a card that
hand-codes a perishable fact, fix it to defer to the descriptor.

## Facet taxonomy (tags)
Controlled vocabulary for discovery facets (extend deliberately, not ad hoc). Seeded from the
April-2026 inventory flag set:

`CLINICAL`, `LINKAGE`, `ISOLATE`, `PHENOTYPE`, `CARBON_UTILIZATION`, `REPORTER`, `AMR`,
`VIRULENCE`, `TAXONOMY`, `GENOME`, `MIND`, `MULTI_OMICS`, `FORMULATION`, `NIF_NICHE_INDEX`,
`SAMPLE_ROSTER`, `LAKEHOUSE_EXPORT`, `PIPELINE_OUTPUT`, `COMPUTATIONAL_TOOL`, `MODEL_ARTIFACT`,
`RAW`, `CLEANED`, `DEPRECATED`.

## Federation (owner-maintained manifests)
When a data owner maintains their own manifest (e.g. Alex Styer's `~/protect/MANIFEST.md`), we
**link** it via `owner_manifest` in `dataset.yaml` rather than re-describing the contents, and we
record the owner's claimed `last_updated` so the crawler can flag drift against the real source
mtime. Owner manifests are an **input to** — never a replacement for — this standard.
