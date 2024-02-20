###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       VFDB_extract_clusters.py
###############################################################################
from extract_clusters import get_cluster_dict, print_files, print_path_list
from sys import argv


if __name__ == "__main__":
    fasta_file, output_dir, cluster_file_list = argv[1], argv[2], argv[3]
    my_protein_clusters = get_cluster_dict.get_clusters_dict(fasta_file)
    my_cluster_file_paths = print_files.print_files(my_protein_clusters, output_dir)
    print_path_list.print_path_list(my_cluster_file_paths, cluster_file_list)
