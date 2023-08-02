###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       contig.py
###############################################################################
import typing
from . import annotation as annot


# contigs are extracted from fa files after assembly
class Contig:
    def __init__(self, data: typing.List[str]) -> None:
        self.label = data[0][1:]
        len = data[3].split("=")[1]
        self.len = len
        self.covered_bases: typing.Set[int] = set()
        self.spanned_by_prot = 0

    def add_covered_bases(self, annotation: annot.Annotation) -> None:
        start = int(annotation.start)
        end = int(annotation.end)

        for base in range(start, end + 1):
            self.covered_bases.add(int(base))

    def proportion_contig_spanned(self) -> None:
        self.spanned_by_prot = len(self.covered_bases) / int(self.len)
