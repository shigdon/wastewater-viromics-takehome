# workflow/scripts/merge_sars_cov2_stats.py

from pathlib import Path
import pandas as pd

samples_tsv = Path(snakemake.input["samples"])
out_tsv = Path(snakemake.output["tsv"])

meta = pd.read_csv(samples_tsv, sep="\t")
rows = []

for sample in meta["sample"]:
    idxstats_path = Path(f"results/sars_cov2/stats/{sample}.idxstats.tsv")
    depth_path = Path(f"results/sars_cov2/stats/{sample}.depth.tsv")

    mapped_reads = 0
    ref_length = None

    if idxstats_path.exists():
        idx = pd.read_csv(
            idxstats_path,
            sep="\t",
            header=None,
            names=["chrom", "length", "mapped", "unmapped"]
        )
        idx = idx[idx["chrom"] != "*"]
        if not idx.empty:
            mapped_reads = int(idx["mapped"].sum())
            ref_length = int(idx["length"].iloc[0])

    mean_depth = 0.0
    breadth_1x = 0.0
    breadth_10x = 0.0

    if depth_path.exists():
        depth = pd.read_csv(
            depth_path,
            sep="\t",
            header=None,
            names=["chrom", "pos", "depth"]
        )
        if not depth.empty:
            if ref_length is None:
                ref_length = int(depth["pos"].max())
            mean_depth = float(depth["depth"].mean())
            breadth_1x = (depth["depth"] >= 1).sum() / ref_length
            breadth_10x = (depth["depth"] >= 10).sum() / ref_length

    rows.append({
        "sample": sample,
        "mapped_reads_sars_cov2": mapped_reads,
        "reference_length": ref_length,
        "mean_depth_sars_cov2": mean_depth,
        "breadth_1x_sars_cov2": breadth_1x,
        "breadth_10x_sars_cov2": breadth_10x
    })

out = pd.DataFrame(rows)
out = meta.merge(out, on="sample", how="left")
out.to_csv(out_tsv, sep="\t", index=False)