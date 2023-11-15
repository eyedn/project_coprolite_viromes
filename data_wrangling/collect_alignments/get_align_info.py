###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       get_align_info.py
###############################################################################
import typing
import pandas as pd
from glob import glob
from . import read_table, read_gff, read_results
from . import update_counts_df, update_contig_hits_dict


def get_align_info(alignment_path: str, annotations_path: str, eval: float) \
    -> typing.Tuple[pd.DataFrame, pd.DataFrame]:

    contigs_hits_dict: typing.Dict[str, typing.List[int]] = {}
    counts_dict: typing.Dict[str, typing.Dict[str, int]] = {}

    alignment_path = alignment_path.replace("!", "**")
    for align_path in glob(alignment_path, recursive = True):
        label = "_".join(align_path.split("/")[-1].split("_")[:-1])
        print(align_path)
        print(label, end = " ")
        table_txt = f"{align_path}/table.txt"
        results_txt = f"{align_path}/results.txt"
        sample_annotations_path = annotations_path.replace("!", label)
        gff_gz = f"{sample_annotations_path}/{label[8:]}.gff.gz"

        curr_contigs, proteins = read_gff.read_gff(gff_gz)
        hits = read_table.read_table(table_txt, eval)
        read_results.read_results(results_txt, proteins, hits, eval)
        
        counts_dict = update_counts_df.update_counts_df(label, hits,
                                                        counts_dict)
        contigs_hits_dict = update_contig_hits_dict.update_contig_hits_dict(
            label, curr_contigs, contigs_hits_dict)
        print(counts_dict)
        print(contigs_hits_dict)

    counts_df = pd.DataFrame(counts_dict)
    counts_df = counts_df.fillna(0)
    contigs_hits_df = pd.DataFrame(contigs_hits_dict)
    contigs_hits_df = contigs_hits_df.fillna(0)

    return counts_df, contigs_hits_df
