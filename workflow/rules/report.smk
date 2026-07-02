import os

rule sample_metadata:
    input:
        samples="config/samples_htp.csv"
    output:
        "results/summary/sample_metadata.tsv"
    log:
        "logs/report/sample_metadata.log"
    conda:
        "../envs/python_report.yaml"
    script:
        "../scripts/summarize_sample_metadata.py"


rule qc_summary:
    input:
        samples="config/samples_htp.csv"
    output:
        "results/summary/qc_summary.tsv"
    log:
        "logs/report/qc_summary.log"
    conda:
        "../envs/python_report.yaml"
    script:
        "../scripts/summarize_qc.py"


rule host_filter_summary:
    input:
        samples="config/samples_htp.csv"
    output:
        "results/summary/host_filter_summary.tsv"
    log:
        "logs/report/host_filter_summary.log"
    conda:
        "../envs/python_report.yaml"
    script:
        "../scripts/summarize_host_filter.py"


rule viral_taxa_summary:
    input:
        species="results/taxonomy/merged/bracken_species_counts.tsv",
        metadata="config/samples_htp.csv"
    output:
        "results/summary/viral_taxa_summary.tsv"
    log:
        "logs/report/viral_taxa_summary.log"
    conda:
        "../envs/python_report.yaml"
    script:
        "../scripts/summarize_viral_taxa.py"


rule render_takehome_notebook:
    input:
        metadata="results/summary/sample_metadata.tsv",
        qc="results/summary/qc_summary.tsv",
        host="results/summary/host_filter_summary.tsv",
        species="results/taxonomy/merged/bracken_species_counts.tsv",
        viral="results/summary/viral_taxa_summary.tsv",
        sars="results/summary/sars_cov2_alignment_summary.tsv",
        notebook="workflow/notebooks/takehome_wastewater_viromics.ipynb"
    output:
        notebook="results/notebooks/takehome_wastewater_viromics.executed.ipynb",
        html="reports/takehome_wastewater_viromics.html"
    log:
        "logs/report/render_takehome_notebook.log"
    conda:
        "../envs/python_report.yaml"
    shell:
        r"""
        mkdir -p results/notebooks reports logs/report
        : > {log}

        jupyter nbconvert \
          --to notebook \
          --execute {input.notebook} \
          --output takehome_wastewater_viromics.executed.ipynb \
          --output-dir results/notebooks \
          >> {log} 2>&1

        jupyter nbconvert \
          --to html results/notebooks/takehome_wastewater_viromics.executed.ipynb \
          --output takehome_wastewater_viromics \
          --output-dir reports \
          >> {log} 2>&1
        """