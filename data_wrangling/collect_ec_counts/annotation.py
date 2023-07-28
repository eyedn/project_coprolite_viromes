###############################################################################
#       Aydin Karatas
#       Project Coporlite Viromes
#       annotation.py
###############################################################################
import typing


# annotations are obtained fom a gff file after annotation
class Annotation:
    def __init__(self, data: typing.List[str]) -> None:
        self.contig = data[0]
        self.feature = data[2]
        self.start = data[3]
        self.end = data[4]
        self.strand = data[6]
        # attibutes contains info about the annotation locus and product
        attributes = data[8].split(";")
        self.seq_id = ""
        self.ec_num = ""
        self.locus = ""
        self.product = ""
        self.interpret_attributes(attributes)

    def interpret_attributes(self, attributes: str) -> None:
        for attribute in attributes:
            if "inference" in attribute:
                inference_info = attribute.split(":")
                self.seq_id = inference_info[-1]
            elif "eC_number" in attribute:
                ec_info = attribute.split("=")
                self.ec_num = ec_info[-1]
            elif "locus_tag" in attribute:
                locus_info = attribute.split("=")
                self.locus = locus_info[-1]
            elif "note" in attribute and "CAZY" in attribute:
                note_info = attribute.split("=")
                self.product = note_info[-1]
            elif "product" in attribute and self.product == "":
                product_info = attribute.split("=")
                self.product = product_info[-1]
