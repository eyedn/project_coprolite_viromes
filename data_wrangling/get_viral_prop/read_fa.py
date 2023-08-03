###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_fa.py
###############################################################################
from . import contig
import typing
import gzip


# read an fa file of contigs and return a list of contigs of that fa file
def read_contigs(fa_file: typing.TextIO) -> typing.Dict[str, contig.Contig]:
    contigs: typing.Dict[str, contig.Contig] = {}
    existing_labels: typing.Set[str] = set()
    with gzip.open(fa_file, "rt") as f:
        for line in f.readlines():
            curr_line = str(line.strip())
            # lines that start with ">" contain are the contig label
            if curr_line.startswith(">"):
                line_data = curr_line.split()
                # skip to next contig if it was already added
                if line_data[0][1:] in existing_labels:
                    continue
                else:
                    existing_labels.add(line_data[0][1:])
                contigs[line_data[0][1:]] = contig.Contig(line_data)
    return contigs
