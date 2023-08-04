###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_stats.py
###############################################################################
import pandas as pd
import typing
import os

def get_stats(stats_file: typing.Union[str, os.PathLike], sample_name: str,
                csv_path: typing.Union[str, os.PathLike]) -> pd.DataFrame:
    read_stats = ""
    contig_stats = ""
    with open(stats_file, "r") as f:
        read_stats = f.readline()
        contig_stats = f.readline()

    total_reads = read_stats.strip().split(", ")[-2].split(" ")[0]
    max_read_length = read_stats.strip().split(", ")[-1].split(" ")[0]

    total_contigs = contig_stats.strip().split(", ")[0].split(" ")[-2]
    total_contig_length = contig_stats.strip().split(", ")[1].split(" ")[1]
    min_contig = contig_stats.strip().split(", ")[2].split(" ")[1]
    max_contig = contig_stats.strip().split(", ")[3].split(" ")[1]
    av_contig = contig_stats.strip().split(", ")[4].split(" ")[1]

    cat = sample_name.split("-")[0]
    ori = sample_name.split("_")[0].split("-")[1]
    sample = sample_name.split("_")[1]

    stats_dict = {'cat': [cat], 'ori': [ori], 'sample': [sample],
                    'total_reads': [total_reads], 'max_reads': [max_read_length],
                    'total_contig_len': [total_contig_length],
                    'total_contigs': [total_contigs], 'min_contig': [min_contig],
                    'max_contig': [max_contig], 'av_contig': [av_contig]}
    stats_df = pd.DataFrame(stats_dict)

    stats_df.to_csv(csv_path)
    return(stats_df)
