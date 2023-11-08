###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       hit.py
###############################################################################
import typing
import pandas as pd
from hit import Hit

def get_df(label: str, hits: typing.List[Hit],
    counts_dict: typing.Dict[str, typing.Dict[str, int]] = {}) -> pd.DataFrame:

    counts_dict[label] = {}
    
    for hit in hits:
        counts_dict[label][hit.label] = len(hit.queries)
    counts_df = pd.DataFrame(counts_dict)

    return counts_df
