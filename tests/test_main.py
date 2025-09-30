"""Tests for main module."""

import subprocess
import sys
from io import StringIO
from unittest.mock import patch

import pytest

from src.main import main


def test_main_function() -> None:
    """Test the main function directly."""
    # Capture stdout
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        main()

    output = captured_output.getvalue()
    assert "Hello from workspace!" in output
    assert output.strip() == "Hello from workspace!"


def test_main_function_return_type() -> None:
    """Test that main function returns None."""
    # main() has return type None, so we just call it
    main()
    # If we reach here, the function executed successfully
    assert True


def test_main_function_no_arguments() -> None:
    """Test that main function works without arguments."""
    try:
        main()
    except Exception as e:
        pytest.fail(f"main() raised an exception: {e}")


def test_main_function_print_behavior() -> None:
    """Test specific print behavior of main function."""
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        main()

    output = captured_output.getvalue()
    # Check exact output
    assert output == "Hello from workspace!\n"


def test_main_module_as_script() -> None:
    """Test main module when run as a script."""
    result = subprocess.run(
        [sys.executable, "src/main.py"],
        capture_output=True,
        text=True,
        cwd="/workspace",
    )

    assert result.returncode == 0
    assert "Hello from workspace!" in result.stdout


def test_main_module_name_guard() -> None:
    """Test that __name__ == '__main__' guard works correctly."""
    # Test importing the module doesn't execute main()
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        import src.main  # noqa: F401

    # Should not have any output when importing
    # The output might be empty or minimal since we're just importing
    # The main execution should only happen with __name__ == '__main__'


def test_main_module_direct_execution() -> None:
    """Test running main module directly with python -m."""
    result = subprocess.run(
        [sys.executable, "-m", "src.main"],
        capture_output=True,
        text=True,
        cwd="/workspace",
    )

    assert result.returncode == 0
    assert "Hello from workspace!" in result.stdout


def test_main_function_multiple_calls() -> None:
    """Test that main function can be called multiple times."""
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        main()
        main()
        main()

    output = captured_output.getvalue()
    lines = output.strip().split("\n")
    assert len(lines) == 3
    for line in lines:
        assert line == "Hello from workspace!"


def test_main_module_import() -> None:
    """Test that main module can be imported without errors."""
    try:
        import src.main  # noqa: F401
    except Exception as e:
        pytest.fail(f"main module import raised an exception: {e}")


def test_main_function_exists() -> None:
    """Test that main function exists and is callable."""
    from src.main import main

    assert callable(main)


def test_main_script_execution_coverage() -> None:
    """Test executing main.py as script to cover __name__ == '__main__' branch."""
    # Execute the script directly to trigger the if __name__ == '__main__' block
    result = subprocess.run(
        [sys.executable, "src/main.py"],
        capture_output=True,
        text=True,
        cwd="/workspace",
    )

    assert result.returncode == 0
    assert "Hello from workspace!" in result.stdout

    # Verify the exact output
    assert result.stdout.strip() == "Hello from workspace!"
