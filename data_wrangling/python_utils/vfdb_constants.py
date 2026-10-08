###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       vfdb_constants.py
###############################################################################


"""Shared full-pool output contract."""
ORF_POOL = "all_bacterial_prokka_cds"
VFDB_DATABASES = {
    "VFDB_setA": "VFDB_setA_pro_20230917.txt",
    "VFDB_setB": "VFDB_setB_pro_20260923.txt",
}
GROUP_COLUMNS = [
    "hypothetical_orfs", "qualifying_hypothetical_orfs",
    "ec_labeled_orfs", "qualifying_ec_labeled_orfs",
    "hypothetical_ec_orfs", "qualifying_hypothetical_ec_orfs",
]
POOL_COLUMNS = ["vfdb_version", "orf_pool"]
ORF_COLUMNS = [
    "orf_id", "feature_id", "start", "end", "strand", "product",
    "ec_number", "is_hypothetical", "has_ec_number", "vf_id",
    "full_seq_evalue", "full_seq_score", "full_seq_bias", "vf_description",
]
