import typing
import os
from sys import argv


class Protein:
    def __init__(self, label) -> None:
        self.label = label
        self.sequence = ""
    def append_sequence(self, sequence):
        self.sequence += sequence


def get_clusters_dict(fasta_file: os.path) \
    -> typing.Dict[str, typing.List[Protein]]:

    clusters: typing.Dict[str, typing.List[Protein]] = {}
    with open(fasta_file, "r") as f:
        for line in f.readlines():
            if line.startswith(">"):
                label = line.strip()
                clus = label.split(") - ")[0].split("(")[-1]
                if clus not in clusters:
                    clusters[clus] = []
                clusters[clus].append(Protein(label))
            else:
                clusters[clus][-1].append_sequence(line.strip())
    return clusters

def print_cluster_files(clusters: typing.Dict[str, typing.List[Protein]],
                        output_dir: os.path) -> typing.List[str]:

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    paths: typing.List[str] = []

    for clus in clusters:
        file = os.path.join(output_dir, f"{clus}.fasta")
        paths.append(file)
        with open(file, "w") as f:
            for protein in clusters[clus]:
                f.write(protein.label)
                f.write(f"{protein.sequence}\n")

    return paths

def write_cluster_file_list(cluster_files, list_file):
    with open(list_file, 'w') as f:
        for path in cluster_files:
            f.write(f"{path}\n")


if __name__ == "__main__":
    if len(argv) != 4:
        print("Usage: python extract_clusters.py <fasta_file> <output_directory> <cluster_file_list>")
    else:
        fasta_file, output_dir, cluster_file_list = argv[1], argv[2], argv[3]
        my_protein_clusters = get_clusters_dict(fasta_file)
        my_cluster_file_paths = print_cluster_files(my_protein_clusters, output_dir)
        write_cluster_file_list(my_cluster_file_paths, cluster_file_list)
