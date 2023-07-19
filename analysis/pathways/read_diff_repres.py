###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		read_diff_repress.py
###############################################################################
import typing
import pandas as pd
from . import pathways_index as pi
from . import ec


def read_diff_repress(file: typing.TextIO) \
    -> typing.Tuple[pi.Pathways_Index, typing.List[ec.EC]]:
    index = pi.Pathways_Index()
    ecs: typing.List[ec.EC] = []

    ec_df = pd.read_csv(file)
    ec_df = ec_df.iloc[:, :4]

    for i, row in ec_df.iterrows():
        new_ec = ec.EC(row.iloc[0], row.iloc[2])
        if not pd.isnull(row.iloc[3]):
            new_ec.add_pathways(index.process_pathway_str(row.iloc[3], new_ec.ec))
        ecs.append(new_ec)
    
    return index, ecs
