###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       qualify_vf_hits.py
###############################################################################


"""Apply VFDB thresholds and retain one deterministic best hit per ORF."""

import math

from .constants import (
    MAX_FULL_SEQ_EVALUE,
    MIN_FULL_SEQ_SCORE,
    MIN_SCORE_TO_BIAS_RATIO,
    VF_REQUIRED_COLUMNS,
)


def qualify_vf_hits(rows):
    """Return the best qualifying VFDB row for each sample and Prokka ORF."""
    selected = {}
    for row_number, row in enumerate(rows, start=2):
        missing_columns = sorted(VF_REQUIRED_COLUMNS - set(row))
        if missing_columns:
            raise ValueError(
                "VFDB table missing required columns: "
                f"{', '.join(missing_columns)}"
            )
        try:
            evalue = float(row["full_seq_evalue"])
            score = float(row["full_seq_score"])
            bias = float(row["full_seq_bias"])
        except (TypeError, ValueError) as error:
            raise ValueError(
                f"VFDB row {row_number} has nonnumeric threshold fields"
            ) from error
        if not all(math.isfinite(value) for value in (evalue, score, bias)):
            raise ValueError(
                f"VFDB row {row_number} has non-finite threshold fields"
            )

        if evalue > MAX_FULL_SEQ_EVALUE or score < MIN_FULL_SEQ_SCORE:
            continue
        if score < MIN_SCORE_TO_BIAS_RATIO * bias:
            continue

        category = str(row["category"]).strip()
        origin = str(row["origin"]).strip()
        sample_id = str(row["sample_id"]).strip()
        target_name = str(row["target_name"]).strip()
        query_name = str(row["query_name"]).strip()
        if not all((category, origin, sample_id, target_name, query_name)):
            raise ValueError(f"VFDB row {row_number} has an empty identifier")

        sample = f"{category}.{origin}_{sample_id}"
        key = (sample, target_name)
        rank = (evalue, -score, query_name)
        current = selected.get(key)
        if current is None or rank < current["_rank"]:
            selected[key] = {
                **row,
                "sample": sample,
                "full_seq_evalue": evalue,
                "full_seq_score": score,
                "full_seq_bias": bias,
                "_rank": rank,
            }

    for row in selected.values():
        del row["_rank"]
    return selected
