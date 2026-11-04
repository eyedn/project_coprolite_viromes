###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       export_checkv_viral_cds.py
###############################################################################


"""Export all conservative viral Prokka CDS without rerunning annotation."""
import argparse
import csv
import gzip
from pathlib import Path

from python_utils.export_checkv_viral_cds_utils.parse_viral_cds import (
    parse_viral_cds,
)


def main():
    """Read existing stage-4 products and publish the supplemental CSV."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_dir", type=Path)
    parser.add_argument("output_csv", type=Path)
    args = parser.parse_args()
    metadata_path = args.project_dir / "data/checkv_genome_metadata.csv"
    gff_path = (args.project_dir / "checkv_genomes/conservative"
                / "annotations/viral/checkv_conservative.gff")
    if not gff_path.is_file():
        gff_path = Path(str(gff_path) + ".gz")
    open_gff = gzip.open if gff_path.suffix == ".gz" else open
    with metadata_path.open(newline="", encoding="utf-8") as handle:
        metadata = list(csv.DictReader(handle))
    with open_gff(gff_path, "rt", encoding="utf-8") as handle:
        features = parse_viral_cds(handle, metadata)

    # validate the entire input before opening the destination for replacement.
    with args.output_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=[
            "checkv_filter", "genome_id", "feature_id", "start", "end",
            "strand", "product", "ec_number",
        ])
        writer.writeheader()
        writer.writerows(features)
    print(f"Exported {len(features)} conservative viral CDS: {args.output_csv}")


if __name__ == "__main__":
    main()
