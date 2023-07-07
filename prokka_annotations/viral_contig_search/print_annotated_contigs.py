###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       print_annotated_contigs.py
###############################################################################
import typing
import gzip
from . import contig
from . import annotation as annot


def print_annotated_contigs(contigs: typing.List[contig.Contig], 
                            annotations: typing.List[annot.Annotation]) \
                            -> None:
    # first, collect all contigs that have been labeled by an anotation
    annotated_contigs = set()
    for annotation in annotations:
        annotated_contigs.add(annotation.contig)
    # second, print out those contigs and their sequences
    for contig in contigs: 
        if contig.label in annotated_contigs:
            contig.print_contig()
