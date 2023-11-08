###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       annotation.py
###############################################################################
import typing
from contig import Contig


# annotations are obtained fom a gff file after annotation
class Protein:
    def __init__(self, label: str) -> None:
        self.label: str = label
        self.start: int = None
        self.end: int = None
        self.aligned_bases: typing.Set[int] = set()
        self.contig: Contig = None

    def add_start_end(self, start: int, end: int) -> None:
        self.start: int = start
        self.end: int = end

    def add_aligned_bases(self, start: int, end: int) -> None:
        aligned_bases = list(range(start, end + 1))
        self.aligned_bases.update(aligned_bases)

    def add_contig(self, contig: Contig) -> None:
        self.contig = contig
        bases_on_contg = list(range(self.start, self.end + 1))
        self.contig.add_covered_bases(bases_on_contg)
