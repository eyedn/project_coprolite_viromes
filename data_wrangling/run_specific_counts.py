###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       run_specific_counts.py 
###############################################################################
from sys import argv
import pandas as pd

# extract the raw gene and ec counts from an accession run
def run_specific_counts(annotations, gene_csv_path, ec_csv_path):
    # dictionaries to hold raw counts
    gene_counts = {}
    ec_counts = {}

    # read in annotation data
    df = pd.read_csv(annotations, delimiter='\t')

    # count raw occurances of each gene and ec
    for i, row in df.iterrows():
        # only record informative observations for genes
        gene = row["gene"]
        if not pd.isna(gene) and gene != "":
            try:
                gene_counts[gene] += 1
            except:
                gene_counts[gene] = 1
        # only record informative observations for ec
        ec = row["EC_number"]
        if not pd.isna(ec) and ec != "":
            try:
                ec_counts[ec] += 1
            except:
                ec_counts[ec] = 1

    # export counts df of gene counts to csv if informative information exists
    if len(gene_counts.keys()) != 0:
        gene_df = pd.DataFrame.from_dict(gene_counts, orient='index', columns=['count'])
        gene_df.to_csv(gene_csv_path, header=False)

    # export counts df of ec counts to csv if informative information exists
    if len(ec_counts.keys()) != 0:
        ec_df = pd.DataFrame.from_dict(ec_counts, orient='index', columns=['count'])
        ec_df.to_csv(ec_csv_path, header=False)

def main():
    # read in arguments
    prokka_annotations = argv[1]
    gene_counts_output = argv[2]
    ec_counts_output = argv[3]

    # create raw counts files
    run_specific_counts(prokka_annotations, gene_counts_output, ec_counts_output)

if __name__ == "__main__":
    main()
