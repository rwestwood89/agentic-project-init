"""Tests for shared logging utilities."""


import pytest

from src.utils.logging import Logger, get_logger, init_logger


class TestLogger:
    """Tests for Logger class."""

    def test_error_message(self, capsys):
        """Test basic error logging."""
        logger = Logger(verbose=False, use_colors=False)
        logger.error("Something went wrong")

        captured = capsys.readouterr()
        assert "Error: Something went wrong" in captured.err
        assert captured.out == ""

    def test_error_with_suggestion(self, capsys):
        """Test error logging with suggestion."""
        logger = Logger(verbose=False, use_colors=False)
        logger.error("File not found", suggestion="Run reconcile-registry first")

        captured = capsys.readouterr()
        assert "Error: File not found" in captured.err
        assert "Run reconcile-registry first" in captured.err

    def test_warning_message(self, capsys):
        """Test warning logging."""
        logger = Logger(verbose=False, use_colors=False)
        logger.warning("Deprecated feature")

        captured = capsys.readouterr()
        assert "Warning: Deprecated feature" in captured.err

    def test_info_message(self, capsys):
        """Test info logging."""
        logger = Logger(verbose=False, use_colors=False)
        logger.info("Processing started")

        captured = capsys.readouterr()
        assert "Processing started" in captured.err

    def test_debug_verbose_enabled(self, capsys):
        """Test debug logging when verbose=True."""
        logger = Logger(verbose=True, use_colors=False)
        logger.debug("Debug details")

        captured = capsys.readouterr()
        assert "DEBUG: Debug details" in captured.err

    def test_debug_verbose_disabled(self, capsys):
        """Test debug logging when verbose=False."""
        logger = Logger(verbose=False, use_colors=False)
        logger.debug("Debug details")

        captured = capsys.readouterr()
        assert captured.err == ""

    def test_debug_with_kwargs(self, capsys):
        """Test debug logging with key-value pairs."""
        logger = Logger(verbose=True, use_colors=False)
        logger.debug("Loading file", path="/tmp/test.json", size=1024)

        captured = capsys.readouterr()
        assert "DEBUG: Loading file" in captured.err
        assert "path=" in captured.err
        assert "/tmp/test.json" in captured.err
        assert "size=1024" in captured.err

    def test_exception_basic(self, capsys):
        """Test exception logging without traceback."""
        logger = Logger(verbose=False, use_colors=False)
        exc = ValueError("Invalid value")
        logger.exception("Failed to parse", exc)

        captured = capsys.readouterr()
        assert "Error: Failed to parse: Invalid value" in captured.err
        # Should NOT include traceback when verbose=False
        assert "Traceback" not in captured.err

    def test_exception_with_traceback(self, capsys):
        """Test exception logging with traceback in verbose mode."""
        logger = Logger(verbose=True, use_colors=False)

        try:
            raise ValueError("Test error")
        except ValueError as e:
            logger.exception("Caught exception", e)

        captured = capsys.readouterr()
        assert "Error: Caught exception: Test error" in captured.err
        # Should include traceback when verbose=True
        assert "Traceback" in captured.err
        assert "ValueError: Test error" in captured.err

    def test_colorize_enabled(self):
        """Test ANSI color codes when colors enabled."""
        # Force colors even without TTY
        logger = Logger(verbose=False, use_colors=True)
        logger.use_colors = True  # Override TTY check

        colored = logger._colorize("text", "31")
        assert "\033[31m" in colored  # Red color code
        assert "\033[0m" in colored   # Reset code
        assert "text" in colored

    def test_colorize_disabled(self):
        """Test no color codes when colors disabled."""
        logger = Logger(verbose=False, use_colors=False)

        colored = logger._colorize("text", "31")
        assert colored == "text"
        assert "\033[" not in colored


class TestGlobalLogger:
    """Tests for global logger initialization."""

    def test_init_logger(self):
        """Test global logger initialization."""
        logger = init_logger(verbose=True, use_colors=False)
        assert logger is not None
        assert logger.verbose is True
        assert logger.use_colors is False

    def test_get_logger_after_init(self):
        """Test getting logger after initialization."""
        init_logger(verbose=False, use_colors=True)
        logger = get_logger()
        assert logger is not None
        assert logger.verbose is False

    def test_get_logger_before_init_raises_error(self):
        """Test that get_logger raises error if not initialized."""
        # Reset global logger
        import src.utils.logging
        src.utils.logging._logger = None

        with pytest.raises(RuntimeError, match="Logger not initialized"):
            get_logger()

        # Restore for other tests
        init_logger()
