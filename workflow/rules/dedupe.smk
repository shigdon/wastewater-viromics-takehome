rule dedupe_bbtools:
    input:
        r1="data/trimmed/htp/{sample}_R1.trimmed.fastq.gz",
        r2="data/trimmed/htp/{sample}_R2.trimmed.fastq.gz"
    output:
        r1="data/deduped/htp/{sample}_R1.deduped.fastq.gz",
        r2="data/deduped/htp/{sample}_R2.deduped.fastq.gz"
    log:
        "logs/dedupe/{sample}.log"
    threads: 4
    conda:
        "../envs/bbtools.yaml"
    shell:
        r"""
        mkdir -p data/deduped/htp logs/dedupe

        dedupe.sh \
            in1={input.r1} in2={input.r2} \
            out1={output.r1} out2={output.r2} \
            threads={threads} \
            ordered=t \
            > {log} 2>&1
        """