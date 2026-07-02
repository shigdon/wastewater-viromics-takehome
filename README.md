# Wastewater viromics take-home

Reanalysis of a subset of Rothman et al. wastewater metatranscriptomic data using a reproducible Snakemake workflow and a rendered Jupyter notebook report. The project focuses on QC, host filtering, taxonomic composition, viral relative abundance, and exploratory SARS-CoV-2 reference-based analysis across enriched and unenriched samples from a single wastewater treatment plant.

## Objectives

- Reproduce an end-to-end metatranscriptomic analysis workflow on a selected subset of wastewater samples.
- Compare enriched and unenriched libraries across consecutive dates from a single wastewater treatment plant.
- Generate plots and biological interpretations for each required analysis step.
- Present one biologically focused multiple-choice question per analysis step.

## Deliverables

- Runnable Snakemake workflow.
- Jupyter notebook containing analysis, plots, interpretation, and MCQs.
- Static HTML report rendered from the executed notebook.

## Repository structure

```text
.
├── config
│   ├── config.yaml
│   └── samples_htp.csv
├── metadata
│   ├── PRJNA729801_htp_.all.runinfo.csv
│   ├── PRJNA729801_htp_.filtered.csv
│   ├── PRJNA729801_htp_.filtered.runinfo.csv
│   ├── PRJNA729801_htp_.filtered.tsv
│   └── PRJNA729801_htp_.summary.txt
├── misc
│   └── workflow_rulegraph.svg
├── README.md
├── repo_tree.txt
├── reports
│   └── takehome_wastewater_viromics.html
├── resources
│   └── reference
│       └── sars_cov2
│           ├── NC_045512.2.fa
│           ├── NC_045512.2.fa.amb
│           ├── NC_045512.2.fa.ann
│           ├── NC_045512.2.fa.bwt
│           ├── NC_045512.2.fa.fai
│           ├── NC_045512.2.fa.pac
│           └── NC_045512.2.fa.sa
├── results
│   └── notebooks
│       └── takehome_wastewater_viromics.executed.ipynb
├── Snakefile
└── workflow
    ├── envs
    │   ├── alignment.yaml
    │   ├── bbtools.yaml
    │   ├── bwa.yaml
    │   ├── fastp.yaml
    │   ├── kraken.yaml
    │   ├── python_report.yaml
    │   ├── r_analysis.yaml
    │   ├── r_metadata.yaml
    │   └── sra-tools.yaml
    ├── notebooks
    │   └── takehome_wastewater_viromics.ipynb
    ├── rules
    │   ├── common.smk
    │   ├── dedupe.smk
    │   ├── download.smk
    │   ├── downsample.smk
    │   ├── host_filter.smk
    │   ├── metadata.smk
    │   ├── qc.smk
    │   ├── reformat.smk
    │   ├── report.smk
    │   ├── sars_cov2.smk
    │   └── taxonomy.smk
    └── scripts
        ├── get_sra_runs.sh
        ├── make_sample_metadata.py
        ├── make_samples_htp.R
        ├── merge_bracken.py
        ├── merge_sars_cov2_stats.py
        ├── summarize_host_filter.py
        ├── summarize_qc.py
        ├── summarize_sample_metadata.py
        └── summarize_viral_taxa.py

15 directories, 50 files

```

The workflow uses a top-level `Snakefile` and modular rule files under `workflow/rules/` so that each major analysis step is explicit, inspectable, and reproducible.

## Samples

The analysis uses a curated subset of 10 libraries from the HTP site, representing 5 consecutive date pairs with matched enriched and unenriched samples. The committed sample manifest at `config/samples_htp.csv` is the single source of truth for workflow execution and downstream analysis.

The sample sheet includes sample-level metadata used throughout the workflow, including:

- sample name
- site
- collection date
- treatment / enrichment status
- SRA accession
- library metadata needed for download and interpretation

## Sample manifest provenance

Although `config/samples_htp.csv` is committed and used directly by Snakemake, its provenance is documented in the repository.

1. `scripts/fetch_sra_runinfo_htp.sh` fetches and filters SRA run metadata for the HTP subset.
2. `scripts/make_samples_htp.R` parses sample names, extracts date and treatment information, identifies matched enriched/unenriched pairs, and writes the final curated manifest.

These helper scripts are included for transparency but are not required for a standard workflow run because the final sample manifest is already present.

## Workflow overview

The pipeline is organized into the following major stages:

1. **Download**
   - Download raw sequencing data for the selected SRR accessions.

2. **QC and preprocessing**
   - Adapter and quality trimming.
   - Deduplication / duplicate handling.
   - FASTQ reformatting and standardization.
   - Downsampling to the target depth.

3. **Host filtering**
   - Removal of host-associated reads before downstream metatranscriptomic analysis.

4. **Taxonomic profiling**
   - Classification with Kraken2.
   - Abundance estimation with Bracken.
   - Merged genus- and species-level abundance tables across samples.

5. **Viral summary analysis**
   - Viral relative abundance summaries derived from the merged taxonomy outputs.
   - Comparison of enriched and unenriched libraries across timepoints.

6. **SARS-CoV-2 reference-based follow-up**
   - Alignment of host-filtered reads to the SARS-CoV-2 reference genome.
   - Summary of mapped reads, mean depth, and genome breadth.
   - Exploratory single-sample SNV calling for the strongest enriched sample.

7. **Notebook rendering**
   - Execution of the final Jupyter notebook with `nbconvert`.
   - Rendering of the executed notebook to static HTML.

## Final outputs

The most important final outputs are:

- `results/summary/sample_metadata.tsv`
- `results/summary/qc_summary.tsv`
- `results/summary/host_filter_summary.tsv`
- `results/taxonomy/merged/bracken_genus_counts.tsv`
- `results/taxonomy/merged/bracken_species_counts.tsv`
- `results/summary/viral_taxa_summary.tsv`
- `results/summary/sars_cov2_alignment_summary.tsv`
- `results/notebooks/takehome_wastewater_viromics.executed.ipynb`
- `reports/takehome_wastewater_viromics.html`

## Data

The workflow operates on a curated set of HTP libraries defined in `config/samples_htp.csv`. Raw sequencing files are downloaded from SRA at runtime using the accessions in that manifest. Large raw inputs and heavy intermediates are not intended to be tracked in Git, keeping the repository lightweight while preserving reproducibility of sample selection and workflow execution.

## Taxonomic classification and databases

Taxonomic classification of host-filtered reads is performed with Kraken2 followed by Bracken for abundance estimation.

The workflow expects paths to the Kraken2 / Bracken database to be configured in `config/config.yaml`. In the completed analysis, a standard Kraken2 database was used for broad metatranscriptomic classification, with Bracken used to summarize abundance at genus and species level.

Because large reference databases are external to the repository, they are configured by path rather than committed to Git.

## Reproducibility

All preprocessing, summarization, and report generation are orchestrated with **Snakemake**. The final notebook reads workflow outputs from the `results/summary/` and `results/taxonomy/merged/` directories rather than recomputing preprocessing inline, which keeps the report modular and reproducible.

The repository includes:

- rule-specific Conda environments under `workflow/envs/`,
- modular Snakemake rules under `workflow/rules/`,
- helper scripts for summary-table generation under `workflow/scripts/`,
- and a final notebook that can be executed interactively or rendered non-interactively through Snakemake.

## Running the workflow

### Dry run

```bash
snakemake -n
```

### Run the full workflow

```bash
snakemake --use-conda --cores 8
```

### Render the final notebook report only

```bash
snakemake --use-conda --cores 2 reports/takehome_wastewater_viromics.html
```

## Notes for reviewers

This repository is organized so that each major analysis step produces inspectable outputs and summary tables. The committed sample sheet provides a stable and reviewable record of the selected libraries, while the helper scripts document how that manifest was derived from SRA metadata. The final notebook assembles workflow outputs into a stepwise biological narrative with plots, interpretation, and one biologically focused MCQ per analysis section.