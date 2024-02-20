###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       print_path_list.py
###############################################################################


def print_path_list(cluster_files, list_file):
    
    with open(list_file, 'w') as f:
        for path in cluster_files:
            f.write(f"{path}\n")