###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       write_csv.py
###############################################################################
"""Write collector rows with an explicit stable column order."""

import csv
import math


def write_csv(path, rows, fieldnames):
    """Write dictionaries to CSV, representing numeric missing values blank."""
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            output_row = {}
            for field in fieldnames:
                value = row.get(field)
                if isinstance(value, float) and math.isnan(value):
                    value = ""
                output_row[field] = value
            writer.writerow(output_row)
