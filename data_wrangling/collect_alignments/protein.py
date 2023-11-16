###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       annotation.py
###############################################################################
import typing
from . import contig


# annotations are obtained fom a gff file after annotation
class Protein:
    def __init__(self, label: str) -> None:
        self.label: str = label
        self.start: int = None
        self.end: int = None
        self.aligned_bases: typing.Set[int] = set()
        self.contig: contig.Contig = None

    def add_start_end(self, start: int, end: int) -> None:
        self.start: int = start
        self.end: int = end

    def get_start_to_end(self) -> typing.Set[int]:
        bases_covered_on_contig = set(range(self.start, self.end + 1))
        return bases_covered_on_contig

    def add_aligned_bases(self, start: int, end: int) -> None:
        aligned_bases = list(range(start + self.start - 1, end + self.start))
        self.aligned_bases.update(aligned_bases)

    def add_contig(self, contig: contig.Contig) -> None:
        self.contig = contig
