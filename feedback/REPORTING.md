# Report an issue or propose a change — PROTECT Data Manifest

**Point your Claude agent at this file** when something in the manifest looks wrong, confusing, or
missing — or when you have a correction or new data to contribute. Your agent will file a structured
report that Spencer reviews. This is the easy, no-Slack-archaeology way to get issues tracked and fixed.

---

## The one rule that keeps the catalog trustworthy

Your agent (and you) should **never edit the catalog directly** — not the cards (`CARD.md`), the
machine descriptors (`dataset.yaml`), `collections.yaml`, `INDEX.md`, or `LINKAGE.md`. Those are the
**shared source of truth** that everyone's agents read. Instead you **file a report**, and Spencer
verifies it against the real data and applies the change.

This is deliberate: it stops anyone from accidentally putting a wrong "fact" into the catalog that
other people's agents would then trust. **Report and propose freely — changes are applied by the
maintainer after review.**

---

## Two kinds of reports

- **`issue`** — "the manifest says X, but that seems wrong / confusing / missing." (e.g. *"it told me
  the cohort is CF-only, but we have non-CF bronchiectasis patients too."*)
- **`proposal`** — you have a concrete fix, a correction, or new data to add. Include **what you found
  and how you know it** (your evidence / source of truth).

---

## How your Claude files it (agent instructions)

1. **Do NOT edit any catalog file.** Only create a new report file.
2. Write a file at `feedback/inbox/<YYYY-MM-DD>_<short-slug>.md` (relative to the manifest repo root)
   using the template below. **If you don't have write access there**, print the filled-in report and
   tell the user to send it to Spencer (Slack) — the report is still perfectly useful that way.
3. Fill every field you can, and **cite evidence**: the exact question asked, what the manifest (or
   your agent using it) answered, what the user expected instead, and the specific collection / file /
   column involved.
4. **Flag uncertainty.** If you're not sure it's actually wrong, say so — do not assert ground truth.
5. **Sanity-check machine facts first.** If the issue is "a count / date / newest-file looks wrong,"
   read the sibling `dataset.yaml` (it's machine-generated and refreshes nightly) — the "error" may be
   a stale expectation rather than a catalog bug. Note what you found either way.

---

## Report template

```markdown
---
id: <YYYY-MM-DD>_<short-slug>
date: <YYYY-MM-DD>
reporter: <your name>
agent: claude
collection: <collection id, or "general">
type: issue | proposal
severity: low | medium | high
status: new
---

## What happened / what I found
<one or two sentences>

## Where (be specific)
- Collection / file / column: <e.g. asma_genomics / amrfinder.tsv / ASMA_id>
- What the manifest (or my agent using it) said: <quote>
- What I expected instead: <...>

## Evidence / how I know
<what you checked, the source of truth, file paths, a screenshot reference, etc.>

## Proposed change (proposals only)
<the correction, or the new data to add, and where it should go>
```

---

## Copy-paste prompt for you to give your Claude

> Please read `/usr2/people/protect/protect-data-manifest/feedback/REPORTING.md` and follow it to file
> a report about the following: **<describe the issue or the fix/data you want to propose>**. Do not
> edit any catalog files — just create the report in `feedback/inbox/` (or show it to me to send to
> Spencer). Fill in the evidence carefully and flag anything you're unsure about.

---

## What happens next

Spencer (with his Claude) reviews the inbox, **verifies your report against the real data**, and — if
it holds — applies the fix to the catalog, credits you, and records it in `feedback/LOG.md`. If it
turns out to be a misunderstanding or can't be reproduced, it's logged with a short reason (often the
fix is to make a card *clearer* so the next agent doesn't hit the same confusion). Either way you get a
record, and the manifest gets better.

Thanks for putting it through its paces — this is exactly how a v0 hardens. 🙏
