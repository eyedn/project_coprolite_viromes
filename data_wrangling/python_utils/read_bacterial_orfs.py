###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       read_bacterial_orfs.py
###############################################################################


"""Read complete bacterial Prokka outputs and validate exact joins."""
import gzip
from pathlib import Path

# support both pipeline entrypoints and repository-qualified package imports.
if __package__ and "." in __package__:
    from ..collect_phage_vf_stats.parse_gff_lines import parse_gff_lines
else:
    from collect_phage_vf_stats.parse_gff_lines import parse_gff_lines
from .parse_protein_ids import parse_protein_ids
from .join_bacterial_orfs import join_bacterial_orfs


def read_bacterial_orfs(gff_path, faa_path, sample):
    contents = []
    for input_path in (gff_path, faa_path):
        path = Path(input_path)
        if not path.is_file():
            path = Path(str(path) + ".gz")
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt", encoding="utf-8") as handle:
            contents.append(list(handle))
    contigs, orfs, invalid = parse_gff_lines(contents[0], sample)
    if invalid:
        raise ValueError("invalid GFF coordinates: " + ", ".join(invalid))
    rows = join_bacterial_orfs(orfs, parse_protein_ids(contents[1]), sample)
    return contigs, orfs, rows
