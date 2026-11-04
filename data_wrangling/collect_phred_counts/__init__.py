###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       __init__.py
###############################################################################


"""Helpers for collecting Phred quality counts."""

from . import get_counts
from . import get_counts as get
from . import search_files
from . import search_files as search

__all__ = [
    "get",
    "get_counts",
    "search",
    "search_files",
]
