rule download_host_reference:
    output:
        fasta=config["paths"]["host_reference"]
    log:
        "logs/host_reference/download.log"
    conda:
        "../envs/bwa.yaml"
    shell:
        r"""
        mkdir -p $(dirname {output.fasta}) logs/host_reference

        wget -O {output.fasta} \
          "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz" \
          > {log} 2>&1
        """

rule index_host_reference_bwa:
    input:
        fasta=config["paths"]["host_reference"]
    output:
        amb=config["paths"]["host_reference"] + ".amb",
        ann=config["paths"]["host_reference"] + ".ann",
        bwt=config["paths"]["host_reference"] + ".bwt",
        pac=config["paths"]["host_reference"] + ".pac",
        sa=config["paths"]["host_reference"] + ".sa"
    log:
        "logs/host_reference/bwa_index.log"
    threads: 4
    conda:
        "../envs/bwa.yaml"
    shell:
        r"""
        bwa index {input.fasta} > {log} 2>&1
        """

rule host_filter_bwa:
    input:
        r1="data/downsampled/htp/{sample}_R1.downsampled.fastq.gz",
        r2="data/downsampled/htp/{sample}_R2.downsampled.fastq.gz",
        fasta=config["paths"]["host_reference"],
        amb=config["paths"]["host_reference"] + ".amb",
        ann=config["paths"]["host_reference"] + ".ann",
        bwt=config["paths"]["host_reference"] + ".bwt",
        pac=config["paths"]["host_reference"] + ".pac",
        sa=config["paths"]["host_reference"] + ".sa"
    output:
        bam="results/host_filter/bwa/{sample}.human.bam",
        unmapped_bam="results/host_filter/bwa/{sample}.human_unmapped.name_sorted.bam",
        r1="data/host_filtered/htp/{sample}_R1.host_filtered.fastq.gz",
        r2="data/host_filtered/htp/{sample}_R2.host_filtered.fastq.gz"
    log:
        "logs/host_filter/{sample}.log"
    threads: 4
    conda:
        "../envs/bwa.yaml"
    shell:
        r"""
        mkdir -p results/host_filter/bwa data/host_filtered/htp logs/host_filter

        # Map to human and save BAM
        bwa mem -t {threads} {input.fasta} {input.r1} {input.r2} 2>> {log} \
          | samtools view -b -o {output.bam} - 2>> {log}

        # Extract pairs where both mates are unmapped, name-sort
        samtools view -b -f 12 -F 256 {output.bam} 2>> {log} \
          | samtools sort -n -o {output.unmapped_bam} - 2>> {log}

        # Convert unmapped BAM to FASTQ and gzip
        samtools fastq \
          -1 >(gzip > {output.r1}) \
          -2 >(gzip > {output.r2}) \
          -0 /dev/null \
          -s /dev/null \
          -n \
          {output.unmapped_bam} >> {log} 2>&1
        """