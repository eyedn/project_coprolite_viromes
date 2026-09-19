###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_hmmer_lines.py
###############################################################################
"""Parse HMMER tblout rows used for CheckV-genome VFDB alignment."""


def parse_hmmer_lines(lines):
    """Return the threshold-relevant fields from HMMER tblout text."""
    rows = []
    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split(maxsplit=18)
        if len(fields) < 18:
            raise ValueError(f"malformed HMMER row at line {line_number}")
        rows.append({
            "target_name": fields[0],
            "query_name": fields[2],
            "full_seq_evalue": fields[4],
            "full_seq_score": fields[5],
            "full_seq_bias": fields[6],
            "description": fields[18] if len(fields) > 18 else "",
        })
    return rows
