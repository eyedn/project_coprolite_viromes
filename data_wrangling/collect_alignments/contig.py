###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       contig.py
###############################################################################
import typing
import statistics


class Contig:
    def __init__(self, label: str, len: int) -> None:
        self.label: str = label
        self.len: int = len
        self.covered_bases: typing.List[int] = []
        self.perc_covered: float = 0.0
        self.coverage_depth: float = 0.0

    def add_covered_bases(self, bases: typing.List[int]) -> None:
        self.covered_bases.append(bases)

    def calc_perc_covered(self) -> None:
        unique_covereage = set(self.covered_bases)
        self.perc_covered = len(unique_covereage) / self.len

    def calc_coverage_depth(self) -> None:
        depth: typing.List[int] = []
        for i in range(self.len):
            ith_depth = self.covered_bases.count(i) 
            depth.append(ith_depth)
        self.coverage_depth = statistics.median(depth)
