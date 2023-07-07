###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		get_file_names.py
###############################################################################
import os
import typing


# return all paired-end and single end data from a given accession run
def get_file_names(fastq_dir: typing.Union[str, os.PathLike]) \
    -> typing.Tuple[typing.List[typing.Union[str, os.PathLike]], 
                    typing.List[typing.Union[str, os.PathLike]], 
                    typing.List[typing.Union[str, os.PathLike]]]:
    my_single_data = ""
    my_paired_data_1 = ""
    my_paired_data_2 = ""
    for file in os.listdir(os.path.join(fastq_dir)):
        if str(file).endswith("fq.gz"):
            file_path = os.path.join(fastq_dir, file)
            # type of data can be identified by what the file name ends in
            if str(file).endswith("trimmed.fq.gz"):
                my_single_data = file_path
            elif str(file).endswith("1.fq.gz"):
                my_paired_data_1 = file_path
            elif str(file).endswith("2.fq.gz"):
                my_paired_data_2 = file_path
    return my_single_data, my_paired_data_1, my_paired_data_2
