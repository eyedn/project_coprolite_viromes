###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       get_table_counts.py
###############################################################################
import typing
import pandas as pd
from glob import glob
from read_table import read_table
from get_df import get_df
from hit import Hit


def get_table_counts(template_path: str) \
    -> typing.Tuple[typing.List[str], typing.List[Hit]]:

    pattern = f"{template_path}/table.txt"
    table_paths = glob(pattern)
    counts_dict: typing.Dict[str, typing.Dict[str, int]] = {}

    for table in table_paths:
        _, hits = read_table(table, 1e-5)
        label = table.split("/")[-2]
        counts_dict = get_df(label, hits, counts_dict)
    counts_df = pd.DataFrame(counts_dict)

    return counts_df
