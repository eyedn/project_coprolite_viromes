###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       pool_sample_vf_stats.py
###############################################################################
"""Pool contig counts and interval-union bases within each sample."""
from .vfdb_constants import GROUP_COLUMNS


def pool_sample_vf_stats(rows):
    totals = {}
    count_columns = [
        "total_bacterial_orfs", "qualifying_vf_orfs", "contig_length",
        "vf_covered_bases", *GROUP_COLUMNS,
    ]
    for row in rows:
        sample = row["sample"]
        if sample not in totals:
            totals[sample] = {
                key: row[key] for key in (
                    "sample", "category", "origin", "sample_id",
                    "vfdb_version", "orf_pool",
                )
            }
            totals[sample].update({key: 0 for key in count_columns})
        for key in count_columns:
            totals[sample][key] += row[key]
    for row in totals.values():
        total = row["total_bacterial_orfs"]
        row["vf_orf_prevalence"] = (
            row["qualifying_vf_orfs"] / total if total else None
        )
        row["vf_present"] = int(row["qualifying_vf_orfs"] > 0)
        row["vf_contig_coverage"] = (
            row["vf_covered_bases"] / row["contig_length"]
        )
    return [totals[key] for key in sorted(totals)]
