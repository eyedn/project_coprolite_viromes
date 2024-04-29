###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_vs_phage_prop.py
###############################################################################
import get_viral_vs_phage_prop as vvp
from sys import argv


if __name__ == "__main__":
    viral_prop = argv[1]
    phage_predict = argv[2]
    output_csv = argv[3]

    viral_vs_phage_df = vvp.get.get_vir_phage_data(viral_prop, phage_predict)
    viral_vs_phage_df.to_csv(output_csv)
