###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       search_files.py
###############################################################################
import typing
import gzip
from . import read_gff
from . import search_annotations as search_annot

def get_counts_dict(files: typing.List[typing.Union[str, typing.BinaryIO]]) \
    -> typing.Dict[str, typing.Dict[str, int]]:
    counts: typing.Dict[str, typing.Dict[str, int]] = {}
    for file in files:
        sample_name = file.strip().split("_")[:1]
        sample_name = ''.join(sample_name)
        sample_counts = {}
        with gzip(file, "rt") as f:
            file_annotations = read_gff.read_annotations(f)
            sample_counts = search_annot.get_counts(file_annotations)
            counts[sample_name] = sample_counts
    return counts
