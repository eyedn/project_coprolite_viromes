###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       identify_viral_contigs.py
###############################################################################
from sys import argv
import viral_contig_search as vcs


if __name__ == "__main__":
    all_contigs_fa = argv[1]
    phage_fa = argv[2]
    gff_file = argv[3]
    my_contigs, my_contig_labels, my_contig_labels = vcs.read_fa.read_contigs(all_contigs_fa)
    _, _, my_phage_labels = vcs.read_fa.read_contigs(phage_fa, my_contigs, my_contig_labels)
    my_viral_genes = vcs.read_gff.read_annotations(gff_file)
    vcs.results.print_annotated_contigs(my_contigs, my_viral_genes, my_contig_labels, my_phage_labels)
