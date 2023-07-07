###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       compile_raw_counts.py 
###############################################################################
import os
import pandas as pd
from sys import argv

def combine_all_raw_counts(directory, output_path):
    # get a list of all CSV files in the directory
    csv_files = [str(file) for file in os.listdir(directory) if file.endswith('.csv')]
    
    # create an empty dictionary to store the counts
    counts = {}
    
    # loop through each csv file and extract the counts
    for file in csv_files:
        # extract the sample name from the file name
        sample_name = ("_".join(file.split("_")[:-1])).replace("-", "_")

        # read the csv file into a df
        df = pd.read_csv(os.path.join(directory, file), header=None, names=['ec_number', sample_name])
        
        # set the 'ec_number' column as the index
        df.set_index('ec_number', inplace=True)
        
        # ddd the counts to the dictionary
        counts[sample_name] = df[sample_name]
    
    # combine the counts into a single DataFrame
    combined_df = pd.DataFrame(counts)
    
    # fill missing values with 0
    combined_df = combined_df.fillna(0)
    
    # # reset the index to include all EC numbers
    # combined_df.reset_index(inplace=True)
    
    # export combined counts to a new csv file
    combined_df.to_csv(output_path)

def main():
    # read in arguments
    raw_counts_dir = argv[1]
    all_counts_output_path = argv[2]

    # export the combined counts to a new csv file
    combine_all_raw_counts(raw_counts_dir, all_counts_output_path)

if __name__ == "__main__":
    main()