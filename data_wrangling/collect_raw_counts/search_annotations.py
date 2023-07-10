###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       search_annotations.py
###############################################################################
import typing
from . import annotation as annot

def get_counts(annotations: typing.List[annot.Annotation]) \
    -> typing.Dict[str, int]:
    counts = {}
    for annot in annotations:
        if annot.ec_num == "":
            continue
        elif annot.ec_num not in counts:
            counts[annot.ec_num] = 0
        counts[annot.ec_num] += 1
    return counts
