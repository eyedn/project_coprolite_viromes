###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       contig.py
###############################################################################
import typing


class Contig:
    def __init__(self, label: str, len: int) -> None:
        self.label: str = label
        self.len: int = len
        self.covered_bases: typing.Set[int] = set()

    # covered bases are bases spanned by at least one protein
    def add_covered_bases(self, bases: typing.Set[int]) -> None:
        self.covered_bases.update(bases)

    def get_base_stats(self) -> typing.Tuple[int, int]:
        return self.len, len(self.covered_bases)
