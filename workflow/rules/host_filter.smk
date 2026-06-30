rule host_filter_bowtie2:
    input:
        r1="data/trimmed/htp/{sample}_R1.fastq.gz",
        r2="data/trimmed/htp/{sample}_R2.fastq.gz"
    output:
        r1="data/host_filtered/htp/{sample}_R1.fastq.gz",
        r2="data/host_filtered/htp/{sample}_R2.fastq.gz",
        sam="results/host_filter/{sample}.sam"
    params:
        index="resources/genomes/host/bowtie2_index/host"
    log:
        "logs/host_filter/{sample}.log"
    threads: 8
    conda:
        "workflow/envs/bowtie2.yaml"
    shell:
        """
        mkdir -p data/host_filtered/htp results/host_filter logs/host_filter
        bowtie2 \
            -x {params.index} \
            -1 {input.r1} \
            -2 {input.r2} \
            --very-sensitive-local \
            --threads {threads} \
            --un-conc-gz data/host_filtered/htp/{wildcards.sample}_R%.fastq.gz \
            -S {output.sam} > {log} 2>&1
        """