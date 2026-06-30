configfile: "config/config.yaml"

include: "workflow/rules/common.smk"
include: "workflow/rules/download.smk"
include: "workflow/rules/qc.smk"
include: "workflow/rules/dedupe.smk"
include: "workflow/rules/reformat.smk"
include: "workflow/rules/host_filter.smk"

rule all:
    input:
        expand("results/qc/fastp/{sample}.html", sample=SAMPLES),
        expand("results/qc/fastp/{sample}.json", sample=SAMPLES),
        expand("data/host_filtered/htp/{sample}_R1.host_filtered.fastq.gz", sample=SAMPLES),
        expand("data/host_filtered/htp/{sample}_R2.host_filtered.fastq.gz", sample=SAMPLES)
