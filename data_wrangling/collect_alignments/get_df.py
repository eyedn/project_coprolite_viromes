###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       hit.py
###############################################################################
import typing
import pandas as pd
from . import hit

def get_df(label: str, hits: typing.List[hit.Hit],
    counts_dict: typing.Dict[str, typing.Dict[str, int]] = {}) -> pd.DataFrame:

    counts_dict[label] = {}

    for hit in hits:
        counts_dict[label][hit.label] = len(hit.queries)
    counts_df = pd.DataFrame(counts_dict)

    return counts_df
