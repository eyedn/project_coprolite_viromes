###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_ec_w_pathway.py
###############################################################################
import typing
from . import ec


def get_ec_with_pathway(ec_list: typing.List[ec.EC]) -> typing.List[ec.EC]:
    ec_with_pathway: typing.List[ec.EC] = []
    
    for ec in ec_list:
        if len(ec.pathway_ids) > 0:
            ec_with_pathway.append(ec)

    return ec_with_pathway
