###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       get_table_counts.py
###############################################################################
import typing
import pandas as pd
from glob import glob
from . import read_table, update_counts_df


def get_table_counts(template_path: str) -> pd.DataFrame:

    counts_dict: typing.Dict[str, typing.Dict[str, int]] = {}

    print(template_path)
    print(glob(template_path, recursive = True))

    for table in glob(template_path, recursive = True):
        print(table)
        _, hits = read_table.read_table(table, 1e-5)
        label = table.split("/")[-2]
        counts_dict = update_counts_df.update_counts_df(label, hits,
                                                        counts_dict)

    counts_df = pd.DataFrame(counts_dict)

    return counts_df
