# Feedback log — reported issues and their outcomes

The durable record of what was reported, by whom, and how it was resolved. Newest first.
(Reports start in `feedback/inbox/`; once processed per `REVIEW_PROTOCOL.md`, they're summarized here.)

| Date | Reporter | Collection | Issue | Outcome |
|---|---|---|---|---|
| 2026-07-22 | Jake | integration_pipeline_outputs / linkage | Manifest implied the cohort is **CF-only**; it actually includes non-CF bronchiectasis patients | **Verified & fixed.** No single "CF vs non-CF" column exists; documented `patient_status` codes (`A1`/`B1`/`C1`/`D1`/`D2`) + `cftr_modulator_status` in the warehouse card, added a LINKAGE gotcha ("cohort is NOT CF-only"), and pointed the linkage `patient_type` note at them. Code meanings flagged *to verify with Conrad*. |
| 2026-07-22 | Jake | asma_genomics | Manifest "pulling ~4,300 isolates" when he expected ">4,900" | **Verified & clarified** (was a subset misunderstanding, not missing data). Documented the three correct count levels in the genomics card + a LINKAGE gotcha: **5,019** total isolates (gold linkage `ASMA-1…5019`) → **~4,900** genome-assembled (this collection) → **~4,300** genome-typed+clustered downstream subset. |
