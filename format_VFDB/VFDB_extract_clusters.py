from Bio import SeqIO
import os


def extract_clusters(fasta_file, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    clusters = {}
    cluster_files = []

    # Read the FASTA file and group sequences by cluster ID
    for record in SeqIO.parse(fasta_file, "fasta"):
        description_parts = record.description.split('[')
        for part in description_parts:
            if part.startswith('Phospholipase'):
                cluster_id = part.split('(')[1].split(')')[0]  # Extracts the cluster ID
                if cluster_id not in clusters:
                    clusters[cluster_id] = []
                clusters[cluster_id].append(record)
                break

    # Write sequences to separate FASTA files based on cluster ID
    for cluster_id, records in clusters.items():
        cluster_file = os.path.join(output_dir, f"{cluster_id}.fasta")
        SeqIO.write(records, cluster_file, "fasta")
        cluster_files.append(cluster_file)

    return cluster_files

def write_cluster_file_list(cluster_files, list_file):
    with open(list_file, 'w') as f:
        for path in cluster_files:
            f.write(path + '\n')

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        print("Usage: python extract_clusters.py <fasta_file> <output_directory> <cluster_file_list>")
    else:
        fasta_file, output_dir, cluster_file_list = sys.argv[1], sys.argv[2], sys.argv[3]
        cluster_files = extract_clusters(fasta_file, output_dir)
        write_cluster_file_list(cluster_files, cluster_file_list)
        print(f"Cluster file paths written to {cluster_file_list}")
