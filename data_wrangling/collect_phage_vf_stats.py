###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           collect_phage_vf_stats.py
###############################################################################
# pattern: Imperative Shell

"""Collect threshold-consistent phage-level lifestyle and VFDB statistics.

The entrypoint gathers PhaTYP, Prokka, and combined HMMER inputs, delegates
validation and calculations to focused helpers, and writes the stats and QC
tables under the requested project's data directory.
"""

##### set up

import argparse
from pathlib import Path

from collect_phage_vf_stats.build_qc_rows import build_qc_rows
from collect_phage_vf_stats.constants import QC_COLUMNS, STATS_COLUMNS
from collect_phage_vf_stats.parse_sample_path import parse_sample_path
from collect_phage_vf_stats.qualify_vf_hits import qualify_vf_hits
from collect_phage_vf_stats.read_gff import read_gff
from collect_phage_vf_stats.read_phatyp import read_phatyp
from collect_phage_vf_stats.read_vf_hits import read_vf_hits
from collect_phage_vf_stats.summarize_phages import summarize_phages
from collect_phage_vf_stats.validate_joins import validate_joins
from collect_phage_vf_stats.write_csv import write_csv


##### main

def main():
    """Collect all inputs, validate their joins, and write both outputs."""
    parser = argparse.ArgumentParser(
        description="Collect phage-level lifestyle and VFDB statistics."
    )
    parser.add_argument("project_dir", type=Path)
    args = parser.parse_args()

    project_dir = args.project_dir.resolve()
    prediction_dir = project_dir / "phage_predictions"
    annotation_dir = project_dir / "genome_annotation"
    data_dir = project_dir / "data"
    vf_hits_path = data_dir / "all_vf_hits.csv"

    for input_dir in (prediction_dir, annotation_dir, data_dir):
        if not input_dir.is_dir():
            raise FileNotFoundError(f"missing required directory: {input_dir}")
    if not vf_hits_path.is_file():
        raise FileNotFoundError(
            "missing upstream all_vf_hits.csv; run "
            "data_wrangling/collect_all_vf_hits.sh first: "
            f"{vf_hits_path}"
        )

    phatyp_paths = sorted(
        prediction_dir.glob("*_prediction/out/phatyp_prediction.csv")
    )
    gff_paths = sorted(
        annotation_dir.glob("*_annotation_bac_on_phage/*.gff.gz")
    )
    if not phatyp_paths:
        raise FileNotFoundError(
            f"no PhaTYP prediction files found under {prediction_dir}"
        )
    if not gff_paths:
        raise FileNotFoundError(
            f"no Prokka GFF files found under {annotation_dir}"
        )

    phages = []
    phatyp_samples = set()
    for path in phatyp_paths:
        metadata = parse_sample_path(path, "prediction")
        if metadata["sample"] in phatyp_samples:
            raise ValueError(
                f"multiple PhaTYP files for sample: {metadata['sample']}"
            )
        phatyp_samples.add(metadata["sample"])
        phages.extend(read_phatyp(path, metadata))

    contigs = {}
    orfs = {}
    invalid_coordinates = []
    gff_samples = set()
    for path in gff_paths:
        metadata = parse_sample_path(path, "gff")
        if metadata["sample"] in gff_samples:
            raise ValueError(
                f"multiple GFF files for sample: {metadata['sample']}"
            )
        gff_samples.add(metadata["sample"])
        current_contigs, current_orfs, current_invalid = read_gff(
            path, metadata["sample"]
        )
        duplicate_contigs = set(contigs) & set(current_contigs)
        duplicate_orfs = set(orfs) & set(current_orfs)
        if duplicate_contigs or duplicate_orfs:
            raise ValueError("duplicate GFF keys across input files")
        contigs.update(current_contigs)
        orfs.update(current_orfs)
        invalid_coordinates.extend(current_invalid)

    if phatyp_samples != gff_samples:
        missing_gff = sorted(phatyp_samples - gff_samples)
        missing_phatyp = sorted(gff_samples - phatyp_samples)
        raise ValueError(
            "PhaTYP and GFF sample sets differ; missing GFF: "
            f"{missing_gff}; missing PhaTYP: {missing_phatyp}"
        )

    hits = qualify_vf_hits(read_vf_hits(vf_hits_path))
    validation_counts = validate_joins(
        phages, contigs, orfs, hits, invalid_coordinates
    )
    summaries = summarize_phages(phages, contigs, orfs, hits)
    qc_rows = build_qc_rows(
        len(phatyp_paths),
        len(gff_paths),
        phages,
        summaries,
        validation_counts,
    )

    write_csv(data_dir / "phage_vf_stats.csv", summaries, STATS_COLUMNS)
    write_csv(data_dir / "phage_vf_stats_qc.csv", qc_rows, QC_COLUMNS)


if __name__ == "__main__":
    main()
