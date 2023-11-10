###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       protein.py
###############################################################################


class Protein:
    def __init__(self, label: str) -> None:
        self.label = label
        self.sequence = ""
    def append_sequence(self, sequence: str):
        self.sequence += sequence