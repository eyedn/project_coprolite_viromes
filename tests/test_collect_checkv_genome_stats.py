###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       test_collect_checkv_genome_stats.py
###############################################################################
"""Focused tests for complete CheckV-genome collection contracts."""

import csv
import gzip
import importlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_DIR / "data_wrangling"))


class CheckvCoreTest(unittest.TestCase):
    """Exercise pure identifier, metadata, annotation, and hit logic."""

    @classmethod
    def setUpClass(cls):
        cls.utils = importlib.import_module(
            "python_utils.collect_checkv_genome_stats_utils"
        )
        cls.prepare = importlib.import_module(
            "python_utils.prepare_checkv_prokka_utils"
        )

    def test_exact_and_unique_longest_prefix_mapping(self):
        match = self.utils.match_checkv_contig
        self.assertEqual(match("g1", ["g1", "g"]), "g1")
        self.assertEqual(match("g1_1", ["g", "g1"]), "g1")
        with self.assertRaisesRegex(ValueError, "no CheckV contig"):
            match("missing_1", ["g1"])
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            match("g1_1", ["g1", "g1"])

    def test_manifest_metadata_and_source_validation(self):
        sample_index = self.utils.build_sample_index({
            "ind-CHN": ["NLF015"],
            "pal-BMS": ["UT30.3"],
        })
        metadata = self.utils.parse_genome_metadata(
            "ind-CHN_NLF015_k99_39404_1", sample_index
        )
        self.assertEqual(
            metadata,
            {"category": "ind", "origin": "CHN", "sample": "NLF015"},
        )
        self.utils.validate_checkv_source("ind", "ind")
        with self.assertRaisesRegex(ValueError, "Source"):
            self.utils.validate_checkv_source("pal", "ind")

    def test_normal_and_merged_checkv_headers(self):
        normal = [
            "contig_id\tcontig_length\twarnings\tLifestyle\tSource\n",
            "g1\t100\tnone\tTemperate\tind\n",
        ]
        merged = [
            "contig_id\tcontig_length\twarningsLifestyle\tSource\n",
            "g1\t100\tnone\tTemperate\tind\n",
        ]
        normal_rows = self.utils.parse_checkv_lines(normal)
        merged_rows = self.utils.parse_checkv_lines(merged)
        self.assertEqual(normal_rows[0]["Lifestyle"], "Temperate")
        self.assertEqual(merged_rows[0]["warnings"], "none")
        self.assertEqual(merged_rows[0]["Lifestyle"], "Temperate")
        with self.assertRaisesRegex(ValueError, "duplicate CheckV"):
            self.utils.parse_checkv_lines(normal + normal[1:])

    def test_prokka_eligibility_requires_ec_and_real_product(self):
        lines = [
            "##gff-version 3\n",
            "##sequence-region g1 1 100\n",
            "g1\tProkka\tCDS\t1\t30\t.\t+\t0\t"
            "ID=orf1;product=enzyme;eC_number=1.2.3.4\n",
            "g1\tProkka\tCDS\t31\t60\t.\t-\t0\t"
            "ID=orf2;product=hypothetical protein;eC_number=2.3.4.5\n",
            "g1\tProkka\tCDS\t61\t90\t.\t+\t0\t"
            "ID=orf3;product=enzyme\n",
        ]
        features = self.prepare.parse_valid_gff_features(lines)
        self.assertEqual([row["feature_id"] for row in features], ["orf1"])
        self.assertEqual(features[0]["ec_number"], "1.2.3.4")

    def test_vf_thresholds_and_deterministic_best_hit(self):
        rows = [
            self._hit("orf1", "VF_B", "1e-20", "50", "1"),
            self._hit("orf1", "VF_A", "1e-20", "50", "1"),
            self._hit("orf2", "VF_C", "1e-9", "80", "1"),
            self._hit("orf3", "VF_D", "1e-20", "24", "1"),
            self._hit("orf4", "VF_E", "1e-20", "50", "6"),
            self._hit("not_eligible", "VF_F", "1e-20", "80", "1"),
        ]
        hits = self.utils.select_best_vf_hits(rows, {"orf1", "orf2"})
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0]["query_name"], "VF_A")

    def test_phabox_formats_and_duplicate_records(self):
        legacy_rows = [{
            "Accession": "g1",
            "Lineage": "Viruses;Caudoviricetes",
            "Family": "Siphoviridae",
            "Score": "0.7",
            "Genus": "G1",
            "Genus_cluster": "GC1",
        }]
        legacy = self.utils.parse_phagcn_rows(
            legacy_rows,
            list(legacy_rows[0]),
        )
        self.assertEqual(legacy["g1"]["family"], "Siphoviridae")
        current_rows = [{
            "Accession": "g2",
            "Length": "100",
            "Lineage": "class:Caudoviricetes;family:Myoviridae",
            "PhaGCNScore": "0.9;0.8",
            "Genus": "-",
            "GenusCluster": "group_1",
        }]
        current = self.utils.parse_phagcn_rows(
            current_rows,
            list(current_rows[0]),
        )
        self.assertEqual(current["g2"]["family"], "Myoviridae")
        self.assertEqual(current["g2"]["family_score"], "0.8")
        with self.assertRaisesRegex(ValueError, "duplicate PhaGCN"):
            self.utils.parse_phagcn_rows(
                current_rows * 2,
                list(current_rows[0]),
            )

        phatyp_rows = [{"Contig": "g1", "Pred": "virulent"}] * 2
        with self.assertRaisesRegex(ValueError, "duplicate PhaTYP"):
            self.utils.parse_phatyp_rows(phatyp_rows, ["Contig", "Pred"])

    def test_duplicate_prokka_feature_fails(self):
        lines = [
            "g1\tProkka\tCDS\t1\t3\t.\t+\t0\t"
            "ID=orf1;product=enzyme;eC_number=1.2.3.4\n",
        ] * 2
        with self.assertRaisesRegex(ValueError, "duplicate Prokka"):
            self.prepare.parse_valid_gff_features(lines)

    @staticmethod
    def _hit(target, query, evalue, score, bias):
        return {
            "target_name": target,
            "query_name": query,
            "full_seq_evalue": evalue,
            "full_seq_score": score,
            "full_seq_bias": bias,
            "description": query + " description",
        }


class CheckvCollectorIntegrationTest(unittest.TestCase):
    """Run the collector against both filters and validate output semantics."""

    def test_both_filters_zero_denominator_and_zero_hit_genomes(self):
        with tempfile.TemporaryDirectory() as temporary_dir:
            project_dir = Path(temporary_dir)
            (project_dir / "data").mkdir()
            samples_dir = project_dir / "samples"
            samples_dir.mkdir()
            (samples_dir / "ind-CHN_samples.txt").write_text(
                "NLF015 SRR1\n", encoding="utf-8"
            )

            for checkv_filter in ("conservative", "aggressive"):
                self._write_filter(project_dir, checkv_filter)

            subprocess.run(
                [
                    sys.executable,
                    str(
                        REPO_DIR
                        / "data_wrangling/collect_checkv_genome_stats.py"
                    ),
                    str(project_dir),
                ],
                check=True,
            )

            metadata = self._read_csv(
                project_dir / "data/checkv_genome_metadata.csv"
            )
            stats = self._read_csv(
                project_dir / "data/checkv_genome_vf_stats.csv"
            )
            features = self._read_csv(
                project_dir / "data/checkv_genome_features.csv"
            )
            hits = self._read_csv(
                project_dir / "data/checkv_genome_vf_hits.csv"
            )

            self.assertEqual(len(metadata), 6)
            self.assertEqual(
                {(row["checkv_filter"], row["genome_id"]) for row in metadata},
                {
                    ("conservative", "ind-CHN_NLF015_k99_39404_1"),
                    ("conservative", "ind-CHN_NLF015_k99_50000"),
                    ("conservative", "ind-CHN_NLF015_k99_60000"),
                    ("aggressive", "ind-CHN_NLF015_k99_39404_1"),
                    ("aggressive", "ind-CHN_NLF015_k99_50000"),
                    ("aggressive", "ind-CHN_NLF015_k99_60000"),
                },
            )
            stats_by_key = {
                (row["checkv_filter"], row["genome_id"]): row
                for row in stats
            }
            for checkv_filter in ("conservative", "aggressive"):
                hit_row = stats_by_key[
                    (checkv_filter, "ind-CHN_NLF015_k99_39404_1")
                ]
                zero_hit_row = stats_by_key[
                    (checkv_filter, "ind-CHN_NLF015_k99_50000")
                ]
                zero_denominator_row = stats_by_key[
                    (checkv_filter, "ind-CHN_NLF015_k99_60000")
                ]
                self.assertEqual(hit_row["vf_orf_prevalence"], "1.0")
                self.assertEqual(zero_hit_row["eligible_bacterial_orfs"], "1")
                self.assertEqual(zero_hit_row["vf_orf_prevalence"], "0.0")
                self.assertEqual(
                    zero_denominator_row["eligible_bacterial_orfs"],
                    "0",
                )
                self.assertEqual(
                    zero_denominator_row["vf_orf_prevalence"],
                    "",
                )
            self.assertEqual(len(hits), 2)
            self.assertEqual(
                {row["annotation"] for row in features},
                {"bacterial", "viral", "vf"},
            )

    def test_missing_phatyp_record_fails(self):
        with tempfile.TemporaryDirectory() as temporary_dir:
            project_dir = Path(temporary_dir)
            (project_dir / "data").mkdir()
            (project_dir / "samples").mkdir()
            (project_dir / "samples/ind-CHN_samples.txt").write_text(
                "NLF015 SRR1\n", encoding="utf-8"
            )
            for checkv_filter in ("conservative", "aggressive"):
                self._write_filter(project_dir, checkv_filter)
            phatyp = (
                project_dir
                / "checkv_genomes/aggressive/final_prediction/"
                "phatyp_prediction.tsv"
            )
            phatyp.write_text(
                "Accession\tLength\tTYPE\tPhaTYPScore\n"
                "ind-CHN_NLF015_k99_39404_1\t4\tvirulent\t0.9\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(
                        REPO_DIR
                        / "data_wrangling/collect_checkv_genome_stats.py"
                    ),
                    str(project_dir),
                ],
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("PhaTYP identifiers differ", result.stderr)

    def test_missing_required_checkv_inputs_fail(self):
        cases = (
            ("phagcn", "missing aggressive PhaGCN"),
            ("checkv", "no CheckV contig matches"),
            ("prokka", "missing aggressive viral features"),
            ("prokka_headerless", "feature table has invalid schema"),
        )
        for missing_input, expected_error in cases:
            with self.subTest(missing_input=missing_input):
                with tempfile.TemporaryDirectory() as temporary_dir:
                    project_dir = Path(temporary_dir)
                    (project_dir / "data").mkdir()
                    (project_dir / "samples").mkdir()
                    (project_dir / "samples/ind-CHN_samples.txt").write_text(
                        "NLF015 SRR1\n", encoding="utf-8"
                    )
                    for checkv_filter in ("conservative", "aggressive"):
                        self._write_filter(project_dir, checkv_filter)
                    if missing_input == "phagcn":
                        path = (
                            project_dir / "checkv_genomes/aggressive/"
                            "final_prediction/phagcn_prediction.tsv"
                        )
                        path.unlink()
                    elif missing_input == "checkv":
                        path = (
                            project_dir / "checkv_input/aggressive/"
                            "quality_summary.tsv"
                        )
                        path.write_text(
                            "contig_id\twarnings\tLifestyle\tSource\n"
                            "unknown\tnone\tLytic\tind\n",
                            encoding="utf-8",
                        )
                    elif missing_input == "prokka":
                        path = (
                            project_dir / "checkv_genomes/aggressive/"
                            "annotations/viral/valid_features.csv"
                        )
                        path.unlink()
                    else:
                        path = (
                            project_dir / "checkv_genomes/aggressive/"
                            "annotations/viral/valid_features.csv"
                        )
                        path.write_text("", encoding="utf-8")
                    result = subprocess.run(
                        [
                            sys.executable,
                            str(
                                REPO_DIR
                                / "data_wrangling/"
                                "collect_checkv_genome_stats.py"
                            ),
                            str(project_dir),
                        ],
                        text=True,
                        capture_output=True,
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(expected_error, result.stderr)

    def test_prepare_cli_extracts_only_eligible_bacterial_proteins(self):
        with tempfile.TemporaryDirectory() as temporary_dir:
            temporary_path = Path(temporary_dir)
            gff_path = temporary_path / "raw.gff"
            faa_path = temporary_path / "raw.faa"
            features_path = temporary_path / "features.csv"
            eligible_path = temporary_path / "eligible.faa"
            gff_path.write_text(
                "g1\tProkka\tCDS\t1\t3\t.\t+\t0\t"
                "ID=eligible;product=enzyme;eC_number=1.2.3.4\n"
                "g1\tProkka\tCDS\t4\t6\t.\t+\t0\t"
                "ID=no_ec;product=enzyme\n"
                "g1\tProkka\tCDS\t7\t9\t.\t+\t0\t"
                "ID=hypothetical;product=hypothetical protein;"
                "eC_number=2.3.4.5\n",
                encoding="utf-8",
            )
            faa_path.write_text(
                ">eligible\nAAA\n>no_ec\nBBB\n>hypothetical\nCCC\n",
                encoding="utf-8",
            )
            subprocess.run(
                [
                    sys.executable,
                    str(REPO_DIR / "data_wrangling/prepare_checkv_prokka.py"),
                    str(gff_path),
                    str(features_path),
                    "--faa-path",
                    str(faa_path),
                    "--faa-output",
                    str(eligible_path),
                ],
                check=True,
            )
            self.assertEqual(
                eligible_path.read_text(encoding="utf-8"),
                ">eligible\nAAA\n",
            )

    @staticmethod
    def _read_csv(path):
        with path.open(newline="", encoding="utf-8") as handle:
            return list(csv.DictReader(handle))

    @staticmethod
    def _write_filter(project_dir, checkv_filter):
        input_dir = project_dir / "checkv_input" / checkv_filter
        output_dir = project_dir / "checkv_genomes" / checkv_filter
        prediction_dir = output_dir / "predictions/out"
        bacterial_dir = output_dir / "annotations/bacterial"
        viral_dir = output_dir / "annotations/viral"
        alignment_dir = output_dir / "vf_alignment"
        for directory in (
            input_dir,
            prediction_dir,
            bacterial_dir,
            viral_dir,
            alignment_dir,
        ):
            directory.mkdir(parents=True, exist_ok=True)

        fasta = (
            ">ind-CHN_NLF015_k99_39404_1\nAAAA\n"
            ">ind-CHN_NLF015_k99_50000\nAAAAAA\n"
            ">ind-CHN_NLF015_k99_60000\nAAAAAAAA\n"
        )
        with gzip.open(input_dir / "genomes.fa.gz", "wt") as handle:
            handle.write(fasta)
        (input_dir / "complete_contigs.txt").write_text(
            "ind-CHN_NLF015_k99_39404\n"
            "ind-CHN_NLF015_k99_50000\n"
            "ind-CHN_NLF015_k99_60000\n",
            encoding="utf-8",
        )
        (input_dir / "quality_summary.tsv").write_text(
            "contig_id\tcontig_length\twarningsLifestyle\tSource\n"
            "ind-CHN_NLF015_k99_39404\t4\tnone\tTemperate\tind\n"
            "ind-CHN_NLF015_k99_50000\t6\tnone\tLytic\tind\n"
            "ind-CHN_NLF015_k99_60000\t8\tnone\tLytic\tind\n",
            encoding="utf-8",
        )
        if checkv_filter == "aggressive":
            phagcn_dir = output_dir / "final_prediction"
            phagcn_dir.mkdir()
            (phagcn_dir / "phatyp_prediction.tsv").write_text(
                "Accession\tLength\tTYPE\tPhaTYPScore\n"
                "ind-CHN_NLF015_k99_39404_1\t4\ttemperate\t0.8\n"
                "ind-CHN_NLF015_k99_50000\t6\tvirulent\t0.9\n"
                "ind-CHN_NLF015_k99_60000\t8\tvirulent\t0.7\n",
                encoding="utf-8",
            )
            (phagcn_dir / "phagcn_prediction.tsv").write_text(
                "Accession\tLength\tLineage\tPhaGCNScore\tGenus\t"
                "GenusCluster\n"
                "ind-CHN_NLF015_k99_39404_1\t4\t"
                "class:Caudoviricetes;family:Siphoviridae\t0.9;0.7\t"
                "G1\tGC1\n"
                "ind-CHN_NLF015_k99_50000\t6\t"
                "class:Caudoviricetes;family:Myoviridae\t0.9;0.8\t"
                "G2\tGC2\n"
                "ind-CHN_NLF015_k99_60000\t8\t"
                "class:Caudoviricetes;family:Podoviridae\t0.9;0.6\t"
                "G3\tGC3\n",
                encoding="utf-8",
            )
        else:
            (prediction_dir / "phatyp_prediction.csv").write_text(
                "Contig,Pred,Score\n"
                "ind-CHN_NLF015_k99_39404_1,temperate,0.8\n"
                "ind-CHN_NLF015_k99_50000,virulent,0.9\n"
                "ind-CHN_NLF015_k99_60000,virulent,0.7\n",
                encoding="utf-8",
            )
            (prediction_dir / "phagcn_prediction.csv").write_text(
                "Accession,Lineage,Family,Score,Genus,Genus_cluster\n"
                "ind-CHN_NLF015_k99_39404_1,Viruses;Caudoviricetes,"
                "Siphoviridae,0.7,G1,GC1\n"
                "ind-CHN_NLF015_k99_50000,Viruses;Caudoviricetes,"
                "Myoviridae,0.8,G2,GC2\n"
                "ind-CHN_NLF015_k99_60000,Viruses;Caudoviricetes,"
                "Podoviridae,0.6,G3,GC3\n",
                encoding="utf-8",
            )
        feature_header = (
            "genome_id,feature_id,start,end,strand,product,ec_number\n"
        )
        (bacterial_dir / "valid_features.csv").write_text(
            feature_header
            + "ind-CHN_NLF015_k99_39404_1,orf1,1,3,+,enzyme,1.2.3.4\n"
            + "ind-CHN_NLF015_k99_50000,orf2,1,3,+,enzyme,3.4.5.6\n",
            encoding="utf-8",
        )
        (viral_dir / "valid_features.csv").write_text(
            feature_header
            + "ind-CHN_NLF015_k99_39404_1,vir1,2,4,-,capsid,2.3.4.5\n",
            encoding="utf-8",
        )
        (alignment_dir / "table.txt").write_text(
            "# hmmer\n"
            "orf1 ACC VF_B QACC 1e-20 50 1 1e-20 50 1 1 1 1 1 1 1 1 1 B\n"
            "orf1 ACC VF_A QACC 1e-20 50 1 1e-20 50 1 1 1 1 1 1 1 1 1 A\n",
            encoding="utf-8",
        )


if __name__ == "__main__":
    unittest.main()
