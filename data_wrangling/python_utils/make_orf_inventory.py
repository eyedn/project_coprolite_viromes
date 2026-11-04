###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       make_orf_inventory.py
###############################################################################


"""Attach best qualifying hits while retaining non-hit bacterial ORFs."""


def make_orf_inventory(rows, hits_by_id, context):
    inventory = []
    for row in rows:
        hit = hits_by_id.get(row["feature_id"], {})
        inventory.append({
            **context, **row,
            "vf_id": hit.get("query_name", ""),
            "full_seq_evalue": hit.get("full_seq_evalue", ""),
            "full_seq_score": hit.get("full_seq_score", ""),
            "full_seq_bias": hit.get("full_seq_bias", ""),
            "vf_description": hit.get("description", ""),
        })
    return inventory
