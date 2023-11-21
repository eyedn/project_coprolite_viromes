###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_fa.py
###############################################################################
import typing
from . import contig


# read an fa file of contigs and return a list of contigs of that fa file
def read_contigs(fa_file: typing.TextIO, contigs: typing.List[contig.Contig] = [],
                existing_labels: typing.Set[str] = set()) \
    -> typing.Tuple[typing.List[contig.Contig], typing.List[str], typing.List[str]]:

    new_labels: typing.Set[str] = set()
    skip_sequence = False

    with open(fa_file) as f:
        for line in f.readlines():
            curr_line = str(line.strip())
            # lines that start with ">" contain are the contig label
            if curr_line.startswith(">"):
                line_data = curr_line.split()
                new_labels.add(line_data[0][1:])
                # skip to next contig if it was already added
                if line_data[0][1:] in existing_labels:
                    skip_sequence = True
                    continue
                else:
                    existing_labels.add(line_data[0][1:])
                skip_sequence = False
                contigs.append(contig.Contig(line_data))
            # line without ">" contain sequence info related to the current label
            elif not skip_sequence:
                contigs[-1].append_to_sequence(curr_line)

    return contigs, existing_labels, new_labels
