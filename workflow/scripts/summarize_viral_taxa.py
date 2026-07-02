import pandas as pd
import re
from pathlib import Path

species = pd.read_csv(snakemake.input.species, sep="\t")
metadata = pd.read_csv(snakemake.input.metadata)

metadata = metadata.rename(columns={"sample_id": "sample"})

VIRAL_PATTERN = re.compile(
    r"(virus|viridae|corona|phage)",
    flags=re.IGNORECASE
)

KNOWN_SARS_COV_2_TAXIDS = {
    3418604,  # Betacoronavirus pandemicum
    694009,   # Severe acute respiratory syndrome-related coronavirus
    2697049,  # SARS-CoV-2
}

KNOWN_SARS_COV_2_NAMES = {
    "betacoronavirus pandemicum",
    "severe acute respiratory syndrome-related coronavirus",
    "sars-cov-2",
    "sars cov 2",
    "severe acute respiratory syndrome coronavirus 2",
}

def melt_species_counts(df):
    id_cols = ["taxon", "taxonomy_id", "taxonomy_lvl"]
    sample_cols = [c for c in df.columns if c not in id_cols]

    long_df = df.melt(
        id_vars=id_cols,
        value_vars=sample_cols,
        var_name="sample",
        value_name="reads"
    )

    long_df["reads"] = pd.to_numeric(long_df["reads"], errors="coerce").fillna(0)
    long_df["taxonomy_id"] = pd.to_numeric(long_df["taxonomy_id"], errors="coerce")

    return long_df

def is_viral_taxon(row):
    taxon = str(row["taxon"]) if pd.notna(row["taxon"]) else ""
    return bool(VIRAL_PATTERN.search(taxon))

def is_sars_cov_2(row):
    taxon = str(row["taxon"]).strip().lower() if pd.notna(row["taxon"]) else ""
    taxid = row["taxonomy_id"]

    if pd.notna(taxid) and int(taxid) in KNOWN_SARS_COV_2_TAXIDS:
        return True

    return taxon in KNOWN_SARS_COV_2_NAMES

species_long = melt_species_counts(species)

species_long = species_long[species_long["taxonomy_lvl"] == "S"].copy()

species_long["is_viral"] = species_long.apply(is_viral_taxon, axis=1)
species_long["is_sars_cov_2"] = species_long.apply(is_sars_cov_2, axis=1)

viral = species_long[species_long["is_viral"]].copy()

totals = viral.groupby("sample")["reads"].sum().rename("viral_total_reads")
viral = viral.merge(totals, on="sample", how="left")
viral["relative_abundance"] = viral["reads"] / viral["viral_total_reads"]

viral = viral.merge(
    metadata[["sample", "site", "date", "treatment"]],
    on="sample",
    how="left"
)

viral = viral.rename(columns={"taxon": "name"})

viral = viral[
    [
        "sample",
        "site",
        "date",
        "treatment",
        "taxonomy_lvl",
        "taxonomy_id",
        "name",
        "reads",
        "viral_total_reads",
        "relative_abundance",
        "is_viral",
        "is_sars_cov_2",
    ]
].sort_values(
    ["sample", "reads"],
    ascending=[True, False]
)

Path(snakemake.output[0]).parent.mkdir(parents=True, exist_ok=True)
viral.to_csv(snakemake.output[0], sep="\t", index=False)