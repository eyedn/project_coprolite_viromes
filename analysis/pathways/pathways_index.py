###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		pathways_index.py
###############################################################################
import typing


class Pathways_Index:
    def __init__(self) -> None:
        self.index: typing.Dict[str, typing.List[str, int]] = {}

    def add_pathway(self, name, id) -> None:
        if id not in self.index:
            self.index[id] = [name, 1]
        else:
            self.index[id][1] += 1

    def process_pathway_str(self, pathways: str) -> typing.List[str]:
        id_list: typing.List[str] = []
        raw_list = pathways.strip().split(";")
        for pathway in raw_list:
            path_info = pathway.split(" ", 1)
            self.add_pathway(path_info[1], path_info[0])
            id_list.append(path_info[0])
        
        return id_list

    def print_pathways_by_rep(self) -> None:
        for pathway, _ in sorted(self.index.items(), key=lambda x: x[1][1], reverse = True):
            print(f"{pathway},{self.index[pathway][0]},{self.index[pathway][1]}")
