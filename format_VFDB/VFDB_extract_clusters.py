import os


def split_clusters(cluster_file, sequence_file, output_dir):
    clusters = {}
    with open(cluster_file, 'r') as clstr_file:
        cluster_id = ""
        for line in clstr_file:
            if line.startswith(">"):
                cluster_id = line.strip().replace(">", "")
                clusters[cluster_id] = []
            else:
                sequence_id = line.split(">")[1].split("...")[0]
                clusters[cluster_id].append(sequence_id.strip())

    sequences = {}
    with open(sequence_file, 'r') as seq_file:
        for line in seq_file:
            if line.startswith(">"):
                seq_id = line.strip().replace(">", "")
                sequences[seq_id] = line
            else:
                sequences[seq_id] += line

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for cluster_id, members in clusters.items():
        with open(os.path.join(output_dir, f"cluster_{cluster_id}.fasta"), 'w') as out_file:
            for seq_id in members:
                out_file.write(sequences[seq_id])

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 4:
        print("Usage: python split_cdhit_clusters.py <cluster_file.clstr> <original_sequence_file.fasta> <output_directory>")
    else:
        split_clusters(sys.argv[1], sys.argv[2], sys.argv[3])

