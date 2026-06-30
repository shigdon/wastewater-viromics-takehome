rule fastp_qc:
    input:
        r1="data/raw/htp/{sample}_R1.fastq.gz",
        r2="data/raw/htp/{sample}_R2.fastq.gz"
    output:
        r1="data/trimmed/htp/{sample}_R1.fastq.gz",
        r2="data/trimmed/htp/{sample}_R2.fastq.gz",
        html="results/qc/fastp/{sample}.html",
        json="results/qc/fastp/{sample}.json"
    log:
        "logs/qc/{sample}.log"
    threads: 8
    conda:
        "workflow/envs/fastp.yaml"
    shell:
        """
        mkdir -p data/trimmed/htp results/qc/fastp logs/qc
        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.r1} \
            -O {output.r2} \
            --thread {threads} \
            --html {output.html} \
            --json {output.json} > {log} 2>&1
        """