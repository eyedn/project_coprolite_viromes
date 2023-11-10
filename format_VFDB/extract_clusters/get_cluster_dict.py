###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       protein.py
###############################################################################
import typing
import os
from . import protein


def get_clusters_dict(fasta_file: os.path) \
    -> typing.Dict[str, typing.List[protein.Protein]]:

    clusters: typing.Dict[str, typing.List[protein.Protein]] = {}
    with open(fasta_file) as f:
        for line in f.readlines():
            if line.startswith(">"):
                label = line.strip()
                clus = label.split(") - ")[0].split("(")[-1]
                if clus not in clusters:
                    clusters[clus] = []
                clusters[clus].append(protein.Protein(label))
            else:
                clusters[clus][-1].append_sequence(line.strip())
    return clusters