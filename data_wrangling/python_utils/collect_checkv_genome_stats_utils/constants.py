###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       constants.py
###############################################################################


"""Schemas and scientific thresholds for CheckV-genome collection."""

CHECKV_FILTERS = ("conservative", "aggressive")
MAX_FULL_SEQ_EVALUE = 1e-10
MIN_FULL_SEQ_SCORE = 25.0
MIN_SCORE_TO_BIAS_RATIO = 10.0

FEATURE_COLUMNS = [
    "checkv_filter",
    "genome_id",
    "checkv_contig_id",
    "category",
    "origin",
    "sample",
    "annotation",
    "feature_id",
    "start",
    "end",
    "strand",
    "product",
    "ec_number",
    "vf_id",
    "full_seq_evalue",
    "full_seq_score",
    "full_seq_bias",
    "vf_description",
]

VF_HIT_COLUMNS = FEATURE_COLUMNS

VF_STATS_COLUMNS = [
    "checkv_filter",
    "genome_id",
    "checkv_contig_id",
    "category",
    "origin",
    "sample",
    "total_bacterial_orfs",
    "qualifying_vf_orfs",
    "vf_present",
    "vf_orf_prevalence",
]

METADATA_COLUMNS = [
    "checkv_filter",
    "genome_id",
    "checkv_contig_id",
    "category",
    "origin",
    "sample",
    "genome_length",
    "checkv_lifestyle",
    "checkv_source",
    "checkv_warnings",
    "phatyp_lifestyle_raw",
    "phatyp_lifestyle",
    "phatyp_score",
    "phagcn_lineage",
    "phagcn_family",
    "phagcn_family_score",
    "phagcn_genus",
    "phagcn_genus_cluster",
    "checkv_raw_json",
    "phagcn_raw_json",
]

QC_COLUMNS = ["checkv_filter", "metric", "value", "details"]
