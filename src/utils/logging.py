"""Shared logging utilities for lifecycle scripts.

Provides consistent logging behavior across all scripts:
- Stderr for error messages
- Optional debug logging via --verbose flag
- Colored output for better readability (when terminal supports it)
"""

import sys
from enum import Enum
from typing import Any


class LogLevel(Enum):
    """Log levels for console output."""
    DEBUG = 0
    INFO = 1
    WARNING = 2
    ERROR = 3


class Logger:
    """Simple logger for lifecycle scripts.

    Attributes:
        verbose: If True, DEBUG messages are printed
        use_colors: If True, use ANSI color codes
    """

    def __init__(self, verbose: bool = False, use_colors: bool = True) -> None:
        """Initialize logger.

        Args:
            verbose: Enable debug output
            use_colors: Enable ANSI color codes
        """
        self.verbose = verbose
        self.use_colors = use_colors and sys.stderr.isatty()

    def _colorize(self, text: str, color_code: str) -> str:
        """Add ANSI color codes to text.

        Args:
            text: Text to colorize
            color_code: ANSI color code (e.g., '31' for red)

        Returns:
            Colorized text if colors enabled, otherwise unchanged
        """
        if not self.use_colors:
            return text
        return f"\033[{color_code}m{text}\033[0m"

    def debug(self, message: str, **kwargs: Any) -> None:
        """Log debug message (only if verbose enabled).

        Args:
            message: Message to log
            **kwargs: Additional key-value pairs to include
        """
        if not self.verbose:
            return

        formatted = self._colorize(f"DEBUG: {message}", "36")  # Cyan
        if kwargs:
            details = " ".join(f"{k}={v!r}" for k, v in kwargs.items())
            formatted += f" ({details})"

        print(formatted, file=sys.stderr)

    def info(self, message: str) -> None:
        """Log info message.

        Args:
            message: Message to log
        """
        formatted = self._colorize(message, "37")  # White
        print(formatted, file=sys.stderr)

    def warning(self, message: str) -> None:
        """Log warning message.

        Args:
            message: Warning message to log
        """
        formatted = self._colorize(f"Warning: {message}", "33")  # Yellow
        print(formatted, file=sys.stderr)

    def error(self, message: str, suggestion: str | None = None) -> None:
        """Log error message with optional suggestion.

        Args:
            message: Error message to log
            suggestion: Optional suggestion for fixing the error
        """
        formatted = self._colorize(f"Error: {message}", "31")  # Red
        print(formatted, file=sys.stderr)

        if suggestion:
            suggestion_text = self._colorize(f"  → {suggestion}", "33")  # Yellow
            print(suggestion_text, file=sys.stderr)

    def exception(self, message: str, exc: Exception) -> None:
        """Log exception with traceback (verbose mode only).

        Args:
            message: Context message
            exc: Exception to log
        """
        self.error(f"{message}: {exc}")

        if self.verbose:
            import traceback
            tb = "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))
            print(self._colorize(tb, "90"), file=sys.stderr)  # Gray


# Global logger instance (initialized by scripts)
_logger: Logger | None = None


def init_logger(verbose: bool = False, use_colors: bool = True) -> Logger:
    """Initialize the global logger.

    Args:
        verbose: Enable debug output
        use_colors: Enable ANSI color codes

    Returns:
        Logger instance
    """
    global _logger
    _logger = Logger(verbose=verbose, use_colors=use_colors)
    return _logger


def get_logger() -> Logger:
    """Get the global logger instance.

    Returns:
        Logger instance

    Raises:
        RuntimeError: If logger not initialized
    """
    if _logger is None:
        raise RuntimeError("Logger not initialized. Call init_logger() first.")
    return _logger
