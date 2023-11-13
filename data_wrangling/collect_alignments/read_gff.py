###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_gff.py
###############################################################################
import typing
import gzip
from . import contig
from . import protein


# read gzipped gff file of annotation and return a list of those annotations
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
            elif curr_line.startswith("##sequence-region"):
                contig_data = curr_line.split()
                contigs[contig_data[1]] = contig.Contig(contig_data[1],
                                                        contig_data[3])
            elif curr_line.startswith("#"):
                continue
            else:
                protein_data = curr_line.split()
                protein_label = protein_data[8].replace("=", ";").split(";")[1]
                proteins[protein_label] = protein.Protein(protein_label)
                proteins[protein_label].add_contig(contigs[protein_data[0]])
                proteins[protein_label].add_start_end(int(protein_data[3]),
                                                      int(protein_data[4]))

    return contigs, proteins

