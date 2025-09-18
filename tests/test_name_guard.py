"""Test to cover the __name__ == '__main__' guard."""

import sys
from io import StringIO
from unittest.mock import patch


def test_main_name_guard_direct_execution() -> None:
    """Test __name__ == '__main__' block by simulating direct execution."""
    # Read the main.py content
    with open("/workspace/src/main.py") as f:
        main_code = f.read()

    # Create a modified version that we can exec with __name__ == '__main__'
    namespace = {
        "__name__": "__main__",
        "__file__": "/workspace/src/main.py",
        "print": print,  # Ensure print is available
    }

    # Capture output
    captured_output = StringIO()

    with patch("sys.stdout", captured_output):
        exec(main_code, namespace)

    output = captured_output.getvalue()
    assert "Hello from workspace!" in output


def test_main_script_as_module() -> None:
    """Test running main.py as a script using runpy."""
    import runpy
    from unittest.mock import patch

    # Add src to path
    sys.path.insert(0, "/workspace/src")

    captured_output = StringIO()

    try:
        with patch("sys.stdout", captured_output):
            # This should execute the if __name__ == '__main__' block
            with patch("sys.argv", ["main.py"]):
                runpy.run_path("/workspace/src/main.py", run_name="__main__")

        output = captured_output.getvalue()
        assert "Hello from workspace!" in output
    finally:
        if "/workspace/src" in sys.path:
            sys.path.remove("/workspace/src")


def test_exec_with_main_name() -> None:
    """Execute main.py code with __name__ set to '__main__'."""
    # Read main.py
    with open("/workspace/src/main.py") as f:
        code = f.read()

    # Execute in a namespace where __name__ is '__main__'
    captured_output = StringIO()

    # Create the execution environment
    exec_globals = {
        "__name__": "__main__",
        "__file__": "/workspace/src/main.py",
    }

    with patch("sys.stdout", captured_output):
        exec(compile(code, "/workspace/src/main.py", "exec"), exec_globals)

    output = captured_output.getvalue()
    assert "Hello from workspace!" in output
