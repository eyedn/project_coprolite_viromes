###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       log_diagnostic.py
###############################################################################


"""Write flushed collector diagnostics with process peak resident memory."""

from datetime import datetime, timezone
import resource
import sys
import time


def log_diagnostic(message, started_at):
    """Report elapsed seconds and peak RSS, never current or virtual memory."""
    peak_rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    # macOS reports bytes; Linux reports KiB. Convert both to MiB.
    divisor = 1024 * 1024 if sys.platform == "darwin" else 1024
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    elapsed = time.monotonic() - started_at
    print(
        f"{timestamp} elapsed={elapsed:.2f}s "
        f"peak RSS={peak_rss / divisor:.2f} MiB {message}",
        file=sys.stderr,
        flush=True,
    )
