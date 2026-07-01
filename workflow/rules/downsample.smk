rule downsample_reformatted:
    input:
        r1="data/deduped_split/htp/{sample}_R1.deduped.fastq.gz",
        r2="data/deduped_split/htp/{sample}_R2.deduped.fastq.gz"
    output:
        r1="data/downsampled/htp/{sample}_R1.downsampled.fastq.gz",
        r2="data/downsampled/htp/{sample}_R2.downsampled.fastq.gz"
    params:
        bases=config["downsampling"]["target_bases"],
        seed=config["downsampling"]["seed"]
    threads:
        4
    log:
        "logs/downsample/{sample}.log"
    conda:
        "../envs/bbtools.yaml"
    shell:
        r"""
        mkdir -p data/downsampled/htp logs/downsample

        reformat.sh \
          in1={input.r1} \
          in2={input.r2} \
          out1={output.r1} \
          out2={output.r2} \
          samplebasestarget={params.bases} \
          sampleseed={params.seed} \
          > {log} 2>&1
        """