from collect_alignments import get_table_counts 
from sys import argv

parent_template_path = argv[1]

get_table_counts.get_table_counts(parent_template_path)
