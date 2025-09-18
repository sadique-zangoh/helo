"""Main entry point for the workspace application."""

import sys


def greet(name: str = "workspace") -> str:
    """Generate a greeting message."""
    return f"Hello from {name}!"


def process_args(args: list[str]) -> str:
    """Process command line arguments and return appropriate greeting."""
    # Look for actual name arguments (not flags, paths, or test artifacts)
    for arg in args[1:]:
        if (
            not arg.startswith(("-", "test", "/"))
            and arg.strip()
            and not arg.endswith(".py")
        ):
            return greet(arg)
    return greet()


def main() -> None:
    """Main application entry point."""
    message = process_args(sys.argv)
    print(message)


if __name__ == "__main__":
    main()
