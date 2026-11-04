###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_protein_ids.py
###############################################################################


"""Validate protein FASTA records without changing exact identifiers."""
import re


def parse_protein_ids(lines):
    ids = set()
    current = None
    has_sequence = False
    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        if line.startswith(">"):
            if current is not None and not has_sequence:
                raise ValueError(f"empty protein sequence: {current}")
            fields = line[1:].split()
            if not fields or fields[0] in ids:
                raise ValueError("empty or duplicate FAA identifier")
            current = fields[0]
            ids.add(current)
            has_sequence = False
        else:
            # translations from Prokka can contain internal or terminal stops.
            if current is None or re.fullmatch(r"[A-Za-z*]+", line) is None:
                raise ValueError("malformed protein FASTA")
            has_sequence = True
    if current is not None and not has_sequence:
        raise ValueError(f"empty protein sequence: {current}")
    return ids
