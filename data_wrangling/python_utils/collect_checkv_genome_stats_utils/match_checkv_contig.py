###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       match_checkv_contig.py
###############################################################################
"""Map exact and cut FASTA identifiers to CheckV identifiers."""


def match_checkv_contig(genome_id, checkv_contig_ids):
    """Return the unique longest exact or underscore-prefix CheckV match."""
    candidates = [
        contig_id
        for contig_id in checkv_contig_ids
        if genome_id == contig_id or genome_id.startswith(contig_id + "_")
    ]
    if not candidates:
        raise ValueError(f"no CheckV contig matches FASTA genome: {genome_id}")
    longest_length = max(len(candidate) for candidate in candidates)
    longest = [
        candidate for candidate in candidates
        if len(candidate) == longest_length
    ]
    if len(longest) != 1:
        raise ValueError(
            f"ambiguous longest CheckV contig match for FASTA genome: "
            f"{genome_id}"
        )
    return longest[0]
