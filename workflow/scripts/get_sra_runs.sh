#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") --bioproject PRJNA729801 [options]

Required:
  --bioproject ID         BioProject accession, e.g. PRJNA729801

Optional:
  --pattern STR          Case-insensitive sample-name filter, default: HTP
  --outdir DIR           Output directory, default: metadata
  --prefix STR           Output file prefix, default: derived from bioproject + pattern
  --keep-all             Keep all runs table in addition to filtered outputs
  -h, --help             Show this help

Outputs:
  <outdir>/<prefix>.filtered.runinfo.csv
  <outdir>/<prefix>.filtered.csv
  <outdir>/<prefix>.filtered.tsv
  <outdir>/<prefix>.summary.txt
  and optionally:
  <outdir>/<prefix>.all.runinfo.csv

Notes:
- Requires Entrez Direct: esearch, efetch
- Designed to retrieve SRA RunInfo from a BioProject and filter rows by sample metadata
- Filtering checks these fields when present: SampleName, ScientificName, LibraryName, BioSample, Sample, Experiment
USAGE
}

BIOPROJECT=""
PATTERN="HTP"
OUTDIR="metadata"
PREFIX=""
KEEP_ALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bioproject)
      BIOPROJECT="$2"; shift 2 ;;
    --pattern)
      PATTERN="$2"; shift 2 ;;
    --outdir)
      OUTDIR="$2"; shift 2 ;;
    --prefix)
      PREFIX="$2"; shift 2 ;;
    --keep-all)
      KEEP_ALL=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1 ;;
  esac
done

if [[ -z "$BIOPROJECT" ]]; then
  echo "Error: --bioproject is required" >&2
  usage >&2
  exit 1
fi

for cmd in esearch efetch python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: required command not found: $cmd" >&2
    exit 1
  }
done

mkdir -p "$OUTDIR"

safe_pattern=$(echo "$PATTERN" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_')
if [[ -z "$PREFIX" ]]; then
  PREFIX="${BIOPROJECT}_${safe_pattern}"
fi

all_csv="$OUTDIR/${PREFIX}.all.runinfo.csv"
filtered_csv="$OUTDIR/${PREFIX}.filtered.runinfo.csv"
filtered_csv_simple="$OUTDIR/${PREFIX}.filtered.csv"
filtered_tsv="$OUTDIR/${PREFIX}.filtered.tsv"
summary_txt="$OUTDIR/${PREFIX}.summary.txt"

esearch -db sra -query "$BIOPROJECT" | efetch -format runinfo > "$all_csv"

python3 - "$all_csv" "$filtered_csv" "$filtered_csv_simple" "$filtered_tsv" "$summary_txt" "$PATTERN" <<'PY'
import csv, sys, re

all_csv, filtered_csv, filtered_csv_simple, filtered_tsv, summary_txt, pattern = sys.argv[1:]
regex = re.compile(pattern, re.IGNORECASE)

with open(all_csv, newline='', encoding='utf-8') as fh:
    rows = list(csv.DictReader(fh))

if not rows:
    raise SystemExit("No SRA runs returned for the supplied BioProject.")

candidate_fields = [
    'SampleName', 'ScientificName', 'LibraryName', 'BioSample',
    'Sample', 'Experiment', 'BioProject', 'LibraryLayout', 'LibraryStrategy'
]
fields_present = [f for f in candidate_fields if f in rows[0].keys()]

filtered = []
for row in rows:
    haystack = " | ".join(str(row.get(f, '')) for f in fields_present)
    if regex.search(haystack):
        filtered.append(row)

with open(filtered_csv, 'w', newline='', encoding='utf-8') as fh:
    writer = csv.DictWriter(fh, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(filtered)

simple_cols = [
    'Run', 'BioSample', 'SampleName', 'LibraryName', 'LibraryStrategy',
    'LibrarySource', 'LibraryLayout', 'Platform', 'Model', 'spots', 'bases',
    'avgLength', 'size_MB', 'download_path'
]
simple_cols = [c for c in simple_cols if c in rows[0].keys()]
with open(filtered_csv_simple, 'w', newline='', encoding='utf-8') as fh:
    writer = csv.writer(fh)
    writer.writerow(simple_cols)
    for row in filtered:
        writer.writerow([row.get(c, '') for c in simple_cols])

with open(filtered_tsv, 'w', newline='', encoding='utf-8') as fh:
    writer = csv.writer(fh, delimiter='\t')
    writer.writerow(simple_cols)
    for row in filtered:
        writer.writerow([row.get(c, '') for c in simple_cols])

runs = [r.get('Run', '') for r in filtered if r.get('Run')]
biosamples = sorted({r.get('BioSample', '') for r in filtered if r.get('BioSample')})
with open(summary_txt, 'w', encoding='utf-8') as fh:
    fh.write(f"BioProject: {rows[0].get('BioProject', 'unknown')}\n")
    fh.write(f"Filter pattern: {pattern}\n")
    fh.write(f"Total runs in BioProject: {len(rows)}\n")
    fh.write(f"Matched runs: {len(filtered)}\n")
    fh.write(f"Matched BioSamples: {len(biosamples)}\n")
    fh.write("\nRuns:\n")
    for run in runs:
        fh.write(run + "\n")
PY

if [[ "$KEEP_ALL" -ne 1 ]]; then
  rm -f "$all_csv"
fi

echo "Wrote: $filtered_csv"
echo "Wrote: $filtered_csv_simple"
echo "Wrote: $filtered_tsv"
echo "Wrote: $summary_txt"
if [[ "$KEEP_ALL" -eq 1 ]]; then
  echo "Wrote: $all_csv"
fi
