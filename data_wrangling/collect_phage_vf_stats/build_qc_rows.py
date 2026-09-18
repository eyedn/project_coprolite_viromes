###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           build_qc_rows.py
###############################################################################
# pattern: Functional Core

"""Build a stable long-form QC report for a successful collection run."""

from collections import Counter


def build_qc_rows(
        phatyp_file_count, gff_file_count, phages, summaries,
        validation_counts):
    """Return file, lifestyle, zero-denominator, and join QC metrics."""
    metrics = [
        ("phatyp_files", phatyp_file_count, ""),
        ("gff_files", gff_file_count, ""),
        ("vf_hit_files", 1, ""),
        ("phage_rows", len(summaries), ""),
        (
            "zero_orf_phages",
            sum(row["total_bacterial_orfs"] == 0 for row in summaries),
            "",
        ),
        (
            "zero_hit_phages",
            sum(row["qualifying_vf_orfs"] == 0 for row in summaries),
            "",
        ),
    ]
    lifestyle_counts = Counter(row["lifestyle"] for row in phages)
    metrics.extend(
        ("lifestyle_count", count, lifestyle)
        for lifestyle, count in sorted(lifestyle_counts.items())
    )
    metrics.extend(
        (metric, value, "")
        for metric, value in validation_counts.items()
    )
    return [
        {"metric": metric, "value": value, "details": details}
        for metric, value, details in metrics
    ]
