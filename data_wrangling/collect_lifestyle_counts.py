###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		collect_lifestyle_counts.py
###############################################################################
from sys import argv
import collect_lifestyle_counts as clc
from collect_ec_counts import create_list, create


if __name__ == "__main__":
    predictions_list_file = argv[1]
    csv_path = argv[2]
    lifestyle_list = create_list.create_list(predictions_list_file)
    counts_dict = clc.search.get_counts_dict(lifestyle_list)
    counts_df = create.create_df(counts_dict, csv_path)