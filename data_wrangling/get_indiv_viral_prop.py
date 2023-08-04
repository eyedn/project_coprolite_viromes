###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop.py
###############################################################################
from sys import argv
import get_viral_prop as gvp


if __name__ == "__main__":
    fa_file = argv[1]
    gff_file = argv[2]
    csv_path = argv[3]
    viral_gene_coverage = gvp.get.get_viral_prop_from_annot(fa_file, gff_file)
    viral_gene_coverage_dict = gvp.create.create_df(viral_gene_coverage, csv_path)
