rule fetch_htp_runinfo:
    output:
        "metadata/PRJNA729801_htp_.filtered.csv"
    log:
        "logs/metadata/fetch_htp_runinfo.log"
    shell:
        """
        mkdir -p metadata logs/metadata
        bash scripts/fetch_sra_runinfo_htp.sh > {log} 2>&1
        """

rule make_samplesheet:
    input:
        "metadata/PRJNA729801_htp_.filtered.csv"
    output:
        "config/samples_htp.csv"
    log:
        "logs/metadata/make_samplesheet.log"
    conda:
        "workflow/envs/r.yaml"
    shell:
        """
        mkdir -p config logs/metadata
        Rscript scripts/make_samples_htp.R {input} {output} > {log} 2>&1
        """