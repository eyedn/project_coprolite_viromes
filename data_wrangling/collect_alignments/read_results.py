###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_table.py
###############################################################################
import typing
import numpy as np
from hit import Hit
from protein import Protein

def read_results(hits_file: typing.TextIO, proteins_file: typing.TextIO,
    hit_labels: typing.List[str], hits_list: typing.List[Hit]) -> None:
    hit_counter = -1
    protein_labels: typing.List[str] = []
    proteins: typing.List[Protein] = []
    with open(hits_file) as h:
        with open(proteins_file) as p:
            hits_lines = h.readlines()
            for i, h_line in enumerate(hits_lines):
                hit_data = h_line.strip().replace(":", "\t").split()
                if hit_data[2] not in hit_labels:
                    continue

                try:
                    next_hit_data = hits_lines[i+1].strip().replace(":", "\t").split()
                except:
                    next_hit_data = [np.inf]
                hit_counter += 1

                lines_per_protein, inspect_protein = 4, True
                for p_line in p.readlines():
                    if lines_per_protein < 0:
                        lines_per_protein, inspect_protein = 4, True
                    elif not inspect_protein:
                        lines_per_protein -= 1
                        continue

                    if lines_per_protein == 4:
                        protein_data = p_line.strip().replace(":>>", "\t").split()
                        if int(protein_data[0]) < int(hit_data[0]) or \
                            int(protein_data[0]) >= int(next_hit_data[0]):
                            continue
                        if protein_data[1] not in hits_list[hit_counter].queries:
                            inspect_protein = False
                        protein_label = protein_data[1]
                    elif lines_per_protein == 1:
                        protein_data = p_line.strip().split()
                        proteins.append(Protein(protein_label))
                        proteins[-1].add_aligned_bases(int(protein_data[10]),
                                                       int(protein_data[11]))
                        protein_labels.append(protein_label)
                    lines_per_protein -= 1
    return protein_labels, proteins  
