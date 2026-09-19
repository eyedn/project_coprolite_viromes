###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       get_alignment_counts.py
###############################################################################
import collect_alignments as ca
from sys import argv


if __name__ == "__main__":
    alignment_path, annotation_path, output_dir, output_prefix = \
        argv[1], argv[2], argv[3], argv[4]
    eval = 1e-5

    counts, contig_hits = ca.get_align_info.get_align_info(
        alignment_path, annotation_path, eval
        )
    
    counts_output = argv[5] if len(argv) > 5 \
        else f"{output_dir}/{output_prefix}_counts.csv"
    contig_hits_output = argv[6] if len(argv) > 6 \
        else f"{output_dir}/{output_prefix}_contig_hits.csv"

    counts.to_csv(counts_output)
    contig_hits.to_csv(contig_hits_output)
