###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop_from_annot.py
###############################################################################
import typing
import pandas as pd
import numpy as np
from collections import Counter
from . import annotation as annot
from . import read_gff
from . import read_fa


def get_viral_prop_from_annot(fa_files: typing.List[typing.BinaryIO],
                                gff_files: typing.List[typing.BinaryIO]) \
    -> typing.List[typing.Dict[str, any]]: 
    data_list: typing.List[typing.Dict[str, any]] = []

    for i, _ in enumerate(gff_files):
        cat = fa_files[i].split("/")[-1][0:3]
        ori = fa_files[i].split("/")[-1][4:7]
        sample = gff_files[i].split("/")[-1].split(".")[0]
        contigs = read_fa.read_contigs(fa_files[i])
        annotations = read_gff.read_annotations(gff_files[i])
        for annot in annotations:
            contigs[annot.contig].add_covered_bases(annot)
        for contig in contigs.keys():
            contig_data = {'cat': cat, 'ori': ori, 'sample': sample,
                            'contig': contigs[contig].label,
                            'affil': contigs[contig].affil,
                            'freq': contigs[contig].spanned_by_prot}
            data_list.append(contig_data)
    return data_list
