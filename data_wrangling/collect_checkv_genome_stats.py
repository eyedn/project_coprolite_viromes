###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_checkv_genome_stats.py
###############################################################################
"""Validate and aggregate complete CheckV-genome pipeline products."""

##### set up

import argparse
import csv
import gzip
import json
import sys
from pathlib import Path

from python_utils.collect_checkv_genome_stats_utils import (
    build_sample_index,
    match_checkv_contig,
    parse_checkv_lines,
    parse_fasta_lines,
    parse_genome_metadata,
    parse_phagcn_rows,
    parse_phatyp_rows,
    select_best_vf_hits,
    validate_checkv_source,
)
from python_utils.collect_checkv_genome_stats_utils.constants import (
    CHECKV_FILTERS,
    FEATURE_COLUMNS,
    METADATA_COLUMNS,
    QC_COLUMNS,
    VF_HIT_COLUMNS,
    VF_STATS_COLUMNS,
)


from python_utils.read_bacterial_orfs import read_bacterial_orfs
from python_utils.validate_vf_search import validate_vf_search
from python_utils.summarize_orf_groups import summarize_orf_groups
from python_utils.make_orf_inventory import make_orf_inventory
from python_utils.vfdb_constants import (
    GROUP_COLUMNS, ORF_COLUMNS, ORF_POOL, POOL_COLUMNS, VFDB_DATABASES,
)

##### main

def main():
    """Gather both filter outputs, enforce joins, and publish six version-specific CSVs."""
    parser = argparse.ArgumentParser()
    parser.add_argument("project_dir", type=Path)
    parser.add_argument("--vfdb-version", choices=VFDB_DATABASES,
                        required=True)
    args = parser.parse_args()
    suffix = "_VFDB_setA" if args.vfdb_version == "VFDB_setA" else ""
    project_dir = args.project_dir.resolve()
    data_dir = project_dir / "data"
    if not data_dir.is_dir():
        raise FileNotFoundError(f"missing data directory: {data_dir}")

    manifest_samples = {}
    manifest_paths = sorted(
        (project_dir / "samples").glob("*_samples.txt")
    )
    for manifest_path in manifest_paths:
        manifest_name = manifest_path.name[:-len("_samples.txt")]
        if manifest_name.endswith("-source") or manifest_name == "soil":
            continue
        samples = []
        with manifest_path.open(encoding="utf-8") as handle:
            for line in handle:
                if line.strip():
                    samples.append(line.split()[0])
        manifest_samples[manifest_name] = samples
    sample_index = build_sample_index(manifest_samples)

    all_orfs = []
    all_metadata = []
    all_features = []
    all_hits = []
    all_stats = []
    all_qc = []

    for checkv_filter in CHECKV_FILTERS:
        input_dir = project_dir / "checkv_input" / checkv_filter
        output_dir = project_dir / "checkv_genomes" / checkv_filter
        prediction_candidates = {
            "PhaTYP": (
                output_dir / "predictions/out/phatyp_prediction.csv",
                output_dir / "final_prediction/phatyp_prediction.tsv",
            ),
            "PhaGCN": (
                output_dir / "predictions/out/phagcn_prediction.csv",
                output_dir / "final_prediction/phagcn_prediction.tsv",
            ),
        }
        prediction_paths = {}
        for label, candidates in prediction_candidates.items():
            existing = [path for path in candidates if path.is_file()]
            if not existing:
                raise FileNotFoundError(
                    f"missing {checkv_filter} {label}: "
                    + " or ".join(str(path) for path in candidates)
                )
            if len(existing) > 1:
                raise ValueError(
                    f"duplicate {checkv_filter} {label} output files: "
                    + ", ".join(str(path) for path in existing)
                )
            prediction_paths[label] = existing[0]
        required_paths = {
            "FASTA": input_dir / "genomes.fa.gz",
            "CheckV summary": input_dir / "quality_summary.tsv",
            "complete-contig list": input_dir / "complete_contigs.txt",
            "PhaTYP": prediction_paths["PhaTYP"],
            "PhaGCN": prediction_paths["PhaGCN"],
            "bacterial features": (
                output_dir / "annotations/bacterial/valid_features.csv"
            ),
            "viral features": (
                output_dir / "annotations/viral/valid_features.csv"
            ),
            "VFDB alignment": (output_dir / "vf_alignment_all_orfs" /
                               args.vfdb_version / "table.txt"),
        }
        for label, path in required_paths.items():
            if not path.is_file():
                raise FileNotFoundError(
                    f"missing {checkv_filter} {label}: {path}"
                )

        with gzip.open(required_paths["FASTA"], "rt") as handle:
            genome_lengths = parse_fasta_lines(handle)
        genome_ids = set(genome_lengths)

        with required_paths["CheckV summary"].open(encoding="utf-8") as handle:
            checkv_rows = parse_checkv_lines(handle)
        checkv_by_id = {row["contig_id"].strip(): row for row in checkv_rows}

        complete_ids = set()
        with required_paths["complete-contig list"].open(
                encoding="utf-8") as handle:
            for line in handle:
                if line.strip():
                    complete_ids.add(line.split()[0].lstrip(">"))
        with required_paths["PhaTYP"].open(
                newline="", encoding="utf-8") as handle:
            first_line = handle.readline()
            handle.seek(0)
            delimiter = "\t" if "\t" in first_line else ","
            reader = csv.DictReader(handle, delimiter=delimiter)
            phatyp = parse_phatyp_rows(reader, reader.fieldnames)
        if set(phatyp) != genome_ids:
            raise ValueError(
                "PhaTYP identifiers differ from FASTA identifiers; missing: "
                f"{sorted(genome_ids - set(phatyp))}; extra: "
                f"{sorted(set(phatyp) - genome_ids)}"
            )

        with required_paths["PhaGCN"].open(
                newline="", encoding="utf-8") as handle:
            first_line = handle.readline()
            handle.seek(0)
            delimiter = "\t" if "\t" in first_line else ","
            reader = csv.DictReader(handle, delimiter=delimiter)
            phagcn = parse_phagcn_rows(reader, reader.fieldnames)
        if set(phagcn) != genome_ids:
            raise ValueError(
                "PhaGCN identifiers differ from FASTA identifiers; missing: "
                f"{sorted(genome_ids - set(phagcn))}; extra: "
                f"{sorted(set(phagcn) - genome_ids)}"
            )

        features_by_annotation = {}
        for annotation, label in (
            ("bacterial", "bacterial features"),
            ("viral", "viral features"),
        ):
            with required_paths[label].open(
                    newline="", encoding="utf-8") as handle:
                reader = csv.DictReader(handle)
                fieldnames = set(reader.fieldnames or [])
                rows = list(reader)
            required_columns = {
                "genome_id",
                "feature_id",
                "start",
                "end",
                "strand",
                "product",
                "ec_number",
            }
            if not required_columns.issubset(fieldnames):
                raise ValueError(
                    f"{annotation} feature table has invalid schema"
                )
            seen = set()
            for row in rows:
                feature_id = row["feature_id"].strip()
                genome_id = row["genome_id"].strip()
                product = row["product"].strip()
                ec_number = row["ec_number"].strip()
                if not feature_id:
                    raise ValueError(
                        f"empty {annotation} Prokka feature identifier"
                    )
                if genome_id not in genome_ids:
                    raise ValueError(
                        f"{annotation} feature has unknown genome: {genome_id}"
                    )
                is_hypothetical = (
                    "hypothetical protein" in product.casefold()
                )
                if not ec_number or is_hypothetical:
                    raise ValueError(
                        f"ineligible feature in filtered {annotation} table: "
                        f"{feature_id}"
                    )
                if feature_id in seen:
                    raise ValueError(
                        f"duplicate Prokka feature identifier: {feature_id}"
                    )
                seen.add(feature_id)
            features_by_annotation[annotation] = rows

        bacterial_dir = output_dir / "annotations/bacterial"
        prefix = f"checkv_{checkv_filter}"
        bacterial_contigs, _, bacterial_orfs = read_bacterial_orfs(
            bacterial_dir / f"{prefix}.gff",
            bacterial_dir / f"{prefix}.faa", "checkv",
        )
        if {key[1]: length for key, length in bacterial_contigs.items()} != (
                genome_lengths):
            raise ValueError("bacterial GFF contigs differ from genome FASTA")
        bacterial_by_id = {row["feature_id"]: {
            **row, "genome_id": row["contig_id"]
        } for row in bacterial_orfs}
        expected_filtered = {
            key for key, row in bacterial_by_id.items()
            if row["has_ec_number"] and not row["is_hypothetical"]
        }
        filtered = features_by_annotation["bacterial"]
        if {row["feature_id"] for row in filtered} != expected_filtered:
            raise ValueError("filtered bacterial map features differ from GFF")
        for row in filtered:
            feature = bacterial_by_id[row["feature_id"]]
            for field in ("genome_id", "start", "end", "strand",
                          "product", "ec_number"):
                if str(row[field]) != str(feature[field]):
                    raise ValueError("filtered bacterial map feature mismatch")
        raw_hits = validate_vf_search(
            required_paths["VFDB alignment"].parent, args.vfdb_version,
            bacterial_dir / f"{prefix}.faa", set(bacterial_by_id),
        )
        best_hits = select_best_vf_hits(raw_hits, set(bacterial_by_id))
        hits_by_id = {row["target_name"]: row for row in best_hits}

        genome_context = {}
        used_checkv_contigs = set()
        for genome_id, genome_length in genome_lengths.items():
            checkv_contig_id = match_checkv_contig(
                genome_id,
                list(checkv_by_id),
            )
            if (
                    genome_id not in complete_ids
                    and checkv_contig_id not in complete_ids):
                raise ValueError(
                    "complete FASTA genome is absent from "
                    f"complete_contigs.txt: {genome_id}"
                )
            sample_metadata = parse_genome_metadata(genome_id, sample_index)
            checkv_row = checkv_by_id[checkv_contig_id]
            used_checkv_contigs.add(checkv_contig_id)
            validate_checkv_source(
                checkv_row["Source"],
                sample_metadata["category"],
            )
            context = {
                "checkv_filter": checkv_filter,
                "vfdb_version": args.vfdb_version,
                "orf_pool": ORF_POOL,
                "genome_id": genome_id,
                "checkv_contig_id": checkv_contig_id,
                **sample_metadata,
            }
            genome_context[genome_id] = context
            taxonomy = phagcn[genome_id]
            all_metadata.append({
                **context,
                "genome_length": genome_length,
                "checkv_lifestyle": checkv_row["Lifestyle"].strip(),
                "checkv_source": checkv_row["Source"].strip(),
                "checkv_warnings": checkv_row["warnings"].strip(),
                "phatyp_lifestyle_raw": phatyp[genome_id]["lifestyle_raw"],
                "phatyp_lifestyle": phatyp[genome_id]["lifestyle"],
                "phatyp_score": phatyp[genome_id]["score"],
                "phagcn_lineage": taxonomy["lineage"],
                "phagcn_family": taxonomy["family"],
                "phagcn_family_score": taxonomy["family_score"],
                "phagcn_genus": taxonomy["genus"],
                "phagcn_genus_cluster": taxonomy["genus_cluster"],
                "checkv_raw_json": json.dumps(checkv_row, sort_keys=True),
                "phagcn_raw_json": taxonomy["raw_json"],
            })

        unmatched_checkv = sorted(set(checkv_by_id) - used_checkv_contigs)
        if unmatched_checkv:
            print(
                "QC-excluded CheckV records with no FASTA genome match: "
                + ", ".join(unmatched_checkv),
                file=sys.stderr,
            )

        for annotation, rows in features_by_annotation.items():
            for row in rows:
                all_features.append({
                    **genome_context[row["genome_id"]],
                    "annotation": annotation,
                    **row,
                    "vf_id": "",
                    "full_seq_evalue": "",
                    "full_seq_score": "",
                    "full_seq_bias": "",
                    "vf_description": "",
                })

        for hit in best_hits:
            feature = bacterial_by_id[hit["target_name"]]
            vf_row = {
                **genome_context[feature["genome_id"]],
                "annotation": "vf",
                **feature,
                "vf_id": hit["query_name"],
                "full_seq_evalue": hit["full_seq_evalue"],
                "full_seq_score": hit["full_seq_score"],
                "full_seq_bias": hit["full_seq_bias"],
                "vf_description": hit["description"],
            }
            all_hits.append(vf_row)
            all_features.append(vf_row)

        bacterial_by_genome = {genome_id: [] for genome_id in genome_ids}
        for feature in bacterial_by_id.values():
            bacterial_by_genome[feature["genome_id"]].append(feature)
        for genome_id in genome_lengths:
            rows = bacterial_by_genome[genome_id]
            all_orfs.extend(make_orf_inventory(
                rows, hits_by_id, genome_context[genome_id]
            ))
            all_stats.append({
                **genome_context[genome_id],
                **summarize_orf_groups(rows, set(hits_by_id)),
            })

        qc_values = {
            "fasta_genomes": len(genome_ids),
            "checkv_records": len(checkv_rows),
            "unmatched_checkv_records": len(unmatched_checkv),
            "phatyp_records": len(phatyp),
            "phagcn_records": len(phagcn),
            "total_bacterial_orfs": len(bacterial_by_id),
            "eligible_viral_features": len(features_by_annotation["viral"]),
            "qualifying_vf_hits": len(best_hits),
        }
        all_qc.extend(
            {
                "checkv_filter": checkv_filter,
                "vfdb_version": args.vfdb_version,
                "orf_pool": ORF_POOL,
                "metric": metric,
                "value": value,
                "details": (
                    ", ".join(unmatched_checkv)
                    if metric == "unmatched_checkv_records"
                    else ""
                ),
            }
            for metric, value in qc_values.items()
        )

    outputs = (
        ("checkv_genome_orfs.csv", all_orfs,
         [*METADATA_COLUMNS[:6], "contig_id", *ORF_COLUMNS]),
        ("checkv_genome_metadata.csv", all_metadata, METADATA_COLUMNS),
        ("checkv_genome_features.csv", all_features, FEATURE_COLUMNS),
        ("checkv_genome_vf_hits.csv", all_hits, VF_HIT_COLUMNS),
        ("checkv_genome_vf_stats.csv", all_stats, VF_STATS_COLUMNS),
        ("checkv_genome_qc.csv", all_qc, QC_COLUMNS),
    )
    for filename, rows, fieldnames in outputs:
        filename = filename[:-4] + suffix + ".csv"
        fieldnames = list(dict.fromkeys([*fieldnames, *POOL_COLUMNS]))
        if "vf_stats" in filename:
            fieldnames += GROUP_COLUMNS
        output_path = data_dir / filename
        temporary_path = data_dir / ("." + filename + ".tmp")
        with temporary_path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=fieldnames,
                extrasaction="ignore",
            )
            writer.writeheader()
            writer.writerows(rows)
        temporary_path.replace(output_path)


if __name__ == "__main__":
    main()
