rule deinterleave_deduped:
    input:
        interleaved="data/deduped/htp/{sample}.deduped.fastq.gz"
    output:
        r1="data/deduped_split/htp/{sample}_R1.deduped.fastq.gz",
        r2="data/deduped_split/htp/{sample}_R2.deduped.fastq.gz"
    log:
        "logs/reformat/{sample}.log"
    threads: 2
    conda:
        "../envs/bbtools.yaml"
    shell:
        r"""
        mkdir -p data/deduped_split/htp logs/reformat

        reformat.sh \
            in={input.interleaved} \
            out1={output.r1} \
            out2={output.r2} \
            threads={threads} \
            > {log} 2>&1
        """