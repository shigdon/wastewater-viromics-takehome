configfile: "config/config.yaml"

include: "workflow/rules/common.smk"
include: "workflow/rules/download.smk"
include: "workflow/rules/qc.smk"
include: "workflow/rules/dedupe.smk"
include: "workflow/rules/reformat.smk"
include: "workflow/rules/downsample.smk"
include: "workflow/rules/host_filter.smk"
include: "workflow/rules/taxonomy.smk"
include: "workflow/rules/report.smk"

rule all:
    input:
        expand("results/qc/fastp/{sample}.html", sample=SAMPLES),
        expand("results/qc/fastp/{sample}.json", sample=SAMPLES),
        expand("data/host_filtered/htp/{sample}_R1.host_filtered.fastq.gz", sample=SAMPLES),
        expand("data/host_filtered/htp/{sample}_R2.host_filtered.fastq.gz", sample=SAMPLES),
        expand("results/taxonomy/kraken2/{sample}.report.txt", sample=SAMPLES),
        expand("results/taxonomy/kraken2/{sample}.kraken.txt", sample=SAMPLES),
        expand("results/taxonomy/bracken/{sample}.G.bracken.tsv", sample=SAMPLES),
        expand("results/taxonomy/bracken/{sample}.S.bracken.tsv", sample=SAMPLES),
        "results/taxonomy/merged/bracken_genus_counts.tsv",
        "results/taxonomy/merged/bracken_species_counts.tsv"
