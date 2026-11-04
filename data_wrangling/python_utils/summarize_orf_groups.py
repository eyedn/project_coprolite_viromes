###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       summarize_orf_groups.py
###############################################################################


"""Count the full pool and independent annotation groups and overlaps."""


def summarize_orf_groups(rows, qualifying_ids):
    total = len(rows)
    hit_ids = set(qualifying_ids)
    groups = {
        "hypothetical": lambda row: row["is_hypothetical"],
        "ec_labeled": lambda row: row["has_ec_number"],
        "hypothetical_ec": lambda row: (
            row["is_hypothetical"] and row["has_ec_number"]
        ),
    }
    qualifying = sum(row["feature_id"] in hit_ids for row in rows)
    result = {
        "total_bacterial_orfs": total,
        "qualifying_vf_orfs": qualifying,
        "vf_present": int(qualifying > 0),
        "vf_orf_prevalence": qualifying / total if total else None,
    }
    for name, predicate in groups.items():
        result[name + "_orfs"] = sum(bool(predicate(row)) for row in rows)
        result["qualifying_" + name + "_orfs"] = sum(
            bool(predicate(row)) and row["feature_id"] in hit_ids
            for row in rows
        )
    return result
