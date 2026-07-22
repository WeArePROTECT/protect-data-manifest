# Review protocol — processing the feedback inbox (maintainer only)

For **Spencer** (+ his Claude). This is the approval gate that protects the catalog's ground truth.
Scientists file reports in `feedback/inbox/` (see `feedback/REPORTING.md`); **nothing they file is live
until it's verified and applied here.**

---

## Principles (don't skip)

- **Verify, don't trust.** Every factual claim in a report is checked against the source of truth — the
  machine `dataset.yaml` and, where needed, the real data files — **before** any change. A plausible,
  well-meaning report can still be wrong (a misread, or a stale expectation vs the nightly-refreshed
  descriptor). *(Jake's "CF-only" report was real; his "~4,300 isolates" report was a subset
  misunderstanding — both worth a card change, but for different reasons. You only know which by
  checking.)*
- **Human-in-the-loop.** Only the maintainer applies changes to cards / the catalog. Reporters
  **propose**; they don't merge.
- **Machine facts stay machine-owned.** Never hand-edit `dataset.yaml` to match a report. If the
  descriptor is genuinely wrong, the fix is in the **crawler** or the **source data**, not a manual
  override of a generated file.
- **Cards hold only durable facts.** Apply corrections as durable narrative; keep perishables in
  `dataset.yaml` (see `templates/README.md` → "Curation rules for CARD.md").
- **Attribute + log everything.** Credit the reporter; keep the audit trail.

---

## The workflow

1. **Triage.** Read each file in `feedback/inbox/`. Classify: real issue / proposal / question /
   not-reproducible.
2. **Verify against ground truth.** Reproduce the claim: check the relevant `dataset.yaml` schema + the
   real file headers/values (same discipline as the card audit). Confirm or refute it with evidence.
3. **Decide and act:**
   - **Apply** → edit the relevant human `CARD.md` (or `LINKAGE.md`) with **only what's verified**; bump
     its `last_reviewed`. If it's a **data-quality** issue in someone's data, flag it to that owner —
     *don't clean it yourself*. If it's a **crawler bug**, fix `crawler/`.
   - **Clarify** → if the report is a misunderstanding, the right fix is usually to make the card
     *clearer* (so the next agent doesn't repeat it), not to change a "fact."
   - **Reject** → not reproducible / out of scope: log it with a short reason.
4. **Commit** → one commit per report (or a batch), message crediting the reporter, e.g.
   `Fix asma_genomics isolate-count confusion (reported by Jake)`. Then `git push`.
5. **Close the loop** → add a row to `feedback/LOG.md` (date, reporter, collection, issue, outcome,
   commit); remove the report from `inbox/` (the LOG is the durable record).

---

## Quick start — point your Claude at the inbox

> Read `feedback/REVIEW_PROTOCOL.md`, then process `feedback/inbox/`: for each report, verify the claim
> against the real data (`dataset.yaml` + the source files) and tell me, per report, whether to **apply**
> (with the exact card edit you propose) or **reject** (with a reason). **Do not change any catalog file
> until I approve.** Then, for the ones I approve, make the edits, bump `last_reviewed`, and draft the
> commits crediting each reporter.

That keeps *you* in the loop: your agent does the verification legwork and proposes, you approve, it
applies. Same guardrail the scientists have — nothing hits the catalog without a verify + an OK.
