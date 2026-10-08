###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       read_vf_hits.py
###############################################################################
"""Read and validate the combined VFDB HMMER hit CSV."""

import csv

from .constants import VF_REQUIRED_COLUMNS


def read_vf_hits(path):
    """Return VFDB rows after validating the combined CSV schema."""
    with open(path, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        fieldnames = set(reader.fieldnames or [])
        missing_columns = sorted((VF_REQUIRED_COLUMNS | {"vfdb_version", "orf_pool"}) - fieldnames)
        if missing_columns:
            raise ValueError(
                "VFDB table missing required columns: "
                f"{', '.join(missing_columns)}"
            )
        return list(reader)
