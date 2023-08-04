###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		combine_csv_files.py
###############################################################################
import typing
import os
import pandas as pd


def combine_csv_files(directory_path: typing.Union[str, os.PathLike],
                        output_filename: typing.Union[str, os.PathLike]) \
    -> pd.DataFrame:
    csv_files = [file for file in os.listdir(directory_path) if file.endswith('.csv')]
    dataframes: typing.List[pd.DataFrame] = []

    for csv_file in csv_files:
        file_path = os.path.join(directory_path, csv_file)
        df = pd.read_csv(file_path)
        dataframes.append(df)

    # concatenate all dataframes into a single dataframe
    combined_df = pd.concat(dataframes, ignore_index=True)
    combined_df.to_csv(output_filename, index=False)
    return combined_df
