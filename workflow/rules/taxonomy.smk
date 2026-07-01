rule kraken2_classify:
    input:
        r1="data/host_filtered/htp/{sample}_R1.host_filtered.fastq.gz",
        r2="data/host_filtered/htp/{sample}_R2.host_filtered.fastq.gz"
    output:
        report="results/taxonomy/kraken2/{sample}.report.txt",
        output="results/taxonomy/kraken2/{sample}.kraken.txt"
    params:
        db=config["paths"]["kraken_db"]
    log:
        "logs/taxonomy/kraken2/{sample}.log"
    threads:
        12
    resources:
        kraken_db=1
    conda:
        "../envs/kraken.yaml"
    shell:
        r"""
        mkdir -p results/taxonomy/kraken2 logs/taxonomy/kraken2

        kraken2 \
          --db {params.db} \
          --paired \
          --gzip-compressed \
          --use-names \
          --threads {threads} \
          --report {output.report} \
          --output {output.output} \
          {input.r1} {input.r2} \
          > {log} 2>&1
        """

rule bracken_genus:
    input:
        report="results/taxonomy/kraken2/{sample}.report.txt"
    output:
        abundance="results/taxonomy/bracken/{sample}.G.bracken.tsv",
        report="results/taxonomy/bracken/{sample}.G.bracken.report"
    params:
        db=config["paths"]["bracken_db"],
        read_len=config["taxonomy"]["bracken_read_length"]
    log:
        "logs/taxonomy/bracken/{sample}.G.log"
    conda:
        "../envs/kraken.yaml"
    shell:
        r"""
        mkdir -p results/taxonomy/bracken logs/taxonomy/bracken

        bracken \
          -d {params.db} \
          -i {input.report} \
          -o {output.abundance} \
          -w {output.report} \
          -r {params.read_len} \
          -l G \
          > {log} 2>&1
        """

rule bracken_species:
    input:
        report="results/taxonomy/kraken2/{sample}.report.txt"
    output:
        abundance="results/taxonomy/bracken/{sample}.S.bracken.tsv",
        report="results/taxonomy/bracken/{sample}.S.bracken.report"
    params:
        db=config["paths"]["bracken_db"],
        read_len=config["taxonomy"]["bracken_read_length"]
    log:
        "logs/taxonomy/bracken/{sample}.S.log"
    conda:
        "../envs/kraken.yaml"
    shell:
        r"""
        mkdir -p results/taxonomy/bracken logs/taxonomy/bracken

        bracken \
          -d {params.db} \
          -i {input.report} \
          -o {output.abundance} \
          -w {output.report} \
          -r {params.read_len} \
          -l S \
          > {log} 2>&1
        """

rule merge_bracken_genus:
    input:
        expand("results/taxonomy/bracken/{sample}.G.bracken.tsv", sample=SAMPLES)
    output:
        "results/taxonomy/merged/bracken_genus_counts.tsv"
    params:
        level="G"
    conda:
        "../envs/kraken.yaml"
    script:
        "../scripts/merge_bracken.py"

rule merge_bracken_species:
    input:
        expand("results/taxonomy/bracken/{sample}.S.bracken.tsv", sample=SAMPLES)
    output:
        "results/taxonomy/merged/bracken_species_counts.tsv"
    params:
        level="S"
    conda:
        "../envs/kraken.yaml"
    script:
        "../scripts/merge_bracken.py"