###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       constants.py
###############################################################################


"""Shared collector schema and VFDB threshold constants."""

MAX_FULL_SEQ_EVALUE = 1e-10
MIN_FULL_SEQ_SCORE = 25.0
MIN_SCORE_TO_BIAS_RATIO = 10.0

VF_REQUIRED_COLUMNS = {
    "category",
    "origin",
    "sample_id",
    "target_name",
    "query_name",
    "full_seq_evalue",
    "full_seq_score",
    "full_seq_bias",
    "description",
}

STATS_COLUMNS = [
    "category",
    "origin",
    "sample_id",
    "sample",
    "contig_id",
    "lifestyle_raw",
    "lifestyle",
    "phatyp_score",
    "contig_length",
    "total_bacterial_orfs",
    "qualifying_vf_orfs",
    "vf_present",
    "vf_orf_prevalence",
    "vf_covered_bases",
    "vf_contig_coverage",
]

QC_COLUMNS = ["metric", "value", "details"]
