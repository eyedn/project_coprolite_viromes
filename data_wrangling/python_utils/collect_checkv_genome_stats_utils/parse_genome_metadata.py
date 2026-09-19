###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_genome_metadata.py
###############################################################################
"""Resolve a genome identifier through repository sample manifests."""


def parse_genome_metadata(genome_id, sample_index):
    """Return metadata for the unique longest sample-prefix match."""
    candidates = [
        (sample, metadata)
        for sample, metadata in sample_index.items()
        if genome_id.startswith(
            f"{metadata['category']}-{metadata['origin']}_{sample}_"
        )
    ]
    if not candidates:
        raise ValueError(
            f"genome identifier does not match a sample manifest: {genome_id}"
        )
    longest_length = max(len(sample) for sample, _ in candidates)
    longest = [
        metadata for sample, metadata in candidates
        if len(sample) == longest_length
    ]
    if len(longest) != 1:
        raise ValueError(f"ambiguous sample manifest match: {genome_id}")
    return dict(longest[0])
