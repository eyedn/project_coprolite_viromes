###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       combine_data.py
###############################################################################
import typing
import pandas as pd
import glob


# read an fa file of contigs and return a list of contigs of that fa file
def combine_data(path: str) -> pd.DataFrame:

    all_files = glob.glob(path + "/*.csv")

    # combine all files in the list into one DataFrame
    df = pd.concat((pd.read_csv(f) for f in all_files), ignore_index=True)

    # group by 'cat', 'ori', 'sample'
    # sum 'prokka_res', 'phabox_res', and count total rows
    result = df.groupby(['cat', 'ori', 'sample']).agg({
        'prokka_res': 'sum',
        'phabox_res': 'sum',
        'contig': 'size'
    }).rename(columns={'contig': 'total_contigs'}).reset_index()

    return result
