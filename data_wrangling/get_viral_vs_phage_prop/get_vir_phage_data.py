###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       get_vir_phage_data.py
###############################################################################
import typing
import pandas as pd


# read an fa file of contigs and return a list of contigs of that fa file
def get_vir_phage_data(vir_prop: typing.TextIO, phage_predict: typing.TextIO) \
    -> pd.DataFrame:

    viral_df = pd.read_csv(vir_prop)
    phages = pd.read_csv(phage_predict)

    # inner join viral prop data with phage predictions
    result = viral_df.join(phages.set_index('Accession'),
                           on = 'contig', how = 'inner')
    result.set_index('contig', inplace=True)
    result = result[['freq', 'Pred', 'cat', 'ori', 'sample']]
    result['prokka_res'] = (result['freq'] != 0).astype(int)
    result['phabox_res'] = (result['Pred'] == 'phage').astype(int)

    return result
