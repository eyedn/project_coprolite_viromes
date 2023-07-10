###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       create_counts_df.py
###############################################################################
import pandas as pd
import typing
import os


def create_df(counts_dict: typing.Dict[str, typing.Dict[str, int]], 
                csv_path: typing.Union[str, os.PathLike]) \
    -> pd.DataFrame:
    counts_df = pd.DataFrame(counts_dict)
    counts_df = counts_df.fillna(0)
    counts_df.to_csv(csv_path)
    return counts_df