###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_table.py
###############################################################################
import typing
from . import hit


def read_table(table: typing.TextIO, eval: float) \
    -> typing.Tuple[typing.List[str], typing.List[hit.Hit]]:

    hit_labels: typing.List[str] = []
    hits: typing.List[hit.Hit] = []

    with open(table) as f:
        for line in f.readlines():
            poss_hit = line.strip()
            if poss_hit.startswith("#"):
                continue
            poss_hit_data = poss_hit.split()
            if float(poss_hit_data[4]) <= eval:
                if poss_hit_data[2] not in hit_labels:
                    hits.append(hit.Hit(poss_hit_data[2]))
                    hit_labels.append(poss_hit_data[2])
                hits[-1].add_query(poss_hit_data[0], float(poss_hit_data[4]))

    return hit_labels, hits    
