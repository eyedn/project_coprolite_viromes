###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       __init__.py
###############################################################################


"""Helpers for comparing viral and phage proportions."""

from . import combine_data
from . import combine_data as comb
from . import get_vir_phage_data
from . import get_vir_phage_data as get

__all__ = [
    "comb",
    "combine_data",
    "get",
    "get_vir_phage_data",
]
