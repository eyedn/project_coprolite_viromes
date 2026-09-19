###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       extract_fasta_records.py
###############################################################################
"""Select protein FASTA records by exact identifier."""


def extract_fasta_records(lines, selected_ids):
    """Return FASTA text containing each selected identifier exactly once."""
    records = {}
    current_id = None
    current_lines = []
    for raw_line in lines:
        if raw_line.startswith(">"):
            if current_id is not None:
                if current_id in records:
                    raise ValueError(
                        f"duplicate protein FASTA ID: {current_id}"
                    )
                records[current_id] = current_lines
            current_id = raw_line[1:].split()[0]
            current_lines = [raw_line]
        elif current_id is not None:
            current_lines.append(raw_line)
    if current_id is not None:
        if current_id in records:
            raise ValueError(f"duplicate protein FASTA ID: {current_id}")
        records[current_id] = current_lines
    missing = sorted(set(selected_ids) - set(records))
    if missing:
        raise ValueError(
            "eligible Prokka features missing from protein FASTA: "
            + ", ".join(missing)
        )
    return "".join(
        "".join(records[feature_id]) for feature_id in sorted(selected_ids)
    )
