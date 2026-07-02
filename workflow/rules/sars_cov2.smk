# workflow/rules/sars_cov2.smk

# Index reference for samtools
rule index_sars_cov2_reference_faidx:
    input:
        fa="resources/reference/sars_cov2/NC_045512.2.fa"
    output:
        fai="resources/reference/sars_cov2/NC_045512.2.fa.fai"
    conda:
        "../envs/alignment.yaml"
    shell:
        r"""
        samtools faidx {input.fa}
        """


# Index reference for bwa
rule index_sars_cov2_reference_bwa:
    input:
        fa="resources/reference/sars_cov2/NC_045512.2.fa"
    output:
        bwt="resources/reference/sars_cov2/NC_045512.2.fa.bwt"
    conda:
        "../envs/alignment.yaml"
    shell:
        r"""
        bwa index {input.fa}
        """


# Align host-filtered reads to SARS-CoV-2 reference
rule align_sars_cov2:
    input:
        fa="resources/reference/sars_cov2/NC_045512.2.fa",
        bwt="resources/reference/sars_cov2/NC_045512.2.fa.bwt",
        r1="data/host_filtered/htp/{sample}_R1.host_filtered.fastq.gz",
        r2="data/host_filtered/htp/{sample}_R2.host_filtered.fastq.gz"
    output:
        bam="results/sars_cov2/alignment/{sample}.sorted.bam",
        bai="results/sars_cov2/alignment/{sample}.sorted.bam.bai"
    log:
        "logs/sars_cov2/align/{sample}.log"
    threads: 4
    conda:
        "../envs/alignment.yaml"
    shell:
        r"""
        mkdir -p results/sars_cov2/alignment logs/sars_cov2/align

        bwa mem -t {threads} {input.fa} {input.r1} {input.r2} 2>> {log} \
          | samtools sort -@ {threads} -o {output.bam} >> {log} 2>&1

        samtools index {output.bam} >> {log} 2>&1
        """


# Per-sample idxstats summary
rule sars_cov2_idxstats:
    input:
        bam="results/sars_cov2/alignment/{sample}.sorted.bam"
    output:
        txt="results/sars_cov2/stats/{sample}.idxstats.tsv"
    conda:
        "../envs/alignment.yaml"
    shell:
        r"""
        mkdir -p results/sars_cov2/stats
        samtools idxstats {input.bam} > {output.txt}
        """


# Per-sample depth summary
rule sars_cov2_depth:
    input:
        bam="results/sars_cov2/alignment/{sample}.sorted.bam",
        fai="resources/reference/sars_cov2/NC_045512.2.fa.fai"
    output:
        txt="results/sars_cov2/stats/{sample}.depth.tsv"
    conda:
        "../envs/alignment.yaml"
    shell:
        r"""
        samtools depth -aa {input.bam} > {output.txt}
        """


# Merge per-sample SARS-CoV-2 stats into one summary table
rule merge_sars_cov2_stats:
    input:
        samples="results/summary/sample_metadata.tsv",
        idxstats=expand("results/sars_cov2/stats/{sample}.idxstats.tsv", sample=SAMPLES),
        depth=expand("results/sars_cov2/stats/{sample}.depth.tsv", sample=SAMPLES)
    output:
        tsv="results/summary/sars_cov2_alignment_summary.tsv"
    conda:
        "../envs/python_report.yaml"
    script:
        "../scripts/merge_sars_cov2_stats.py"


# Optional variant calling rule (commented out until coverage supports it)
#rule call_sars_cov2_variants:
#    input:
#        fa="resources/reference/sars_cov2/NC_045512.2.fa",
#        bam="results/sars_cov2/alignment/{sample}.sorted.bam"
#    output:
#        vcf="results/sars_cov2/variants/{sample}.vcf.gz",
#        tbi="results/sars_cov2/variants/{sample}.vcf.gz.tbi"
#    conda:
#        "../envs/alignment.yaml"
#    shell:
#        r"""
#        mkdir -p results/sars_cov2/variants
#
#        bcftools mpileup -Ou -f {input.fa} {input.bam} \
#          | bcftools call -mv -Oz -o {output.vcf}
#
#        bcftools index -t {output.vcf}
#        """