###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       create_counts_df.py
###############################################################################
import pandas as pd
import typing
import os


def create_df(counts_list: typing.List[typing.Dict[str, any]], 
                csv_path: typing.Union[str, os.PathLike]) \
    -> pd.DataFrame:
    counts_df = pd.DataFrame(counts_list)
    counts_df = counts_df.fillna(0)
    counts_df.to_csv(csv_path)
    return counts_df
