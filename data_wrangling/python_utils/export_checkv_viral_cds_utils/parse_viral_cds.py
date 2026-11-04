###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_viral_cds.py
###############################################################################


from urllib.parse import unquote


def parse_viral_cds(lines, metadata):
    """Extract every conservative viral CDS and validate against metadata."""
    genome_lengths = {}
    for row in metadata:
        if row["checkv_filter"] != "conservative":
            continue
        genome_id = row["genome_id"]
        length = int(row["genome_length"])
        if not genome_id or genome_id in genome_lengths or length < 1:
            raise ValueError("Invalid or duplicate conservative genome metadata")
        genome_lengths[genome_id] = length
    if not genome_lengths:
        raise ValueError("No conservative genome metadata")

    features = []
    seen = set()
    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()
        if line == "##FASTA":
            break
        if line.startswith("##sequence-region "):
            _, genome_id, start, end = line.split()
            if (genome_id not in genome_lengths or int(start) != 1
                    or int(end) != genome_lengths[genome_id]):
                raise ValueError(f"GFF sequence-region mismatch: {genome_id}")
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 9:
            raise ValueError(f"Malformed GFF row at line {line_number}")
        if fields[2] != "CDS":
            continue
        genome_id = fields[0]
        attributes = dict(
            item.split("=", 1) for item in fields[8].split(";") if "=" in item
        )
        attributes = {key: unquote(value) for key, value in attributes.items()}
        feature_id = attributes.get("ID", "").strip()
        key = (genome_id, feature_id)
        if not feature_id or key in seen:
            raise ValueError(f"Missing or duplicate CDS ID at line {line_number}")
        if genome_id not in genome_lengths:
            raise ValueError(f"Unknown CDS genome at line {line_number}")
        start, end = int(fields[3]), int(fields[4])
        if not 1 <= start <= end <= genome_lengths[genome_id]:
            raise ValueError(f"Invalid CDS coordinates at line {line_number}")
        if fields[6] not in {"+", "-"}:
            raise ValueError(f"Invalid CDS strand at line {line_number}")
        seen.add(key)
        features.append({
            "checkv_filter": "conservative",
            "genome_id": genome_id,
            "feature_id": feature_id,
            "start": start,
            "end": end,
            "strand": fields[6],
            "product": attributes.get("product", ""),
            "ec_number": (attributes.get("eC_number", "")
                          or attributes.get("EC_number", "")),
        })
    if not features:
        raise ValueError("No viral CDS found in conservative GFF")
    return features
