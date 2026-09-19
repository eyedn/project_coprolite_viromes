###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_checkv_lines.py
###############################################################################
"""Parse supplied CheckV tables, including the merged-header variant."""

import csv


def parse_checkv_lines(lines):
    """Return CheckV records with separate warnings, Lifestyle, and Source."""
    rows = list(csv.reader(lines, delimiter="\t"))
    if not rows:
        raise ValueError("empty CheckV quality summary")
    header = rows[0]
    merged_index = None
    if "warningsLifestyle" in header:
        merged_index = header.index("warningsLifestyle")
        header = (
            header[:merged_index]
            + ["warnings", "Lifestyle"]
            + header[merged_index + 1:]
        )
    required = {"contig_id", "warnings", "Lifestyle", "Source"}
    missing = sorted(required - set(header))
    if missing:
        raise ValueError(
            "CheckV table missing required columns: " + ", ".join(missing)
        )

    parsed = []
    seen = set()
    for row_number, values in enumerate(rows[1:], start=2):
        if not values or not any(value.strip() for value in values):
            continue
        if merged_index is not None and len(values) == len(header) - 1:
            merged_value = values[merged_index].strip()
            tokens = merged_value.rsplit(None, 1)
            if len(tokens) != 2:
                raise ValueError(
                    f"cannot split warningsLifestyle at row {row_number}"
                )
            values = (
                values[:merged_index]
                + tokens
                + values[merged_index + 1:]
            )
        if len(values) != len(header):
            raise ValueError(
                f"CheckV row {row_number} has {len(values)} fields; "
                f"expected {len(header)}"
            )
        record = dict(zip(header, values))
        contig_id = record["contig_id"].strip()
        if not contig_id:
            raise ValueError(f"empty CheckV contig_id at row {row_number}")
        if not record["Lifestyle"].strip() or not record["Source"].strip():
            raise ValueError(
                f"empty CheckV Lifestyle or Source at row {row_number}"
            )
        if contig_id in seen:
            raise ValueError(f"duplicate CheckV contig_id: {contig_id}")
        seen.add(contig_id)
        parsed.append(record)
    return parsed
