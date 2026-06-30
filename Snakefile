configfile: "config/config.yaml"

include: "workflow/rules/common.smk"
include: "workflow/rules/download.smk"
include: "workflow/rules/qc.smk"
include: "workflow/rules/dedupe.smk"

rule all:
    input:
        expand("results/qc/fastp/{sample}.html", sample=SAMPLES),
        expand("results/qc/fastp/{sample}.json", sample=SAMPLES),
        expand("data/deduped/htp/{sample}.deduped.fastq.gz", sample=SAMPLES)
