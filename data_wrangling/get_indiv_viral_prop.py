###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_indiv_viral_prop.py
###############################################################################
from sys import argv
import get_viral_prop as gvp


if __name__ == "__main__":
    fa_file = argv[1]
    gff_file = argv[2]
    csv_path_all = argv[3]
    csv_path_no_hypo = argv[4]


    viral_gene_coverage_all = gvp.get.get_viral_prop_from_annot(fa_file, gff_file, True)
    viral_gene_coverage_no_hypo = gvp.get.get_viral_prop_from_annot(fa_file, gff_file, False)

    viral_gene_coverage_dict = gvp.create.create_df(viral_gene_coverage_all, csv_path_all)
    viral_gene_coverage_dict = gvp.create.create_df(viral_gene_coverage_no_hypo, csv_path_no_hypo)
