###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       validate_vf_search.py
###############################################################################
"""Reject partial, stale, wrong-version, and restricted-pool searches."""
import hashlib
import json
from pathlib import Path

from .read_search_inputs import read_search_inputs
from .vfdb_constants import ORF_POOL, VFDB_DATABASES
from .collect_checkv_genome_stats_utils.parse_hmmer_lines import (
    parse_hmmer_lines,
)
from .collect_checkv_genome_stats_utils.select_best_vf_hits import (
    select_best_vf_hits,
)


def validate_vf_search(directory, version, faa_path, protein_ids, db_path=None,
                       search_scope=None):
    directory = Path(directory)
    if search_scope is None:
        search_scope = (directory.parent.parent.name
                        if directory.parent.name == "vf_alignment_all_orfs"
                        else directory.name)
    with (directory / "search_manifest.json").open() as handle:
        manifest = json.load(handle)
    if (manifest.get("search_scope") != search_scope
            or manifest.get("vfdb_version") != version
            or manifest.get("orf_pool") != ORF_POOL
            or manifest.get("database") != VFDB_DATABASES[version]
            or manifest.get("protein_count") != len(protein_ids)
            or manifest.get("faa_sha256") != hashlib.sha256(
                read_search_inputs(faa_path)).hexdigest()):
        raise ValueError(f"stale or incompatible VFDB search: {directory}")
    if db_path is not None and manifest.get("database_sha256") != (
            hashlib.sha256(read_search_inputs(db_path)).hexdigest()):
        raise ValueError(f"changed VFDB database: {directory}")
    outputs = []
    for name in ("table.txt", "results.txt"):
        text = (directory / name).read_text()
        if not text.strip() or not text.rstrip().endswith("[ok]"):
            raise ValueError(f"incomplete HMMER output: {directory / name}")
        outputs.append(text)
    hits = parse_hmmer_lines(outputs[0].splitlines())
    # Validate all targets, including rows below the qualifying thresholds.
    select_best_vf_hits(hits, protein_ids)
    return hits
