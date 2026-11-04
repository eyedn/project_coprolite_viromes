###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       summarize_phages.py
###############################################################################


"""Calculate per-phage ORF prevalence and interval-union coverage."""


def summarize_phages(phages, contigs, orfs, hits):
    """Return one threshold-consistent VFDB summary per PhaTYP contig."""
    orfs_by_contig = {}
    for (sample, orf_id), record in orfs.items():
        key = (sample, record["contig_id"])
        orfs_by_contig.setdefault(key, []).append((orf_id, record))

    summaries = []
    for phage in sorted(
            phages, key=lambda row: (row["sample"], row["contig_id"])):
        contig_key = (phage["sample"], phage["contig_id"])
        contig_orfs = orfs_by_contig.get(contig_key, [])
        qualifying_orfs = [
            (orf_id, record)
            for orf_id, record in contig_orfs
            if (phage["sample"], orf_id) in hits
        ]

        intervals = sorted(
            (record["start"], record["end"])
            for _, record in qualifying_orfs
        )
        merged_intervals = []
        for start, end in intervals:
            if not merged_intervals or start > merged_intervals[-1][1] + 1:
                merged_intervals.append([start, end])
            else:
                merged_intervals[-1][1] = max(merged_intervals[-1][1], end)
        covered_bases = sum(
            end - start + 1 for start, end in merged_intervals
        )

        contig_length = contigs[contig_key]
        total_orfs = len(contig_orfs)
        qualifying_count = len(qualifying_orfs)
        prevalence = qualifying_count / total_orfs \
            if total_orfs else float("nan")
        coverage = covered_bases / contig_length
        if prevalence > 1 or coverage > 1:
            raise ValueError(
                f"calculated statistic exceeds 1 for {phage['sample']} + "
                f"{phage['contig_id']}"
            )

        summaries.append({
            **phage,
            "contig_length": contig_length,
            "total_bacterial_orfs": total_orfs,
            "qualifying_vf_orfs": qualifying_count,
            "vf_present": int(qualifying_count > 0),
            "vf_orf_prevalence": prevalence,
            "vf_covered_bases": covered_bases,
            "vf_contig_coverage": coverage,
        })

    return summaries
