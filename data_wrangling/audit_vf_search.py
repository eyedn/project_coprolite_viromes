###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       audit_vf_search.py
###############################################################################


"""Validate the complete full-pool search products for one sample."""
import argparse
from pathlib import Path
from python_utils.read_bacterial_orfs import read_bacterial_orfs
from python_utils.validate_vf_search import validate_vf_search
from python_utils.vfdb_constants import VFDB_DATABASES


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("gff", type=Path)
    parser.add_argument("faa", type=Path)
    parser.add_argument("directory", type=Path)
    parser.add_argument("version", choices=VFDB_DATABASES)
    args = parser.parse_args()
    _, _, rows = read_bacterial_orfs(args.gff, args.faa, "audit")
    validate_vf_search(args.directory, args.version, args.faa,
                       {row["orf_id"] for row in rows})


if __name__ == "__main__":
    main()
