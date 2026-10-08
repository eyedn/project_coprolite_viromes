###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_phage_vf_stats.py
###############################################################################
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
from collect_phage_vf_stats.read_phatyp import read_phatyp
from collect_phage_vf_stats.read_vf_hits import read_vf_hits
from collect_phage_vf_stats.summarize_phages import summarize_phages
from collect_phage_vf_stats.validate_joins import validate_joins
from collect_phage_vf_stats.write_csv import write_csv


from python_utils.validate_vf_search import validate_vf_search
from python_utils.read_bacterial_orfs import read_bacterial_orfs
from python_utils.summarize_orf_groups import summarize_orf_groups
from python_utils.make_orf_inventory import make_orf_inventory
from python_utils.pool_sample_vf_stats import pool_sample_vf_stats
from python_utils.vfdb_constants import (
    GROUP_COLUMNS, ORF_COLUMNS, ORF_POOL, POOL_COLUMNS, VFDB_DATABASES,
)

##### main

def main():
    """Collect all inputs, validate their joins, and write both outputs."""
    parser = argparse.ArgumentParser(
        description="Collect phage-level lifestyle and VFDB statistics."
    )
    parser.add_argument("project_dir", type=Path)
    parser.add_argument("--vf-hits-file", type=Path)
    parser.add_argument("--stats-output", type=Path)
    parser.add_argument("--qc-output", type=Path)
    parser.add_argument("--complete-samples-file", type=Path)
    parser.add_argument("--vfdb-version", choices=VFDB_DATABASES,
                        required=True)
    parser.add_argument("--orfs-output", type=Path)
    parser.add_argument("--sample-stats-output", type=Path)
    args = parser.parse_args()
    suffix = "_VFDB_setA" if args.vfdb_version == "VFDB_setA" else ""

    project_dir = args.project_dir.resolve()
    prediction_dir = project_dir / "phage_predictions"
    annotation_dir = project_dir / "genome_annotation"
    data_dir = project_dir / "data"
    vf_hits_path = args.vf_hits_file or data_dir / f"all_vf_hits{suffix}.csv"
    stats_output = args.stats_output or data_dir / f"phage_vf_stats{suffix}.csv"
    qc_output = args.qc_output or data_dir / f"phage_vf_stats_qc{suffix}.csv"

    complete_samples = None
    if args.complete_samples_file is not None:
        with args.complete_samples_file.open() as handle:
            complete_samples = {
                line.strip()
                for line in handle
                if line.strip()
            }
        if not complete_samples:
            raise ValueError("complete-samples file contains no samples")

    for input_dir in (prediction_dir, annotation_dir, data_dir):
        if not input_dir.is_dir():
            raise FileNotFoundError(f"missing required directory: {input_dir}")
    if not vf_hits_path.is_file():
        raise FileNotFoundError(
            "missing upstream all_vf_hits.csv; run "
            "data_wrangling/collect_all_vf_hits.sh first: "
            f"{vf_hits_path}"
        )
    for output_path in (stats_output, qc_output):
        if not output_path.parent.is_dir():
            raise FileNotFoundError(
                f"missing output directory: {output_path.parent}"
            )

    phatyp_paths = sorted(
        prediction_dir.glob("*_prediction/out/phatyp_prediction.csv")
    )
    gff_paths = sorted(
        annotation_dir.glob("*_annotation_bac_on_phage/*.gff*")
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
        sample_label = (
            f"{metadata['category']}-{metadata['origin']}_"
            f"{metadata['sample_id']}"
        )
        if (
            complete_samples is not None
            and sample_label not in complete_samples
        ):
            continue
        if metadata["sample"] in phatyp_samples:
            raise ValueError(
                f"multiple PhaTYP files for sample: {metadata['sample']}"
            )
        phatyp_samples.add(metadata["sample"])
        phages.extend(read_phatyp(path, metadata))

    sample_metadata = {}
    inventory_by_sample = {}
    contigs = {}
    orfs = {}
    invalid_coordinates = []
    gff_samples = set()
    for path in gff_paths:
        metadata = parse_sample_path(path, "gff")
        sample_label = (
            f"{metadata['category']}-{metadata['origin']}_"
            f"{metadata['sample_id']}"
        )
        if (
            complete_samples is not None
            and sample_label not in complete_samples
        ):
            continue
        if metadata["sample"] in gff_samples:
            raise ValueError(
                f"multiple GFF files for sample: {metadata['sample']}"
            )
        gff_samples.add(metadata["sample"])
        faa_path = path.parent / (metadata["sample_id"] + ".faa")
        current_contigs, current_orfs, current_rows = read_bacterial_orfs(
            path, faa_path, metadata["sample"]
        )
        validate_vf_search(
            project_dir / "alignment/vfdb_all_orfs" / args.vfdb_version /
            (sample_label + "_vf"), args.vfdb_version, faa_path,
            {row["orf_id"] for row in current_rows},
        )
        current_invalid = []
        sample_metadata[metadata["sample"]] = metadata
        inventory_by_sample[metadata["sample"]] = current_rows
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

    raw_hits = read_vf_hits(vf_hits_path)
    for row in raw_hits:
        if (row["vfdb_version"] != args.vfdb_version
                or row["orf_pool"] != ORF_POOL):
            raise ValueError("incompatible combined VFDB hit table")
        key = (f"{row['category']}.{row['origin']}_{row['sample_id']}",
               row["target_name"])
        if key not in orfs:
            raise ValueError(f"unknown HMMER target: {key}")
    hits = qualify_vf_hits(raw_hits)
    validation_counts = validate_joins(
        phages, contigs, orfs, hits, invalid_coordinates
    )
    summaries = summarize_phages(phages, contigs, orfs, hits)
    inventory = []
    for sample, metadata in sample_metadata.items():
        context = {**metadata, "vfdb_version": args.vfdb_version,
                   "orf_pool": ORF_POOL}
        sample_rows = inventory_by_sample[sample]
        sample_hits = {key[1]: hit for key, hit in hits.items()
                       if key[0] == sample}
        inventory.extend(make_orf_inventory(sample_rows, sample_hits, context))
    inventory_by_contig = {}
    for record in inventory:
        key = (record["sample"], record["contig_id"])
        inventory_by_contig.setdefault(key, []).append(record)
    for row in summaries:
        row.update(vfdb_version=args.vfdb_version, orf_pool=ORF_POOL)
        contig_rows = inventory_by_contig.get(
            (row["sample"], row["contig_id"]), []
        )
        row.update(summarize_orf_groups(
            contig_rows, {record["feature_id"] for record in contig_rows
                          if record["vf_id"]}
        ))
    sample_stats = pool_sample_vf_stats(summaries)
    qc_rows = build_qc_rows(
        len(phatyp_samples),
        len(gff_samples),
        phages,
        summaries,
        validation_counts,
    )

    write_csv(stats_output, summaries,
              STATS_COLUMNS + GROUP_COLUMNS + POOL_COLUMNS)
    write_csv(args.orfs_output or data_dir / f"phage_vf_orfs{suffix}.csv",
              inventory, ["sample", "category", "origin", "sample_id",
                          "contig_id", *ORF_COLUMNS, *POOL_COLUMNS])
    write_csv(args.sample_stats_output or
              data_dir / f"sample_vf_stats{suffix}.csv", sample_stats,
              [column for column in STATS_COLUMNS if column not in {
                  "contig_id", "lifestyle_raw", "lifestyle", "phatyp_score"
              }] + GROUP_COLUMNS + POOL_COLUMNS)
    for row in qc_rows:
        row.update(vfdb_version=args.vfdb_version, orf_pool=ORF_POOL)
    write_csv(qc_output, qc_rows, QC_COLUMNS + POOL_COLUMNS)


if __name__ == "__main__":
    main()
