###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       hit.py
###############################################################################
import typing


# annotations are obtained fom a gff file after annotation
class Hit:
    def __init__(self, label) -> None:
        self.label: str = label
        self.queries: typing.List[str] = []
        self.evals: typing.List[float] = []

    def add_query(self, query, eval) -> None:
        self.queries.append(query)
        self.evals.append(eval)
