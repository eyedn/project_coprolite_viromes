###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		combine_viral_vs_phage_prop.py
###############################################################################
import get_viral_vs_phage_prop as vvp
from sys import argv


if __name__ == "__main__":
    viral_prop_dir = argv[1]
    output_csv = argv[2]

    viral_vs_phage_df = vvp.comb.combine_data(viral_prop_dir)
    viral_vs_phage_df.to_csv(output_csv)
