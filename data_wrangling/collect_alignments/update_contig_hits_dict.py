###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       update_contig_hits_dict.py
###############################################################################
import typing
from . import contig


def update_contig_hits_dict(sample_label: str, contigs: typing.Dict[str, contig.Contig],
    contig_hits_dict: typing.Dict[str, typing.List[int]]) \
    -> typing.Dict[str, typing.List[int]]:
    
    contig_hits_dict[sample_label] = []
    
    for key in contigs.keys():
        contig = contigs[key]
        contig_hits_dict[sample_label].append(int(contig.hit_proteins))

    return contig_hits_dict

