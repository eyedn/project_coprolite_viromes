###############################################################################
#       Aydin Karatas
#       Project Coprolite Viromes
#       diagnostic_phase.py
###############################################################################


"""Report phase boundaries without swallowing collector exceptions."""

from contextlib import contextmanager
import time

from .log_diagnostic import log_diagnostic


@contextmanager
def diagnostic_phase(phase, started_at, version):
    """Log duration and failure context while preserving the traceback."""
    prefix = f"version={version} phase={phase}"
    phase_started = time.monotonic()
    log_diagnostic(f"{prefix} event=start", started_at)
    try:
        yield
    except BaseException as error:
        elapsed = time.monotonic() - phase_started
        log_diagnostic(
            f"{prefix} event=failed phase_elapsed={elapsed:.2f}s "
            f"error={type(error).__name__}", started_at,
        )
        raise
    else:
        elapsed = time.monotonic() - phase_started
        log_diagnostic(
            f"{prefix} event=end phase_elapsed={elapsed:.2f}s", started_at,
        )
