###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       read_results.py
###############################################################################
import typing
from . import hit
from . import protein


def read_results(results_file: typing.TextIO, 
    proteins: typing.Dict[str, protein.Protein],
    hits: typing.Dict[str, hit.Hit], eval: float) -> None:

    with open(results_file) as f:
        curr_hit = ""
        # counts how many lines to relavent info when a hit is identified
        lines_to_info = -1
        # monitors if a protein domain alignment is currently identified
        domain = False

        # if-else follows naming conventions in results file to find info
        for line in f.readlines():
            curr_line = line.strip()
            if lines_to_info > 0:
                lines_to_info -= 1
            elif curr_line.startswith("#") or len(curr_line) == 0:
                lines_to_info = -1
                domain = False
            # hit identified
            elif curr_line.startswith("Query:"):
                curr_hit = curr_line.split()[1]
                if curr_hit not in hits.keys():
                    curr_hit = ""
                    continue
            # protein of current hit identified
            elif curr_line.startswith(">>") and len(curr_hit) > 0:
                curr_protein = curr_line.split()[1]
                if curr_protein not in hits[curr_hit].queries:
                    lines_to_info = -1
                    domain = False
                    continue
                domain = True
                lines_to_info = 2
            # add aligned bases to protein and covered bases to protein contig
            elif domain and lines_to_info == 0:
                hit_result = curr_line.split()
                if float(hit_result[4]) > eval:
                    continue
                aln_start = int(hit_result[9])
                aln_end = int(hit_result[10])
                proteins[curr_protein].add_aligned_bases(aln_start, aln_end)
                proteins[curr_protein].contig.add_covered_bases(
                    proteins[curr_protein].get_start_to_end()
                    )
