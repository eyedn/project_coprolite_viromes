###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_table.py
###############################################################################
import typing
from . import hit


# read table file to produce dict of hits
def read_table(table: typing.TextIO, eval: float) -> typing.Dict[str, hit.Hit]:

    hits: typing.Dict[str, hit.Hit] = {}

    with open(table) as f:
        for line in f.readlines():
            poss_hit = line.strip()
            if poss_hit.startswith("#"):
                continue
            poss_hit_data = poss_hit.split()
            if float(poss_hit_data[4]) <= eval:
                if poss_hit_data[2] not in hits.keys():
                    hits[poss_hit_data[2]] = hit.Hit(poss_hit_data[2])
                hits[poss_hit_data[2]].add_query(poss_hit_data[0], float(poss_hit_data[4]))

    return hits    
