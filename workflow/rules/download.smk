rule download_srr_fastq:
    output:
        r1="data/raw/htp/{sample}_R1.fastq.gz",
        r2="data/raw/htp/{sample}_R2.fastq.gz"
    params:
        srr=get_srr,
        sra_dir="data/sra",
        tmp_dir=lambda wc: f"data/tmp/sra/{wc.sample}"
    log:
        "logs/download/{sample}.log"
    threads: 3
    resources:
        sra_jobs=1
    conda:
        "../envs/sra-tools.yaml"
    shell:
        r"""
        set -euo pipefail

        mkdir -p data/raw/htp data/sra logs/download {params.tmp_dir}

        prefetch \
            --output-directory {params.sra_dir} \
            {params.srr} >> {log} 2>&1

        fasterq-dump \
            --split-files \
            --threads {threads} \
            --temp {params.tmp_dir} \
            --outdir data/raw/htp \
            {params.sra_dir}/{params.srr} >> {log} 2>&1

        pigz -p {threads} -f data/raw/htp/{params.srr}_1.fastq
        pigz -p {threads} -f data/raw/htp/{params.srr}_2.fastq

        mv data/raw/htp/{params.srr}_1.fastq.gz {output.r1}
        mv data/raw/htp/{params.srr}_2.fastq.gz {output.r2}

        rm -rf {params.tmp_dir}
        """