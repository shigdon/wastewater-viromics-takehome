import pandas as pd

SAMPLESHEET = "config/samples_htp.csv"
SAMPLE_DF = pd.read_csv(SAMPLESHEET)
SAMPLES = SAMPLE_DF["sample_id"].tolist()

SAMPLE_TO_SRR = dict(zip(SAMPLE_DF["sample_id"], SAMPLE_DF["srr"]))

def get_srr(wildcards):
    return SAMPLE_TO_SRR[wildcards.sample]