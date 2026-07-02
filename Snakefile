configfile: "config/config.yaml"

include: "workflow/rules/common.smk"
include: "workflow/rules/download.smk"
include: "workflow/rules/qc.smk"
include: "workflow/rules/dedupe.smk"
include: "workflow/rules/reformat.smk"
include: "workflow/rules/downsample.smk"
include: "workflow/rules/host_filter.smk"
include: "workflow/rules/taxonomy.smk"
include: "workflow/rules/sars_cov2.smk"
include: "workflow/rules/report.smk"

rule all:
    input:
        # QC summary products
        "results/summary/sample_metadata.tsv",
        "results/summary/qc_summary.tsv",
        "results/summary/host_filter_summary.tsv",

        # Taxonomy merged outputs used in notebook
        "results/taxonomy/merged/bracken_genus_counts.tsv",
        "results/taxonomy/merged/bracken_species_counts.tsv",

        # Viral summary outputs
        "results/summary/viral_taxa_summary.tsv",

        # SARS-CoV-2 summary output
        "results/summary/sars_cov2_alignment_summary.tsv",

        # Final rendered notebook deliverables
        "results/notebooks/takehome_wastewater_viromics.executed.ipynb",
        "reports/takehome_wastewater_viromics.html"
