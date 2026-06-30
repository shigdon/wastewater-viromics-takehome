rule fastp_qc:
    input:
        r1="data/raw/htp/{sample}_R1.fastq.gz",
        r2="data/raw/htp/{sample}_R2.fastq.gz"
    output:
        r1="data/trimmed/htp/{sample}_R1.trimmed.fastq.gz",
        r2="data/trimmed/htp/{sample}_R2.trimmed.fastq.gz",
        html="results/qc/fastp/{sample}.html",
        json="results/qc/fastp/{sample}.json"
    log:
        "logs/qc/fastp/{sample}.log"
    threads: 4
    conda:
        "../envs/fastp.yaml"
    shell:
        r"""
        mkdir -p data/trimmed/htp results/qc/fastp logs/qc/fastp

        fastp \
            --thread {threads} \
            -i {input.r1} -I {input.r2} \
            -o {output.r1} -O {output.r2} \
            -h {output.html} -j {output.json} \
            >> {log} 2>&1
        """