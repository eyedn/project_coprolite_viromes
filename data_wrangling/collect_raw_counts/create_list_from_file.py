###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       create_list_from_file.py
###############################################################################
import typing


# given a file, create a list where each line of the file is an item
def create_list(list_file: typing.TextIO) \
    -> typing.List[typing.Union[str, typing.BinaryIO]]:
    items: typing.List[typing.Union[str, typing.BinaryIO]] = []
    with open(list_file, "r"):
        for line in list_file.readlines():
            items.append(line.strip())
    return items
