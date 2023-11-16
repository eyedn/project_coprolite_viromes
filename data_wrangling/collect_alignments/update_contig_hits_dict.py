###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       update_contig_hits_dict.py
###############################################################################
import typing
from . import contig


def update_contig_hits_dict(sample_label: str, contigs: typing.Dict[str, contig.Contig],
    contig_hits_dict: typing.Dict[str, typing.List[int]]) \
    -> typing.Dict[str, typing.Dict[str, int]]:
    
    contig_hits_dict[sample_label] = {}
    contig_hits_dict[sample_label]["total_length"] = 0
    contig_hits_dict[sample_label]["unique_cover"] = 0

    for key in contigs.keys():
        contig = contigs[key]
        base_stats = contig.get_base_stats()
        contig_hits_dict[sample_label]["total_length"] += base_stats[0]
        contig_hits_dict[sample_label]["unique_cover"] += base_stats[1]

    return contig_hits_dict

