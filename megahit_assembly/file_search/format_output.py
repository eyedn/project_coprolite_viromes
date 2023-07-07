###############################################################################
#       Aydin Karatas
#		Project Coprolite Viromes
#		format_output.py
###############################################################################
import os
import typing


# same-type data is comma-separated; different type data is space-separated
def format_output(single_end: typing.List[typing.Union[str, os.PathLike]], 
                    paired_end_1: typing.List[typing.Union[str, os.PathLike]], 
                    paired_end_2: typing.List[typing.Union[str, os.PathLike]]) \
    -> str:
    if single_end:
        single_string = ",".join(single_end)
    else:
        single_string = "no_data"
    if paired_end_1:
        paired_1_string = ",".join(paired_end_1)
    else:
        paired_1_string = "no_data"
    if paired_end_2:
        paired_2_string = ",".join(paired_end_2)
    else:
        paired_2_string = "no_data"
    return f"{single_string}\t{paired_1_string}\t{paired_2_string}"
