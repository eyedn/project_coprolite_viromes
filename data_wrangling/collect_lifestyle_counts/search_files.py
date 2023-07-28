###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       search_files.py
###############################################################################
import typing
import get_lifestyle_counts as get


def get_counts_dict(files: typing.List[typing.Union[str, typing.BinaryIO]]) \
    -> typing.Dict[str, typing.Dict[str, int]]:
    counts: typing.Dict[str, typing.Dict[str, int]] = {}
    for file in files:
        # format sample name
        sample_name = file.strip().split("/")[-2]
        sample_name = sample_name.split("_")[:-2]
        sample_name = '_'.join(sample_name)
        # create counts dict for each sample; add it to the main counts dict
        sample_counts = get.get_lifestyle_counts(file)
        counts[sample_name] = sample_counts
    return counts
