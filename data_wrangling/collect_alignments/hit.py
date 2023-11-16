###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       hit.py
###############################################################################
import typing


# hit objects are proteins in a data base
class Hit:
    def __init__(self, label) -> None:
        self.label: str = label
        self.queries: typing.List[str] = []
        self.evals: typing.List[float] = []

    # queries are proteins that aligned to this hit
    def add_query(self, query, eval) -> None:
        self.queries.append(query)
        self.evals.append(eval)
