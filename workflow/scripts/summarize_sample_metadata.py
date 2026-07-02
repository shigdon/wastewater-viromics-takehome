import pandas as pd
from pathlib import Path

samples = pd.read_csv(snakemake.input.samples)

if "sample_id" in samples.columns:
    samples = samples.rename(columns={"sample_id": "sample"})
elif "sample" not in samples.columns:
    raise ValueError("Expected 'sample_id' or 'sample' column in samples_htp.csv")

rows = []

for sample in samples["sample"]:
    site = None
    date = None
    treatment = None

    parts = sample.split("_")
    if len(parts) >= 3:
        site = parts[0]
        date = parts[1]
        treatment = parts[2]
    else:
        raise ValueError(f"Cannot parse site/date/treatment from sample name: {sample}")

    rows.append({
        "sample": sample,
        "site": site,
        "date": date,
        "treatment": treatment,
        "is_enriched": treatment.lower() == "enriched",
    })

df = pd.DataFrame(rows)

out_path = Path(snakemake.output[0])
out_path.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(out_path, sep="\t", index=False)