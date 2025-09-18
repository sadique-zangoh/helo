"""Tests for hello module."""

import sys
from io import StringIO
from unittest.mock import patch

import pytest


def test_hello_module_import() -> None:
    """Test that hello module can be imported without errors."""
    import src.hello  # noqa: F401


def test_hello_module_execution() -> None:
    """Test that hello module prints correct output when executed."""
    # Capture stdout
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        # Import the module which will execute the print statement
        import importlib

        import src.hello

        # Force reload to capture the print statement
        importlib.reload(src.hello)

    output = captured_output.getvalue()
    assert "Hello, World!" in output


def test_hello_module_as_script() -> None:
    """Test hello module when run as a script."""
    import subprocess

    result = subprocess.run(
        [sys.executable, "-c", "import src.hello"],
        capture_output=True,
        text=True,
        cwd="/workspace",
    )

    assert result.returncode == 0
    assert "Hello, World!" in result.stdout


def test_hello_module_no_errors() -> None:
    """Test that hello module doesn't raise any exceptions."""
    try:
        import src.hello  # noqa: F401
    except Exception as e:
        pytest.fail(f"hello module raised an exception: {e}")
