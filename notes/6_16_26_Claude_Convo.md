Great — let me do both: implement the recency change, and ground the process answer in how the code actually behaves. First I need to read the crawler internals (this also lets me answer your "what happens when new data arrives" question accurately rather than from assumption).

Read
crawl.py
Now let me read the freshness report logic — it's central to answering your "what happens when new data arrives" question accurately.

Read
freshness_report.py
I now understand the full mechanics — and importantly, this also tells me exactly how new data flows through (which I'll explain after). Let me implement the recency change.

Edit 1 — thread per-file mtime into the xlsx resources:

Edited
crawl.py
+2
-2
Edit 2 — stamp each resource with its real mtime, and name the newest resource explicitly:

Edited
crawl.py
+9
-4
Edit 3 — add mtime to each subdirectory digest (for dated-export collections):

Edited
crawl.py
+6
-1
Edit 4 — name the newest dated subdirectory:

Edited
crawl.py
+4
-0
Now syntax-check, run the full pipeline, and verify the new fields landed correctly on the key collections:

Ran
Syntax check and run pipeline
Pipeline clean. Let me verify the new fields are correct — does latest_resource actually point to the newest dump for clinical, and latest_subdir to the newest export?

Ran
Verify latest_resource/latest_subdir + per-item mtimes
The fields work — and the verification immediately caught a subtle bug worth fixing. For clinical_redcap_raw, latest_resource correctly points to the May 21 dump even though it's listed 2nd alphabetically — exactly the win. But for lakehouse_exports, latest_subdir: previous_exports is wrong: the archive folder has the newest directory-mtime (something was recently moved into it), so it masquerades as "newest." Let me exclude archive folders so latest_subdir names the real current snapshot.

Edited a file, ran a command
latest_subdir now correctly names integration_export_20260519_124658 (the real current export), and 5_21_26 for the warehouse. Now let me point the relevant card pointers at these new explicit fields so they land precisely, and note them in the standard + skill.

Edited 2 files
Now the standard and the agent skill, so card authors and agents both know these recency fields exist:

Edited 2 files
Now a final full pipeline run to regenerate everything consistently, plus a sweep confirming the new recency fields are present and sane across all 8 collections:

Ran
Final pipeline run and recency-field sweep
Everything is clean and the recency fields are correct exactly where they matter (clinical→newest dump, lakehouse→current export with archive excluded, warehouse→current run), and honest-but-harmless elsewhere (the cards only wire to them where meaningful). Note freshness still shows 0 changed — correct, because it tracks source-data drift, not our descriptor's schema, and no source data moved.

Let me mark this done in the handoff and memory, then answer your process question.

Edited 2 files
Both the recency enhancement and the docs are done, tested, and clean. Now — your process question, which is a great one to nail down. I traced it through the actual code so this is how it really behaves, not how it's "supposed to."

The short answer
There are two layers, and they update differently:

Machine facts (where the data is, its files, columns, row counts, sizes, recency) → auto-refresh every night. Zero action from you.
Human cards (CARD.md narrative) → only need a human touch when something semantically new shows up — and the freshness report tells you when, so you're not relying on anyone's memory.
You do not ping an agent for routine new data. The cron handles it.

What runs every night (2 AM UTC)
run_pipeline.sh → crawl.py → build_index.py → freshness_report.py. The crawler re-lists and re-reads every collection from scratch and overwrites each dataset.yaml. Then the freshness report diffs against last night's snapshot and writes FRESHNESS.md — the "what's new / changed / undocumented / possibly-stale" triage list. That report is your dashboard.

Scenario 1 — Conrad drops a new REDCap dump
A new ..._6.15.2026_CompleteDatabase.csv lands in Conrad_Lab/metadata/RedCapDataExports/raw/. That folder is the clinical_redcap_raw collection root. So next crawl, automatically:

It becomes a new resource in dataset.yaml with full schema (columns + types), row count, size, and mtime.
latest_resource flips to the new dump (newest mtime) — so "which is current?" is correct with no edit.
source_mtime_latest + file_count advance → freshness report lists clinical_redcap_raw under "Changed at source," and since the source date is now newer than the card's last_reviewed, also under "Possibly-stale card."
What you do: nothing — because we de-perished the card, it says "see dataset.yaml latest_resource," which is now correct on its own. The "possibly-stale" flag is just a heads-up to glance at it; you'd only edit the card if the new dump changed something semantic (new columns worth narrating, a new caveat). A routine same-shape dump needs no edit. This is exactly the payoff of the de-perishing work — before, that card hard-coded "5.21.2026, 62 records" and would have silently lied the moment this dump arrived.

Scenario 2 — you run the integration pipeline (new run, maybe new tables)
A new pipeline_outputs/runs// appears, possibly with a table type that wasn't in prior runs (say a newly-cleaned Conrad sample table). The integration_pipeline_outputs collection has pick_latest_subdir: true, so next crawl:

The crawler auto-follows the newest run (latest_subdir → the new date), and schema-extracts every table in it — including a brand-new table type, because it just globs the run dir. No config change needed.
Freshness flags the collection as "Changed."
The one nuance: the card's "Products in this collection" table is a curated list of known tables by role + join keys. A genuinely-new table type will be fully described in dataset.yaml (an agent will find it), but won't have a human-written row in the card until someone adds one. That's the case where the "possibly-stale" flag is doing real work — it's telling you "a human should glance at this card." (Also by design: since it follows the newest run, if a new run omits a table an old run had, the manifest tracks the new run — "use the newest, outputs vary by run.")

Are we covering our bases? Honest answer
Situation	Auto-caught?
New file in an already-registered collection dir (your two scenarios)	✅ Yes — schema, counts, recency, next crawl
New columns in an existing file	✅ Yes — schema re-read every crawl
"Which file/run is newest"	✅ Yes — now via latest_resource/latest_subdir
A brand-new directory no collection points at yet	❌ No — must be registered once in crawler/collections.yaml
New file deeper than scan_depth or a non-tabular type (.json, .h5, Delta .txt)	⚠️ Partial — counted (so the collection flags "changed"), but not schema-extracted
Files beyond max_resources cap (genomics 60/70, zengler 60/208)	⚠️ Partial — counted, not individually described
Card narrative for genuinely-new semantics	❌ Needs a human — but freshness flags it for you
So: for everything we've registered, machine facts cover the bases automatically and the freshness report is the bounded to-do list. The one real blind spot is a team starting to drop data in a directory we've never registered — the crawler only looks where collections.yaml tells it to, so it can't flag what it isn't watching. Registering a new data product there is a ~6-line addition to collections.yaml (and a card). A future "discovery sweep" that scans /usr2/people/protect for big un-cataloged dirs would close even that gap — worth considering for v1.

And if you don't want to wait for 2 AM: just run crawler/run_pipeline.sh (or an agent does) and the manifest reflects the new data in ~60 seconds.

Want me to add that discovery sweep (flag un-registered data dirs) to close the last gap, or leave it queued? Otherwise — your two scenarios are fully covered, no pinging required.