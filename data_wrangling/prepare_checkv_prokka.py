###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       prepare_checkv_prokka.py
###############################################################################
"""Filter Prokka features and optionally extract their protein sequences."""

##### set up

import argparse
import csv
import gzip
from pathlib import Path

from python_utils.prepare_checkv_prokka_utils import (
    extract_fasta_records,
    parse_valid_gff_features,
)


##### main

def main():
    """Read raw Prokka output and persist its eligible feature subset."""
    parser = argparse.ArgumentParser()
    parser.add_argument("gff_path", type=Path)
    parser.add_argument("features_output", type=Path)
    parser.add_argument("--faa-path", type=Path)
    parser.add_argument("--faa-output", type=Path)
    args = parser.parse_args()

    open_gff = gzip.open if args.gff_path.suffix == ".gz" else open
    with open_gff(args.gff_path, "rt", encoding="utf-8") as handle:
        features = parse_valid_gff_features(handle)

    fieldnames = [
        "genome_id",
        "feature_id",
        "start",
        "end",
        "strand",
        "product",
        "ec_number",
    ]
    with args.features_output.open(
            "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(features)

    if bool(args.faa_path) != bool(args.faa_output):
        parser.error("--faa-path and --faa-output must be provided together")
    if args.faa_path:
        open_faa = gzip.open if args.faa_path.suffix == ".gz" else open
        with open_faa(args.faa_path, "rt", encoding="utf-8") as handle:
            fasta_text = extract_fasta_records(
                handle,
                {feature["feature_id"] for feature in features},
            )
        args.faa_output.write_text(fasta_text, encoding="utf-8")


if __name__ == "__main__":
    main()
