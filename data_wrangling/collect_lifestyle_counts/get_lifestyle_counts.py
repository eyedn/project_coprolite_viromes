###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       search_annotations.py
###############################################################################
import typing
import pandas as pd


def get_lifestyle_counts(lifestyle_data: typing.BinaryIO) -> typing.Dict[str, int]:
    lifestyle_df = pd.read_csv(lifestyle_data)
    lifestyle_counts = lifestyle_df["Pred"].value_counts()
    counts = lifestyle_counts.to_dict()
    return counts
