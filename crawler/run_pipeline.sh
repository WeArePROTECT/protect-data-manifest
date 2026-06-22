#!/bin/bash
# =============================================================================
# PROTECT Data Manifest — full refresh pipeline (for the nightly cron)
# Runs: crawl (descriptors) -> build_index (catalog) -> freshness_report (diff).
# Mirrors the protect-data-listing nightly pattern. Logs to crawler/pipeline.log.
#
# Suggested crontab (2 AM UTC daily), once tested:
#   0 2 * * * /usr2/people/protect/protect-data-manifest/crawler/run_pipeline.sh
# =============================================================================
set -uo pipefail
export PATH=/usr/bin:/bin:${PATH:-}

BASE="/usr2/people/protect/protect-data-manifest"
CR="$BASE/crawler"
LOG="$CR/pipeline.log"
PY=/usr/bin/python3

ts() { date -u +"[%Y-%m-%d %H:%M:%S UTC]"; }

echo "$(ts) === manifest refresh starting ===" >> "$LOG"

run_step() {
  local name="$1"; shift
  echo "$(ts) running $name" >> "$LOG"
  if "$@" >> "$LOG" 2>&1; then
    echo "$(ts) $name OK" >> "$LOG"
  else
    echo "$(ts) ERROR: $name failed (rc $?)" >> "$LOG"
    return 1
  fi
}

run_step "crawl"            "$PY" "$CR/crawl.py"            || exit 1
run_step "build_index"      "$PY" "$CR/build_index.py"     || exit 1
run_step "freshness_report" "$PY" "$CR/freshness_report.py" || exit 1

# sanity check: INDEX.md must exist and be non-trivial
if [ ! -s "$BASE/manifest/INDEX.md" ]; then
  echo "$(ts) ERROR: manifest/INDEX.md missing or empty" >> "$LOG"
  exit 1
fi

echo "$(ts) === manifest refresh complete ===" >> "$LOG"
