from pathlib import Path
import pandas as pd

input_files = list(snakemake.input)
output_file = snakemake.output[0]

dfs = []

for fp in input_files:
    fp = Path(fp)
    sample = fp.name.split(".")[0]

    df = pd.read_csv(fp, sep="\t")
    cols = [c for c in df.columns]

    if "name" in cols:
        tax_col = "name"
    elif "taxonomy_name" in cols:
        tax_col = "taxonomy_name"
    else:
        raise ValueError(f"Could not find taxonomy name column in {fp}")

    if "new_est_reads" in cols:
        value_col = "new_est_reads"
    elif "fraction_total_reads" in cols:
        value_col = "fraction_total_reads"
    else:
        raise ValueError(f"Could not find abundance column in {fp}")

    sub = df[[tax_col, value_col]].copy()
    sub.columns = ["taxon", sample]
    dfs.append(sub)

merged = dfs[0]
for df in dfs[1:]:
    merged = merged.merge(df, on="taxon", how="outer")

merged = merged.fillna(0)

Path(output_file).parent.mkdir(parents=True, exist_ok=True)
merged.to_csv(output_file, sep="\t", index=False)