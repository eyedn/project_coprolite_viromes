###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_prop_from_annot.py
###############################################################################
import typing
from collections import Counter
from . import annotation as annot
from . import read_gff
from . import read_fa


def get_viral_prop_from_annot(fa_files: typing.List[typing.BinaryIO],
                                gff_files: typing.List[typing.BinaryIO]) \
    -> None: 

    freq: typing.List[float] = []
    for i, file in enumerate(gff_files):
        contigs = read_fa.read_contigs(fa_files[i])
        annotations = read_gff.read_annotations(file)
        for annot_contig in annotations.keys():
            contigs[annot_contig].add_covered_bases(annotations[annot_contig])
        for contig in contigs.keys():
            contigs[contig].proportion_contig_spanned()
            freq.append(contigs[contig].spanned_by_prot)
    
    return freq
