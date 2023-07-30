###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       identify_viral_contigs.py
###############################################################################
from sys import argv
import viral_contig_search as vcs


if __name__ == "__main__":
    viral_fa = argv[1]
    phage_fa = argv[2]
    gff_file = argv[3]
    my_contigs, my_contig_labels, my_viral_labels = vcs.read_fa.read_contigs(viral_fa)
    my_contigs, _, my_phage_labels = vcs.read_fa.read_contigs(phage_fa, my_contigs, my_contig_labels)
    my_annotations = vcs.read_gff.read_annotations(gff_file)
    vcs.results.print_annotated_contigs(my_contigs, my_annotations, my_viral_labels, my_phage_labels)
