###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_gff.py
###############################################################################
import typing
import gzip
from . import contig
from . import protein


# read gff file to produce dictionaries of proteins and contigs
def read_gff(gff_file: typing.BinaryIO) \
    -> typing.Tuple[typing.Dict[str, contig.Contig],
        typing.Dict[str, protein.Protein]]:

    contigs: typing.Dict[str, contig.Contig] = {}
    proteins: typing.Dict[str, protein.Protein] = {}

    with gzip.open(gff_file, "rt") as f:
        for line in f.readlines():
            curr_line = str(line.strip())

            if curr_line.startswith(">") or curr_line == "##FASTA":
                break
            # "##sequence-region" defines names of contigs
            elif curr_line.startswith("##sequence-region"):
                contig_data = curr_line.split()
                # contig_data[0] == label; [1] == contig length
                contigs[contig_data[1]] = contig.Contig(contig_data[1],
                                                        int(contig_data[3]))
            elif curr_line.startswith("#"):
                continue
            else:
                protein_data = curr_line.split()
                protein_label = protein_data[8].replace("=", ";").split(";")[1]
                proteins[protein_label] = protein.Protein(protein_label)
                # protein_data[0] == ass. contig
                # [3], [4] == start and end base on contig
                proteins[protein_label].add_contig(contigs[protein_data[0]])
                proteins[protein_label].add_start_end(int(protein_data[3]),
                                                      int(protein_data[4]))

    return contigs, proteins

