###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       parse_gff_lines.py
###############################################################################
"""Parse contig lengths and CDS-to-contig mappings from GFF text."""


def parse_gff_lines(lines, sample):
    """Return contig lengths, CDS coordinates, and invalid coordinates."""
    lines = list(lines)
    contigs = {}
    orfs = {}
    invalid_coordinates = []

    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.rstrip("\n")
        if line == "##FASTA":
            break
        if not line.startswith("##sequence-region"):
            continue
        fields = line.split()
        if len(fields) != 4:
            raise ValueError(
                f"malformed ##sequence-region at GFF line {line_number}"
            )
        contig_id = fields[1]
        try:
            region_start = int(fields[2])
            region_end = int(fields[3])
        except ValueError as error:
            raise ValueError(
                f"nonnumeric ##sequence-region at GFF line {line_number}"
            ) from error
        if region_start != 1 or region_end < region_start:
            raise ValueError(
                f"invalid ##sequence-region at GFF line {line_number}"
            )
        key = (sample, contig_id)
        if key in contigs:
            raise ValueError(
                f"duplicate GFF contig key: {sample} + {contig_id}"
            )
        contigs[key] = region_end

    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.rstrip("\n")
        if line == "##FASTA":
            break
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 9:
            raise ValueError(f"malformed GFF feature at line {line_number}")
        if fields[2] != "CDS":
            continue

        contig_id = fields[0]
        contig_key = (sample, contig_id)
        if contig_key not in contigs:
            raise ValueError(
                f"GFF CDS references undeclared contig at line {line_number}: "
                f"{contig_id}"
            )
        attributes = {}
        for item in fields[8].split(";"):
            if "=" in item:
                key, value = item.split("=", 1)
                attributes[key] = value
        orf_id = attributes.get("ID", "").strip()
        if not orf_id:
            raise ValueError(f"GFF CDS has no ID at line {line_number}")

        try:
            start = int(fields[3])
            end = int(fields[4])
        except ValueError as error:
            raise ValueError(
                f"GFF CDS has nonnumeric coordinates at line {line_number}"
            ) from error
        if start < 1 or end < start or end > contigs[contig_key]:
            invalid_coordinates.append(
                f"{sample}:{orf_id}:{start}-{end}"
            )

        orf_key = (sample, orf_id)
        if orf_key in orfs:
            raise ValueError(f"duplicate GFF ORF key: {sample} + {orf_id}")
        orfs[orf_key] = {
            "contig_id": contig_id,
            "start": start,
            "end": end,
        }

    return contigs, orfs, invalid_coordinates
