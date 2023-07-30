###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       contig.py
###############################################################################
import typing


# contigs are extracted from fa files after assembly
class Contig:
    def __init__(self, data: typing.List[str]) -> None:
        self.label = data[0][1:]
        flag = data[1].split("=")[1]
        self.flag = flag
        mutli = data[2].split("=")[1]
        self.mutli = mutli
        len = data[3].split("=")[1]
        self.len = len
        self.sequence = ""
        self.affil: typing.List[str] = []
    
    def append_to_sequence(self, sequence: str) -> None:
        self.sequence = self.sequence + sequence

    def print_contig(self) -> None:
        affil = ";".join(self.affil)
        print(f">{self.label} flag={self.flag} mutli={self.mutli} len={self.len} affil={affil}")
        print(self.sequence)
