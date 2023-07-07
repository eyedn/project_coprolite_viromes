###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_fa.py
###############################################################################
import typing
from . import contig


# read an fa file of contigs and return a list of contigs of that fa file
def read_contigs(fa_file: typing.TextIO) -> typing.List[contig.Contig]:
    contigs: typing.List[contig.Contig] = []
    with open(fa_file, "r") as f:
        for line in f.readlines():
            curr_line = str(line.strip())
            # lines that start with ">" contain are the contig label
            if curr_line.startswith(">"):
                line_data = curr_line.split()
                contigs.append(contig.Contig(line_data))
            # line without ">" contain sequence info related to the current label
            else:
                contigs[-1].append_to_sequence(curr_line)
    return contigs
