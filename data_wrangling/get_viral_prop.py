###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop.py
###############################################################################
from sys import argv
import csv
import get_viral_prop as gvp
from collect_ec_counts import create_list


if __name__ == "__main__":
    # fa_list_file = "/Users/aydinkaratas/Documents/Research/project_coprolite_viromes/data_wrangling/fa_files.txt"
    # gff_list_file = "/Users/aydinkaratas/Documents/Research/project_coprolite_viromes/data_wrangling/gff_files.txt"
    # csv_path = "/Users/aydinkaratas/Documents/Research/project_coprolite_viromes/data_wrangling/text.csv"
    fa_list_file = argv[0]
    gff_list_file = argv[1]
    csv_path = argv[2]
    gff_list = create_list.create_list(gff_list_file)
    fa_list = create_list.create_list(fa_list_file)
    viral_gene_coverage = gvp.get.get_viral_prop_from_annot(fa_list, gff_list)

    with open(csv_path, 'w') as f:
        writer = csv.writer(f)
        for val in viral_gene_coverage:
            writer.writerow([val])
    
