###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       read_gff.py
###############################################################################
"""Read one gzip-compressed Prokka GFF file."""

import gzip

from .parse_gff_lines import parse_gff_lines


def read_gff(path, sample):
    """Read one GFF and return its contigs, CDS records, and coordinate QC."""
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        return parse_gff_lines(handle, sample)
