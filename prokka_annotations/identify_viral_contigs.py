###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       identify_viral_contigs.py
###############################################################################
from sys import argv
import viral_contig_search as vcs


if __name__ == "__main__":
    fa_file = argv[1]
    gff_file = argv[2]
    my_contigs, _, _ = vcs.read_fa.read_contigs(fa_file)
    my_annotations = vcs.read_gff.read_annotations(gff_file)
    vcs.results.print_annotated_contigs(my_contigs, my_annotations)
