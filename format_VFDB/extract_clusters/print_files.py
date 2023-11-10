###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       print_files.py
###############################################################################
import typing
import os
from . import protein


def print_files(clusters: typing.Dict[str, typing.List[protein.Protein]],
    output_dir: os.path) -> typing.List[str]:

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    paths: typing.List[str] = []

    for clus in clusters:
        file = os.path.join(output_dir, f"{clus}.fas")
        paths.append(file)
        with open(file, "w") as f:
            for protein in clusters[clus]:
                f.write(f"{protein.label}\n")
                f.write(f"{protein.sequence}\n")

    return paths