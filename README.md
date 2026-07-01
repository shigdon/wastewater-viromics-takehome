# Wastewater viromics take-home

Reanalysis of Rothman et al. wastewater metatranscriptomic data using a reproducible Snakemake workflow and an R Markdown report. The project focuses on QC, host filtering, taxonomic composition, viral relative abundance, and SARS-CoV-2 SNV exploration across enriched and unenriched samples. The workflow is organized so that Snakemake performs the end-to-end computation, while the final report assembles workflow outputs into a biological narrative.

## Objectives

- Reproduce an end-to-end metatranscriptomic analysis workflow on a selected subset of wastewater samples.
- Compare enriched and unenriched libraries across consecutive dates from a single wastewater treatment plant.
- Generate plots and biological interpretations for each required analysis step.
- Present one multiple-choice question per step that captures the main scientific takeaway.

## Deliverables

- Runnable workflow codebase.
- R Markdown report with analysis, implementation details, plots, and MCQs.
- Static HTML report.

## Repository structure

```text
.
├── README.md
├── .gitattributes
├── .gitignore
├── Snakefile
├── config/
│   ├── config.yaml
│   └── samples_htp.csv
├── metadata/
│   └── PRJNA729801_htp_.filtered.csv
├── scripts/
│   ├── fetch_sra_runinfo_htp.sh
│   └── make_samples_htp.R
├── workflow/
│   ├── rules/
│   │   ├── common.smk
│   │   ├── download.smk
│   │   ├── qc.smk
│   │   ├── host_filter.smk
│   │   ├── taxonomy.smk
│   │   ├── viral_abundance.smk
│   │   ├── snv.smk
│   │   └── report.smk
│   └── envs/
│       ├── sra-tools.yaml
│       ├── fastp.yaml
│       ├── bowtie2.yaml
│       ├── kraken2.yaml
│       ├── samtools.yaml
│       ├── r_analysis.yaml
│       └── quarto.yaml
├── analysis/
│   ├── wastewater_viromics_report.Rmd
│   └── styles.css
├── resources/
│   ├── references/
│   └── genomes/
├── data/
│   ├── raw/
│   │   └── htp/
│   ├── trimmed/
│   └── host_filtered/
├── results/
│   ├── qc/
│   ├── host_filter/
│   ├── taxonomy/
│   ├── viral/
│   ├── snv/
│   ├── tables/
│   ├── figures/
│   └── report/
└── docs/
```

The workflow uses a top-level `Snakefile` plus modular rule files under `workflow/rules/`, which is a standard way to keep larger Snakemake workflows readable and extensible.

## Sample manifest

The workflow treats `config/samples_htp.csv` as the single source of truth for sample-level metadata. This follows the conventional Snakemake pattern of using a tabular sample sheet as workflow configuration rather than generating the manifest dynamically during a standard run.

The sample sheet contains the selected 5 enriched/unenriched HTP date pairs and includes the metadata needed for both workflow execution and downstream analysis:

- `sample_id`
- `site`
- `date`
- `treatment`
- `matrix`
- `srr`
- `biosample`
- `library_strategy`
- `library_source`
- `layout`

## How the sample sheet was generated

Although `config/samples_htp.csv` is committed to the repository and used directly by Snakemake, its provenance is fully documented.

The sample sheet was generated in two steps:

1. **Fetch HTP-specific SRA metadata**  
   Script: `workflow/scripts/fetch_sra_runinfo_htp.sh`  
   Output: `metadata/PRJNA729801_htp_.filtered.csv`

   This script queries SRA/RunInfo metadata for BioProject PRJNA729801 and filters rows to HTP samples.

2. **Parse and curate the final sample manifest**  
   Script: `workflow/scripts/make_samples_htp.R`  
   Input: `metadata/PRJNA729801_htp_.filtered.csv`  
   Output: `config/samples_htp.csv`

   This script parses HTP sample names, infers date and treatment, identifies matched enriched/unenriched HTP pairs, and writes the final curated 10-sample manifest used by the workflow.

These scripts are included for transparency and reproducibility, but they are not required for a standard pipeline run because the resulting sample sheet is already present in the repository.

## Analysis overview

### 1. QC

- Adapter and quality trimming.
- Summary of read retention and quality metrics.
- Plots and interpretation of sequencing quality across selected samples.

### 2. Host filtering

- Removal of host-associated reads.
- Summary of reads removed versus retained.
- Interpretation of how host filtering affects downstream viromic analysis.

### 3. Taxonomic composition and viral relative abundance

- Viral read assignment and abundance table generation.
- Comparison of enriched versus unenriched libraries.
- Alpha diversity, beta diversity, and relative abundance visualizations.

### 4. SARS-CoV-2 SNVs

- Coverage and breadth assessment for SARS-CoV-2.
- Variant calling and filtering for interpretable SNV analysis.
- Time-resolved SNV summaries for samples with sufficient coverage.

## Data

The workflow operates on a curated set of 10 HTP libraries represented in `config/samples_htp.csv`. Raw FASTQ files for these libraries are downloaded from the SRA at runtime using the SRR accessions in that manifest. Large raw inputs and heavy intermediates (e.g. `data/raw/htp/`, `data/sra/`, and `data/tmp/`) are not tracked in Git, keeping the repository lightweight while preserving full reproducibility of sample selection and download.

## Reproducibility

The workflow is intended to be run with Snakemake and rule-specific software environments. The final report reads workflow outputs from the `results/` directory rather than recomputing raw preprocessing inline, which keeps the narrative report clean and reproducible. Snakemake’s modular workflow structure and per-rule environment support are designed for this style of reproducible analysis.

## Taxonomic classification and databases

Taxonomic classification of host-filtered metatranscriptomic reads is performed with
Kraken2 followed by Bracken for abundance estimation.

For this take-home, I used the **Kraken2 standard database** provided via the Genome
Index Zone:

- Source: https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20260226.tar.gz
- Contents: RefSeq archaea, bacteria, viruses, plasmids, human, UniVec_Core
- Local path (configured in `config/config.yaml`):
  - `paths.kraken_db`: /path/to/k2_standard_20260226
  - `paths.bracken_db`: /path/to/k2_standard_20260226
- Bracken read length: 150 bp (assuming 2×150 bp Illumina paired-end reads)

This choice provides a recent, prebuilt, widely used metagenomic reference suitable
for efficient taxonomic profiling of wastewater RNA virome data.

## Planned commands

### Dry run

```bash
snakemake -n
```

### Run the full workflow

```bash
snakemake --use-conda --cores 8
```

### Render the report only

```bash
Rscript -e "rmarkdown::render('analysis/wastewater_viromics_report.Rmd', output_file='wastewater_viromics_report.html', output_dir='results/report')"
```

## Notes for reviewers

This repository is organized so that each major analysis step produces inspectable outputs. The committed sample sheet provides a stable and reviewable record of the selected libraries, while the included helper scripts document exactly how that manifest was derived from SRA metadata. The R Markdown report then assembles workflow outputs into a stepwise narrative with implementation details, plots, and a biologically focused MCQ for each stage.