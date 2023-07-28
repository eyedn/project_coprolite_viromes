###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		collect_raw_counts.py
###############################################################################
from sys import argv
import collect_ec_counts as crc


if __name__ == "__main__":
    gff_list_file = argv[1]
    csv_path = argv[2]
    gff_list = crc.create_list.create_list(gff_list_file)
    counts_dict = crc.search.get_counts_dict(gff_list)
    counts_df = crc.create.create_df(counts_dict, csv_path)
