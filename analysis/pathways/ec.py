###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		ec.py
###############################################################################
import typing


class EC:
    def __init__(self, ec: str, name: str) -> None:
        self.ec = ec
        self.name = name
        self.pathway_ids: typing.List[str] = []

    def add_pathways(self, pathways_ids: typing.List[str]) -> None:
        self.pathway_ids = pathways_ids