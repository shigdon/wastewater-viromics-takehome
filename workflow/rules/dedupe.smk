rule dedupe_bbtools:
    input:
        r1="data/trimmed/htp/{sample}_R1.trimmed.fastq.gz",
        r2="data/trimmed/htp/{sample}_R2.trimmed.fastq.gz"
    output:
        interleaved="data/deduped/htp/{sample}.deduped.fastq.gz"
    log:
        "logs/dedupe/{sample}.log"
    threads: 4
    conda:
        "../envs/bbtools.yaml"
    shell:
        r"""
        mkdir -p data/deduped/htp logs/dedupe

        dedupe.sh \
            -Xmx8g \
            in1={input.r1} in2={input.r2} \
            out={output.interleaved} \
            threads={threads} \
            ordered=t \
            > {log} 2>&1
        """