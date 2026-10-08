###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       search_vfdb.py
###############################################################################
"""Search the complete bacterial FAA with validated, atomic cached outputs."""
import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path

from python_utils.read_bacterial_orfs import read_bacterial_orfs
from python_utils.read_search_inputs import read_search_inputs
from python_utils.validate_vf_search import validate_vf_search
from python_utils.vfdb_constants import ORF_POOL, VFDB_DATABASES


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("faa", type=Path)
    parser.add_argument("gff", type=Path)
    parser.add_argument("database", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("version", choices=VFDB_DATABASES)
    parser.add_argument("cores")
    parser.add_argument("hmmsearch")
    args = parser.parse_args()
    if args.database.name != VFDB_DATABASES[args.version]:
        raise ValueError("VFDB database/version mismatch")
    database_bytes = read_search_inputs(args.database)
    if not database_bytes.strip():
        raise ValueError("empty VFDB profile database")
    search_scope = (args.output.parent.parent.name
                    if args.output.parent.name == "vf_alignment_all_orfs"
                    else args.output.name)
    _, _, rows = read_bacterial_orfs(args.gff, args.faa, "search")
    ids = {row["orf_id"] for row in rows}
    if args.output.exists() and any(args.output.iterdir()):
        validate_vf_search(args.output, args.version, args.faa, ids,
                           args.database)
        print(f"Complete cached full-pool search: {args.output}")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=args.output.parent) as temporary:
        work = Path(temporary)
        faa = read_search_inputs(args.faa)
        (work / "proteins.faa").write_bytes(faa)
        if ids:
            subprocess.run([
                args.hmmsearch, "-o", str(work / "results.txt"),
                "--tblout", str(work / "table.txt"), "--cpu", args.cores,
                "--incE", "1e-5", str(args.database),
                str(work / "proteins.faa"),
            ], check=True)
        else:
            for name in ("results.txt", "table.txt"):
                (work / name).write_text("# Zero bacterial proteins\n# [ok]\n")
        manifest = {
            "vfdb_version": args.version, "orf_pool": ORF_POOL,
            "database": args.database.name, "protein_count": len(ids),
            "search_scope": search_scope,
            "faa_sha256": hashlib.sha256(faa).hexdigest(),
            "database_sha256": hashlib.sha256(
                database_bytes).hexdigest(),
        }
        (work / "search_manifest.json").write_text(json.dumps(manifest))
        validate_vf_search(work, args.version, args.faa, ids, args.database,
                           search_scope=search_scope)
        args.output.mkdir(exist_ok=True)
        for name in ("table.txt", "results.txt", "search_manifest.json"):
            os.replace(work / name, args.output / name)


if __name__ == "__main__":
    main()
