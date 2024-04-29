###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_viral_vs_phage_prop.py
###############################################################################
import get_viral_vs_phage_prop as vvp


if __name__ == "__main__":
    # viral_prop = argv[1]
    # phage_predict = argv[2]
    # output_csv = argv[3]

    viral_prop = "/Users/aydinkaratas/Documents/research/project_coprolite_viromes_NOT_CODE/testing/pal-BEL_SRS510175_viral_prop_all.csv"
    phage_predict = "/Users/aydinkaratas/Documents/research/project_coprolite_viromes_NOT_CODE/testing/phamer_prediction.csv"
    output_csv = "/Users/aydinkaratas/Documents/research/project_coprolite_viromes_NOT_CODE/testing/test.csv"

    viral_vs_phage_df = vvp.get.get_vir_phage_data(viral_prop, phage_predict)
    viral_vs_phage_df.to_csv(output_csv)
