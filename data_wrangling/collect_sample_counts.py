###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       collect_sample_counts.py 
###############################################################################
from sys import argv
import pandas as pd
import glob

# combine raw counts form all accession runs under the same sample
def collect_sample_counts(directory, output_fname):
    # get a list of all CSV files in the directory
    csv_files = glob.glob(directory + '/*.csv')

    # check if no csv files are found
    if len(csv_files) == 0:
        return 
    
    # create an empty dataframe to hold the merged data
    merged_df = pd.DataFrame(columns=['label', 'count'])

    # loop through each csv file and merge with the existing dataframe
    for file in csv_files:
        df = pd.read_csv(file, header=None, names=['label', 'count'])
        # merge by 'label' column
        if not merged_df.empty:
            merged_df = pd.merge(merged_df, df, on='label', how='outer')
            # add counts together
            merged_df['count'] = merged_df[['count_x', 'count_y']].sum(axis=1, skipna=True)
            merged_df.drop(columns=['count_x', 'count_y'], inplace=True)
        else:
            merged_df = df.copy()

    # fill missing values with 0
    merged_df = merged_df.fillna(0)

    # export combined counts to csv file
    merged_df.to_csv(output_fname, index=False, header=False)

def main():
    # read in arguments
    sample_dir = argv[1]
    comb_counts_output = argv[2]

    # combine all raw counts for this sample
    collect_sample_counts(sample_dir, comb_counts_output)

if __name__ == "__main__":
    main()
