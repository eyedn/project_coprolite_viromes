###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       validate_joins.py
###############################################################################
"""Validate collector keys before any phage rows are summarized."""

from collections import Counter


def validate_joins(phages, contigs, orfs, hits, invalid_coordinates):
    """Reject duplicate, invalid, or unmatched cross-file identifiers."""
    phage_keys = [
        (row["sample"], row["contig_id"])
        for row in phages
    ]
    duplicate_phage_keys = sorted(
        key for key, count in Counter(phage_keys).items() if count > 1
    )
    unmatched_phatyp_contigs = sorted(set(phage_keys) - set(contigs))
    if set(contigs) - set(phage_keys):
        raise ValueError("GFF contigs missing from PhaTYP predictions")
    unmatched_vf_orfs = sorted(set(hits) - set(orfs))

    if duplicate_phage_keys:
        duplicate_details = ", ".join(
            f"{sample} + {contig}"
            for sample, contig in duplicate_phage_keys
        )
        raise ValueError("duplicate phage keys: " + duplicate_details)
    if invalid_coordinates:
        raise ValueError(
            "invalid GFF coordinates: " + ", ".join(invalid_coordinates)
        )
    if unmatched_phatyp_contigs:
        phatyp_details = ", ".join(
            f"{sample} + {contig}"
            for sample, contig in unmatched_phatyp_contigs
        )
        raise ValueError("unmatched PhaTYP contigs: " + phatyp_details)
    if unmatched_vf_orfs:
        vf_details = ", ".join(
            f"{sample} + {orf}"
            for sample, orf in unmatched_vf_orfs
        )
        raise ValueError("unmatched VF ORFs: " + vf_details)

    return {
        "duplicate_phage_keys": len(duplicate_phage_keys),
        "invalid_coordinates": len(invalid_coordinates),
        "unmatched_phatyp_contigs": len(unmatched_phatyp_contigs),
        "unmatched_vf_orfs": len(unmatched_vf_orfs),
    }
