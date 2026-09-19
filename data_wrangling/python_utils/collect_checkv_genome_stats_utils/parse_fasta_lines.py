###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_fasta_lines.py
###############################################################################
"""Parse exact FASTA identifiers and sequence lengths."""


def parse_fasta_lines(lines):
    """Return an insertion-ordered mapping of FASTA identifier to length."""
    lengths = {}
    current_id = None
    current_length = 0
    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith(">"):
            if current_id is not None:
                lengths[current_id] = current_length
            current_id = line[1:].split()[0]
            if not current_id:
                raise ValueError(
                    f"empty FASTA identifier at line {line_number}"
                )
            if current_id in lengths:
                raise ValueError(f"duplicate FASTA identifier: {current_id}")
            current_length = 0
        else:
            if current_id is None:
                raise ValueError("FASTA sequence occurs before first header")
            current_length += len(line)
    if current_id is not None:
        if current_id in lengths:
            raise ValueError(f"duplicate FASTA identifier: {current_id}")
        lengths[current_id] = current_length
    if not lengths:
        raise ValueError("FASTA contains no records")
    return lengths
