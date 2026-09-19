###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_phatyp_rows.py
###############################################################################
"""Validate and normalize rows from one PhaTYP prediction table."""


def parse_phatyp_rows(
        rows, fieldnames, sample, category, origin, sample_id):
    """Convert PhaTYP CSV rows to the collector's phage records."""
    fieldnames = fieldnames or []
    identifier_columns = [
        column for column in ("Contig", "Accession")
        if column in fieldnames
    ]
    if len(identifier_columns) != 1 or "Pred" not in fieldnames:
        raise ValueError(
            "PhaTYP table missing required columns: exactly one of Contig or "
            "Accession, plus Pred"
        )

    score_columns = [
        column for column in (
            "Score", "score", "Pred_score", "Prediction_score",
            "Confidence",
        )
        if column in fieldnames
    ]
    if len(score_columns) > 1:
        raise ValueError(
            "PhaTYP table has multiple recognized score columns: "
            f"{', '.join(score_columns)}"
        )

    identifier_column = identifier_columns[0]
    score_column = score_columns[0] if score_columns else None
    parsed_rows = []
    for row_number, row in enumerate(rows, start=2):
        contig_id = str(row.get(identifier_column, "")).strip()
        lifestyle_raw = str(row.get("Pred", "")).strip()
        if not contig_id or not lifestyle_raw:
            raise ValueError(
                f"PhaTYP row {row_number} has an empty identifier or Pred"
            )

        normalized = {
            "virulent": "Lytic",
            "temperate": "Temperate",
        }.get(lifestyle_raw.casefold(), lifestyle_raw)
        score = None
        if score_column and str(row.get(score_column, "")).strip():
            try:
                score = float(row[score_column])
            except ValueError as error:
                raise ValueError(
                    f"PhaTYP row {row_number} has a nonnumeric score"
                ) from error

        parsed_rows.append({
            "category": category,
            "origin": origin,
            "sample_id": sample_id,
            "sample": sample,
            "contig_id": contig_id,
            "lifestyle_raw": lifestyle_raw,
            "lifestyle": normalized,
            "phatyp_score": score,
        })

    return parsed_rows
