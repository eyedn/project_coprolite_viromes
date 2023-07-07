###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		identify_fastq_files.py
###############################################################################
from sys import argv
import file_search as fs


if __name__ == "__main__":
    fastq_dir = argv[1]
    single_data, paired_data_1, paried_data_2 = fs.search_main.search_directory(fastq_dir)
    print(fs.format.format_output(single_data, paired_data_1, paried_data_2))
