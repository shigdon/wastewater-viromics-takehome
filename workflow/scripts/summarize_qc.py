import json
import pandas as pd
from pathlib import Path

samples = pd.read_csv(snakemake.input.samples)
samples = samples.rename(columns={"sample_id": "sample"})

rows = []

for sample in samples["sample"]:
    json_path = Path(f"results/qc/fastp/{sample}.json")

    if not json_path.exists():
        raise FileNotFoundError(f"Missing fastp JSON for sample {sample}: {json_path}")

    with open(json_path) as f:
        data = json.load(f)

    summary = data.get("summary", {})
    before = summary.get("before_filtering", {})
    after = summary.get("after_filtering", {})
    filt = data.get("filtering_result", {})
    dup = data.get("duplication", {})
    adapter = data.get("adapter_cutting", {})

    reads_before = before.get("total_reads")
    reads_after = after.get("total_reads")
    bases_before = before.get("total_bases")
    bases_after = after.get("total_bases")

    rows.append({
        "sample": sample,
        "reads_before": reads_before,
        "reads_after": reads_after,
        "reads_retained_fraction": (reads_after / reads_before) if reads_before else None,
        "bases_before": bases_before,
        "bases_after": bases_after,
        "bases_retained_fraction": (bases_after / bases_before) if bases_before else None,
        "read1_mean_length_before": before.get("read1_mean_length"),
        "read2_mean_length_before": before.get("read2_mean_length"),
        "read1_mean_length_after": after.get("read1_mean_length"),
        "read2_mean_length_after": after.get("read2_mean_length"),
        "q20_rate_before": before.get("q20_rate"),
        "q20_rate_after": after.get("q20_rate"),
        "q30_rate_before": before.get("q30_rate"),
        "q30_rate_after": after.get("q30_rate"),
        "gc_content_before": before.get("gc_content"),
        "gc_content_after": after.get("gc_content"),
        "passed_filter_reads": filt.get("passed_filter_reads"),
        "low_quality_reads": filt.get("low_quality_reads"),
        "too_many_N_reads": filt.get("too_many_N_reads"),
        "adapter_dimer_reads": filt.get("adapter_dimer_reads"),
        "too_short_reads": filt.get("too_short_reads"),
        "too_long_reads": filt.get("too_long_reads"),
        "duplication_rate": dup.get("rate"),
        "adapter_trimmed_reads": adapter.get("adapter_trimmed_reads"),
        "adapter_trimmed_bases": adapter.get("adapter_trimmed_bases"),
    })

df = pd.DataFrame(rows)

Path(snakemake.output[0]).parent.mkdir(parents=True, exist_ok=True)
df.to_csv(snakemake.output[0], sep="\t", index=False)