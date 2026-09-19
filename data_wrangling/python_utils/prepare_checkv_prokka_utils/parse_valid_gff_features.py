###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_valid_gff_features.py
###############################################################################
"""Select EC-labelled, non-hypothetical Prokka CDS annotations."""

from urllib.parse import unquote


def parse_valid_gff_features(lines):
    """Return valid Prokka CDS features from GFF text."""
    features = []
    seen = set()
    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.rstrip("\n")
        if line == "##FASTA":
            break
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 9:
            raise ValueError(f"malformed GFF row at line {line_number}")
        if fields[2] != "CDS":
            continue
        attributes = {}
        for item in fields[8].split(";"):
            if "=" in item:
                key, value = item.split("=", 1)
                attributes[key] = unquote(value)
        feature_id = attributes.get("ID", "").strip()
        product = attributes.get("product", "").strip()
        ec_number = (
            attributes.get("eC_number", "")
            or attributes.get("EC_number", "")
        ).strip()
        if not feature_id:
            raise ValueError(f"CDS has no ID at GFF line {line_number}")
        if feature_id in seen:
            raise ValueError(
                f"duplicate Prokka feature identifier: {feature_id}"
            )
        seen.add(feature_id)
        if not ec_number or "hypothetical protein" in product.casefold():
            continue
        try:
            start = int(fields[3])
            end = int(fields[4])
        except ValueError as error:
            raise ValueError(
                f"nonnumeric GFF coordinates at line {line_number}"
            ) from error
        if start < 1 or end < start or fields[6] not in {"+", "-"}:
            raise ValueError(f"invalid GFF feature at line {line_number}")
        features.append({
            "genome_id": fields[0],
            "feature_id": feature_id,
            "start": start,
            "end": end,
            "strand": fields[6],
            "product": product,
            "ec_number": ec_number,
        })
    return features
