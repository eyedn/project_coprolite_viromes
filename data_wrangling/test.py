from collect_alignments import get_table_counts 
from sys import argv

parent_template_path = argv[1]
output_csv = argv[2]

counts = get_table_counts.get_table_counts(parent_template_path)
print(counts)
counts.to_csv(output_csv)
