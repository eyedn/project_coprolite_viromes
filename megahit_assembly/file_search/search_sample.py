###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		search_directory.py
###############################################################################
import os
import typing
from . import search_acc_id as search


# look through the sample directory to get all fastq files
def search_sample(dir: typing.Union[str, os.PathLike]) \
    -> typing.Tuple[typing.List[typing.Union[str, os.PathLike]], 
                    typing.List[typing.Union[str, os.PathLike]], 
                    typing.List[typing.Union[str, os.PathLike]]]:
    all_single_data: typing.List[typing.Union[str, os.PathLike]] = []
    all_paired_data_1: typing.List[typing.Union[str, os.PathLike]] = []
    all_paired_data_2: typing.List[typing.Union[str, os.PathLike]] = []
    # find all trimmed fastq files
    for sub_dir in os.listdir(dir):
        sub_dir_path = os.path.join(dir, sub_dir)
        new_single, new_paired_1, new_paired_2 = search.get_file_names(sub_dir_path)
        if new_single != "":
            all_single_data.append(new_single)
        if new_paired_1 != "":
            all_paired_data_1.append(new_paired_1)
        if new_paired_2 != "":
            all_paired_data_2.append(new_paired_2)
    return all_single_data, all_paired_data_1, all_paired_data_2
