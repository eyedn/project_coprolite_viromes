###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       format_database.py
###############################################################################
from sys import argv
import re
import gzip

# a viruence factor is obtain through the raw VFDB
class VF:
    def __init__(self, data):
        seq_id = data[0].split("(")[0][1:]
        self.seq_id = seq_id
        # product name will contain vf, vf ID, vf category, vf category id
        self.product = re.sub(r' - ', '_', data[1][:-1])
        self.product = re.sub(r' ', '_', self.product)
        self.product = re.sub(r'[^a-zA-Z0-9_]', '', self.product)
        self.sequence = ""

    def append_to_sequence(self, sequence):
        self.sequence = self.sequence + sequence

    def print_vf(self):
        print(f">{self.seq_id} {self.product}")
        print(self.sequence)

def read_database(db_file):
    vf = []
    with gzip.open(db_file, "rt") as f:
        for line in f.readlines():
            curr_line = line.strip()
            # lines that start with ">" contain are the contig label
            if curr_line.startswith(">"):
                line_data = curr_line.split("[")
                vf.append(VF(line_data))
            # line without ">" contain sequence info related to the current label
            else:
                vf[-1].append_to_sequence(curr_line)
    return vf

def print_formatted_database(database):
    for vf in database:
        vf.print_vf()

if __name__ == "__main__":
    unformatted_db = argv[1]
    my_vfs = read_database(unformatted_db)
    print_formatted_database(my_vfs)
