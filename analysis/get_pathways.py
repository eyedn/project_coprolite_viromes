###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_pathways.py
###############################################################################
from sys import argv
import pathways as pw


if __name__ == "__main__":
    # diff_repres_ec_file = argv[1]
    diff_repres_ec_file = "../data/diff_repress_bacterial_ec.csv"
    pathway_index, ecs = pw.read.read_diff_repress(diff_repres_ec_file)
    ecs_with_pathway = pw.get.get_ec_with_pathway(ecs)
    # print(f"Number of EC with KEGG pathway: {len(ecs_with_pathway)}")
    # with open("../data/diff_repress_bacterial_ec_meta.csv", "w") as f:
    #     for ec in ecs_with_pathway:
    #         pathways = ",".join(ec.pathway_ids)
    #         f.write(f"\"{ec.ec}\",\"{pathways}\"\n")
    pathway_index.print_pathways_by_rep()
