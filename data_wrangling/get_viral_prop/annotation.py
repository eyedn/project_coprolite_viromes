###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       annotation.py
###############################################################################
import typing


# annotations are obtained fom a gff file after annotation
class Annotation:
    def __init__(self, data: typing.List[str]) -> None:
        self.contig = data[0]
        self.start = data[3]
        self.end = data[4]
        self.strand = data[6]
