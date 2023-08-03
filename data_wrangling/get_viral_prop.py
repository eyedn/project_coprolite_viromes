###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop.py
###############################################################################
from sys import argv
from collect_ec_counts import create_list
import pandas as pd
import get_viral_prop as gvp


if __name__ == "__main__":
    fa_list_file = argv[0]
    gff_list_file = argv[1]
    csv_path = argv[2]
    fa_list = create_list.create_list(fa_list_file)
    print('\n'.join(fa_list))
    gff_list = create_list.create_list(gff_list_file)
    print('\n'.join(gff_list))
    viral_gene_coverage = gvp.get.get_viral_prop_from_annot(fa_list, gff_list)
    viral_gene_coverage_dict = gvp.create.create_df(viral_gene_coverage, csv_path)
