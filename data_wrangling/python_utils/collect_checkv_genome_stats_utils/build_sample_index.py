###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       build_sample_index.py
###############################################################################
"""Build a unique sample-to-category/origin lookup."""


def build_sample_index(manifest_samples):
    """Return sample metadata derived from named repository manifests."""
    sample_index = {}
    for manifest_name, samples in manifest_samples.items():
        if "-" not in manifest_name:
            raise ValueError(f"invalid sample manifest name: {manifest_name}")
        category, origin = manifest_name.split("-", 1)
        for sample in samples:
            if sample in sample_index:
                raise ValueError(
                    f"sample occurs in multiple manifests: {sample}"
                )
            sample_index[sample] = {
                "category": category,
                "origin": origin,
                "sample": sample,
            }
    return sample_index
