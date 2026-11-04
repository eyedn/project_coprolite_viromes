###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       aggregate_sample_coverage.py
###############################################################################


"""Pool per-phage covered and total bases into sample-level coverage."""


def aggregate_sample_coverage(rows):
    """Aggregate sample coverage from summed bases, never mean proportions."""
    totals = {}
    for row in rows:
        sample = row["sample"]
        totals.setdefault(sample, {"covered": 0, "length": 0})
        totals[sample]["covered"] += int(row["vf_covered_bases"])
        totals[sample]["length"] += int(row["contig_length"])

    aggregated = []
    for sample in sorted(totals):
        covered = totals[sample]["covered"]
        length = totals[sample]["length"]
        aggregated.append({
            "sample": sample,
            "sample_vf_covered_bases": covered,
            "sample_phage_bases": length,
            "sample_vf_contig_coverage": covered / length,
        })
    return aggregated
