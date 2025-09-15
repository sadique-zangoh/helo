"""Tests for the hello module."""

import io
from unittest.mock import patch

import pytest

from src.hello import hello, main


class TestHello:
    """Test cases for the hello function."""

    def test_hello_default(self):
        """Test hello with default parameter."""
        result = hello()
        assert result == "Hello, World!"

    def test_hello_with_name(self):
        """Test hello with custom name."""
        result = hello("Alice")
        assert result == "Hello, Alice!"

    def test_hello_with_empty_string(self):
        """Test hello with empty string raises ValueError."""
        with pytest.raises(ValueError, match="Name cannot be empty"):
            hello("")

    def test_hello_with_whitespace_only(self):
        """Test hello with whitespace only raises ValueError."""
        with pytest.raises(ValueError, match="Name cannot be empty"):
            hello("   ")

    def test_hello_with_non_string(self):
        """Test hello with non-string input raises TypeError."""
        with pytest.raises(TypeError, match="Name must be a string"):
            hello(123)

    def test_hello_with_none(self):
        """Test hello with None raises TypeError."""
        with pytest.raises(TypeError, match="Name must be a string"):
            hello(None)

    def test_hello_with_special_characters(self):
        """Test hello with special characters."""
        result = hello("José")
        assert result == "Hello, José!"

    def test_hello_with_numbers_in_name(self):
        """Test hello with numbers in name."""
        result = hello("User123")
        assert result == "Hello, User123!"

    def test_hello_case_sensitivity(self):
        """Test hello preserves case."""
        result = hello("alice")
        assert result == "Hello, alice!"


class TestMain:
    """Test cases for the main function."""

    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main_output(self, mock_stdout):
        """Test that main prints the correct output."""
        main()
        output = mock_stdout.getvalue()
        assert output.strip() == "Hello, World!"

    @patch("src.hello.hello")
    def test_main_calls_hello(self, mock_hello):
        """Test that main calls hello function."""
        mock_hello.return_value = "Hello, World!"

        with patch("builtins.print") as mock_print:
            main()

        mock_hello.assert_called_once_with()
        mock_print.assert_called_once_with("Hello, World!")


class TestModuleExecution:
    """Test cases for module execution."""

    def test_main_block_execution(self):
        """Test the __main__ block execution."""
        import importlib.util
        from unittest.mock import patch

        # Load the module as if it were __main__
        spec = importlib.util.spec_from_file_location("__main__", "src/hello.py")
        module = importlib.util.module_from_spec(spec)

        with patch("builtins.print") as mock_print:
            # Temporarily set __name__ to __main__ and execute
            original_name = getattr(module, "__name__", None)
            module.__name__ = "__main__"

            try:
                spec.loader.exec_module(module)
                mock_print.assert_called_with("Hello, World!")
            finally:
                if original_name is not None:
                    module.__name__ = original_name


# Integration tests
class TestIntegration:
    """Integration test cases."""

    def test_full_workflow(self):
        """Test the complete workflow."""
        # Test normal case
        result = hello("TestUser")
        assert result == "Hello, TestUser!"

        # Test with main function
        with patch("builtins.print") as mock_print:
            main()
            mock_print.assert_called_once_with("Hello, World!")

    def test_error_handling_workflow(self):
        """Test error handling in complete workflow."""
        # Test TypeError
        with pytest.raises(TypeError):
            hello(42)

        # Test ValueError
        with pytest.raises(ValueError):
            hello("")
