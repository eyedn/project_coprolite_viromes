###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       print_annotated_contigs.py
###############################################################################
import typing
from . import contig
from . import annotation as annot


def print_annotated_contigs(contigs: typing.List[contig.Contig], 
                            annotations: typing.List[annot.Annotation],
                            viral_labels: typing.List[str] = [],
                            phage_labels: typing.List[str] = []) \
                            -> None:
    # first, collect all contigs that have been labeled by an anotation
    annotated_contigs = set()
    for annotation in annotations:
        annotated_contigs.add(annotation.contig)
    # second, print out those contigs and their sequences
    for contig in contigs: 
        if contig.label not in annotated_contigs:
            continue
        if len(viral_labels) != 0:
            if contig.label in viral_labels:
                contig.affil.append("viral")
            if contig.label in phage_labels:
                contig.affil.append("phage")
        contig.print_contig()
