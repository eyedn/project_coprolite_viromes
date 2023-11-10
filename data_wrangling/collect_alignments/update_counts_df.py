###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       update_counts_df.py
###############################################################################
import typing
from . import hit

def update_counts_df(label: str, hits: typing.List[hit.Hit],
    counts_dict: typing.Dict[str, typing.Dict[str, int]]) \
    -> typing.Dict[str, typing.Dict[str, int]]:

    counts_dict[label] = {}

    for hit in hits:
        counts_dict[label][hit.label] = len(hit.queries)

    return counts_dict
