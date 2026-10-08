# Full bacterial Prokka VFDB validation

Run from the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
Rscript tests/test_report_full_pool.R
```

The Python suite covers complete FAA/GFF inventories, independent annotation
flags and intersections, threshold boundaries, best-hit selection, non-hit
records, zero hits and denominators, invalid joins, search provenance, version
and trimming-filter isolation, biological skips, pooled reconciliation, and
preservation of source Prokka files.

The R smoke test renders the actual inline contig analysis and active CheckV
section against temporary synthetic data. It checks historical-table rejection,
version-specific outputs, retention of VFDB IDs without metadata, hypothetical
non-EC VF maps, and conservative-only CheckV exports. It uses three bootstrap
iterations. The unchanged Jenks block is omitted because BAMMtools is not
installed locally; a full production render still requires that dependency and
regenerated full-pool inputs.

## Hoffman2 evidence, 2026-10-08

Job `15104605` completed with `failed = 0` and `exit_status = 0`, using one
scheduler core and the actual HMMER 3.4 executable and both configured databases.
Complete existing bacterial Prokka inputs were read without modification.

| Input | All bacterial ORFs | Set A qualifying ORFs | Set B qualifying ORFs |
| --- | ---: | ---: | ---: |
| Contig sample `pal-ZAF_SRS4491531` | 14 | 1 | 1 |
| Conservative CheckV genome `pre-TZA_ERS9106184_k141_65577` | 285 | 2 | 3 |

The contig sample has 9 hypothetical and 2 EC-labeled ORFs; its qualifying hit
has no EC number. The CheckV genome has 265 hypothetical and 15 EC-labeled
ORFs; two qualifying hits are EC-labeled, so set B's third hit is non-EC.
The full CheckV bacterial FAA/GFF join was validated before selecting this
genome's complete ORF pool for the representative searches.

Logs, raw searches, manifests, and `validation_summary.json` remain under
`/u/scratch/a/ayd1n/vfdb_full_pool_validation_20261008/`. Job `15104436` also
verified zero-ORF handling and the CheckV searches with a successful exit.

The production deployment, full-dataset stages 3/4 and 3a/4a reruns, and
production report activation have not been performed. Stage 2 and its Prokka,
PhaBOX, and shared configuration files remain unchanged from the base checkout.
