###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop_from_annot.py
###############################################################################
from . import annotation as annot
from . import read_gff
from . import read_fa
import typing
import pandas as pd
import numpy as np
from collections import Counter


def get_viral_prop_from_annot(fa_file: typing.Union[str, typing.BinaryIO],
                                gff_file: typing.Union[str, typing.BinaryIO]) \
    -> typing.List[typing.Dict[str, any]]: 
    data_list: typing.List[typing.Dict[str, any]] = []
    cat = fa_file.split("/")[-1][0:3]
    ori = fa_file.split("/")[-1][4:7]
    sample = gff_file.split("/")[-1].split(".")[0]
    contigs = read_fa.read_contigs(fa_file)
    annotations = read_gff.read_annotations(gff_file)
    for annot in annotations:
        contigs[annot.contig].add_covered_bases(annot)
    for contig in contigs.keys():
        contig_data = {'cat': cat, 'ori': ori, 'sample': sample,
                        'contig': contigs[contig].label,
                        'freq': contigs[contig].spanned_by_prot,
                        'len': contigs[contig].len}
        data_list.append(contig_data)
    return data_list
