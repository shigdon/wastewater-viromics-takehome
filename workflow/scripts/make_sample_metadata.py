import pandas as pd
from pathlib import Path

samples = pd.read_csv(snakemake.input.samples)

df = samples.copy()
df = df.rename(columns={"sample_id": "sample"})

keep = [
    "sample",
    "site",
    "date",
    "treatment",
    "matrix",
    "srr",
    "biosample",
    "library_strategy",
    "library_source",
    "layout",
]
df = df[keep]

df["pair_id"] = df["site"].astype(str) + "_" + df["date"].astype(str)

Path(snakemake.output[0]).parent.mkdir(parents=True, exist_ok=True)
df.to_csv(snakemake.output[0], sep="\t", index=False)