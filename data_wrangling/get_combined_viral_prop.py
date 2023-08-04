###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop.py
###############################################################################
from sys import argv
import get_viral_prop as gvp


if __name__ == "__main__":
    directory_path = argv[1]
    output_filename = argv[2]

    gvp.combine.combine_csv_files(directory_path, output_filename)