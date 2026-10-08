###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       join_bacterial_orfs.py
###############################################################################
"""Require a bijection between bacterial FAA proteins and GFF CDS IDs."""


def join_bacterial_orfs(orfs, protein_ids, sample):
    features = {key[1]: row for key, row in orfs.items() if key[0] == sample}
    if set(features) != set(protein_ids):
        raise ValueError(
            "FAA/GFF identifiers differ; unmatched proteins: "
            f"{sorted(set(protein_ids) - set(features))}; unmatched CDS: "
            f"{sorted(set(features) - set(protein_ids))}"
        )
    return [
        {"orf_id": orf_id, "feature_id": orf_id, **features[orf_id]}
        for orf_id in sorted(features)
    ]
