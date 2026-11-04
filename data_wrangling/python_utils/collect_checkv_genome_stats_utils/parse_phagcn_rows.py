###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_phagcn_rows.py
###############################################################################


"""Normalize legacy and current PhaGCN output schemas."""

import json


def parse_phagcn_rows(rows, fieldnames):
    """Return normalized taxonomy fields while preserving each raw row."""
    fieldnames = fieldnames or []
    id_columns = [
        name for name in ("Contig", "Accession")
        if name in fieldnames
    ]
    if len(id_columns) != 1:
        raise ValueError("PhaGCN table requires exactly one identifier column")
    aliases = {
        "lineage": ("Lineage", "lineage"),
        "family": ("Family", "family"),
        "family_score": ("Family_score", "FamilyScore", "Score"),
        "genus": ("Genus", "genus"),
        "genus_cluster": ("Genus_cluster", "GenusCluster"),
        "lineage_score": ("PhaGCNScore",),
    }
    parsed = {}
    for row_number, row in enumerate(rows, start=2):
        genome_id = str(row.get(id_columns[0], "")).strip()
        if not genome_id:
            raise ValueError(f"empty PhaGCN identifier at row {row_number}")
        if genome_id in parsed:
            raise ValueError(
                f"duplicate PhaGCN genome identifier: {genome_id}"
            )
        values = {}
        for output_name, options in aliases.items():
            values[output_name] = next(
                (
                    str(row.get(name, "")).strip()
                    for name in options
                    if name in fieldnames
                ),
                "",
            )
        if not values["family"] and values["lineage"]:
            family_parts = [
                part.split(":", 1)[1]
                for part in values["lineage"].split(";")
                if part.casefold().startswith("family:")
            ]
            values["family"] = family_parts[-1] if family_parts else ""
        if not values["family_score"] and values["lineage_score"]:
            lineage_parts = values["lineage"].split(";")
            score_parts = values["lineage_score"].split(";")
            family_indexes = [
                index for index, part in enumerate(lineage_parts)
                if part.casefold().startswith("family:")
            ]
            if family_indexes and family_indexes[-1] < len(score_parts):
                values["family_score"] = score_parts[family_indexes[-1]]
            else:
                values["family_score"] = values["lineage_score"]
        values["raw_json"] = json.dumps(row, sort_keys=True)
        parsed[genome_id] = values
    return parsed
