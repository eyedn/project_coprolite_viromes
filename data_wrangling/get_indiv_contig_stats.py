###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_indiv_contig_stats.py
###############################################################################
from sys import argv
import get_contig_stats as gcs

if __name__ == "__main__":
    stats_file = argv[1]
    csv_path = argv[2]

    sample_name = stats_file.strip().split("/")[-1].split("_contig_")[0]
    stats_dict = gcs.stats.get_stats(stats_file, sample_name, csv_path)
