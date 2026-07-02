import pandas as pd
import subprocess
import shutil
from pathlib import Path

samples = pd.read_csv(snakemake.input.samples)
samples = samples.rename(columns={"sample_id": "sample"})

out_path = Path(snakemake.output[0])
out_path.parent.mkdir(parents=True, exist_ok=True)

log_path = Path(snakemake.log[0]) if len(snakemake.log) > 0 else None
if log_path is not None:
    log_path.parent.mkdir(parents=True, exist_ok=True)

def log(msg):
    if log_path is not None:
        with open(log_path, "a") as fh:
            fh.write(str(msg) + "\n")

samtools_path = shutil.which("samtools")
if samtools_path is None:
    raise RuntimeError("samtools not found in PATH inside Snakemake conda environment")
log(f"Using samtools: {samtools_path}")

rows = []

def run_count(args):
    result = subprocess.run(args, check=True, capture_output=True, text=True)
    return int(result.stdout.strip())

for sample in samples["sample"]:
    bam = Path(f"results/host_filter/bwa/{sample}.human.bam")

    if not bam.exists():
        raise FileNotFoundError(f"Missing BAM for sample {sample}: {bam}")

    log(f"Processing sample {sample}: {bam}")

    total_reads = run_count(["samtools", "view", "-c", str(bam)])
    mapped_reads = run_count(["samtools", "view", "-c", "-F", "4", str(bam)])
    unmapped_reads = run_count(["samtools", "view", "-c", "-f", "4", str(bam)])
    both_mates_unmapped = run_count(["samtools", "view", "-c", "-f", "12", "-F", "256", str(bam)])

    rows.append({
        "sample": sample,
        "bam": str(bam),
        "total_reads": total_reads,
        "mapped_reads": mapped_reads,
        "unmapped_reads": unmapped_reads,
        "both_mates_unmapped": both_mates_unmapped,
        "mapped_fraction": mapped_reads / total_reads if total_reads else 0,
        "unmapped_fraction": unmapped_reads / total_reads if total_reads else 0,
        "both_mates_unmapped_fraction": both_mates_unmapped / total_reads if total_reads else 0,
    })

df = pd.DataFrame(rows)
df.to_csv(out_path, sep="\t", index=False)
log(f"Wrote {out_path}")