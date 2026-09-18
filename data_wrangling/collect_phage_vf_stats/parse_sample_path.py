###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           parse_sample_path.py
###############################################################################
# pattern: Functional Core

"""Parse category, origin, and sample identifiers from input paths."""

import re
from pathlib import Path


def parse_sample_path(path, input_type):
    """Return canonical metadata parsed from a PhaTYP or GFF path."""
    path = Path(path)
    suffix_by_type = {
        "prediction": "_prediction",
        "gff": "_annotation_bac_on_phage",
    }
    if input_type not in suffix_by_type:
        raise ValueError(f"unsupported input type: {input_type}")

    suffix = suffix_by_type[input_type]
    directory_name = path.parent.parent.name if input_type == "prediction" \
        else path.parent.name
    if not directory_name.endswith(suffix):
        raise ValueError(
            f"could not parse {input_type} metadata from path: {path}"
        )

    sample_label = directory_name[:-len(suffix)]
    match = re.fullmatch(r"([^-]+)-([^_]+)_(.+)", sample_label)
    if match is None:
        raise ValueError(
            f"could not parse category, origin, and sample ID from: {path}"
        )

    category, origin, sample_id = match.groups()
    return {
        "category": category,
        "origin": origin,
        "sample_id": sample_id,
        "sample": f"{category}.{origin}_{sample_id}",
    }
