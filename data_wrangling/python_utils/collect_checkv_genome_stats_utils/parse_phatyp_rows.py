###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_phatyp_rows.py
###############################################################################
"""Normalize installed legacy and current PhaTYP table rows."""


def parse_phatyp_rows(rows, fieldnames):
    """Return one normalized PhaTYP record per exact FASTA identifier."""
    fieldnames = fieldnames or []
    id_columns = [
        name for name in ("Contig", "Accession")
        if name in fieldnames
    ]
    lifestyle_columns = [
        name for name in ("Pred", "TYPE", "Lifestyle")
        if name in fieldnames
    ]
    score_columns = [
        name for name in ("Score", "PhaTYPScore", "Pred_score")
        if name in fieldnames
    ]
    if len(id_columns) != 1 or len(lifestyle_columns) != 1:
        raise ValueError(
            "PhaTYP table has unsupported identifier/lifestyle columns"
        )
    if len(score_columns) > 1:
        raise ValueError("PhaTYP table has multiple recognized score columns")
    parsed = {}
    for row_number, row in enumerate(rows, start=2):
        genome_id = str(row.get(id_columns[0], "")).strip()
        lifestyle_raw = str(row.get(lifestyle_columns[0], "")).strip()
        if not genome_id or not lifestyle_raw:
            raise ValueError(f"empty PhaTYP field at row {row_number}")
        if genome_id in parsed:
            raise ValueError(
                f"duplicate PhaTYP genome identifier: {genome_id}"
            )
        lifestyle = {
            "virulent": "Lytic",
            "lytic": "Lytic",
            "temperate": "Temperate",
        }.get(lifestyle_raw.casefold(), lifestyle_raw)
        score = ""
        if score_columns:
            score = str(row.get(score_columns[0], "")).strip()
            if score:
                try:
                    float(score)
                except ValueError as error:
                    raise ValueError(
                        f"nonnumeric PhaTYP score at row {row_number}"
                    ) from error
        parsed[genome_id] = {
            "lifestyle_raw": lifestyle_raw,
            "lifestyle": lifestyle,
            "score": score,
        }
    return parsed
