###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       select_best_vf_hits.py
###############################################################################
"""Apply stringent VFDB thresholds and deterministic per-ORF selection."""

import math

from .constants import (
    MAX_FULL_SEQ_EVALUE,
    MIN_FULL_SEQ_SCORE,
    MIN_SCORE_TO_BIAS_RATIO,
)


def select_best_vf_hits(rows, eligible_feature_ids):
    """Return one best qualifying VFDB hit per eligible bacterial ORF."""
    selected = {}
    for row_number, row in enumerate(rows, start=1):
        target_name = str(row.get("target_name", "")).strip()
        if target_name not in eligible_feature_ids:
            continue
        try:
            evalue = float(row["full_seq_evalue"])
            score = float(row["full_seq_score"])
            bias = float(row["full_seq_bias"])
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError(
                f"invalid VFDB threshold fields at row {row_number}"
            ) from error
        if not all(math.isfinite(value) for value in (evalue, score, bias)):
            raise ValueError(f"non-finite VFDB threshold at row {row_number}")
        if evalue > MAX_FULL_SEQ_EVALUE or score < MIN_FULL_SEQ_SCORE:
            continue
        if score < MIN_SCORE_TO_BIAS_RATIO * bias:
            continue
        query_name = str(row.get("query_name", "")).strip()
        if not query_name:
            raise ValueError(f"empty VFDB identifier at row {row_number}")
        normalized = dict(row)
        normalized.update({
            "full_seq_evalue": evalue,
            "full_seq_score": score,
            "full_seq_bias": bias,
        })
        rank = (evalue, -score, bias, query_name)
        if target_name not in selected or rank < selected[target_name][0]:
            selected[target_name] = (rank, normalized)
    return [selected[key][1] for key in sorted(selected)]
