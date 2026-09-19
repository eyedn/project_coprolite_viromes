###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       validate_checkv_source.py
###############################################################################
"""Validate supplied CheckV source labels against manifests."""


def validate_checkv_source(source, category):
    """Raise when a supplied CheckV Source conflicts with the category."""
    if str(source).strip().casefold() != str(category).strip().casefold():
        raise ValueError(
            f"CheckV Source '{source}' does not match category '{category}'"
        )
