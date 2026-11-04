###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       read_search_inputs.py
###############################################################################


"""Read plain or compressed search inputs without altering Prokka outputs."""
import gzip
from pathlib import Path


def read_search_inputs(path):
    path = Path(path)
    if not path.is_file():
        path = Path(str(path) + ".gz")
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rb") as handle:
        return handle.read()
