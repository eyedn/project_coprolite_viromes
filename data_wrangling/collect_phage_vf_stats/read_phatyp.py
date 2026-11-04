###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       read_phatyp.py
###############################################################################


"""Read one PhaTYP CSV file and pass its rows to the parser."""

import csv

from .parse_phatyp_rows import parse_phatyp_rows


def read_phatyp(path, metadata):
    """Read and normalize one PhaTYP prediction table."""
    with open(path, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        return parse_phatyp_rows(
            list(reader),
            reader.fieldnames,
            metadata["sample"],
            metadata["category"],
            metadata["origin"],
            metadata["sample_id"],
        )
