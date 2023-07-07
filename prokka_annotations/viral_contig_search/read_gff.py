###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_gff.py
###############################################################################
import typing
import gzip
from . import annotation as annot


# read gzipped gff file of annotation and return a list of those annotations
def read_annotations(gff_file: typing.BinaryIO) -> typing.List[annot.Annotation]:
    annotations: typing.List[annot.Annotation] = []
    with gzip.open(gff_file, "rt") as f:
        for line in f.readlines():
            curr_line = str(line.strip())
            # skip contigs section
            if curr_line.startswith(">") or curr_line == "##FASTA":
                break
            # skip header section
            if curr_line.startswith("##"):
                continue
            line_data = curr_line.split("\t")
            annotations.append(annot.Annotation(line_data))
    return annotations

