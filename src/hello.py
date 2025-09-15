"""A simple hello world module."""


def hello(name: str = "World") -> str:
    """Return a greeting message.

    Args:
        name: The name to greet. Defaults to "World".

    Returns:
        A greeting message.
    """
    if not isinstance(name, str):
        raise TypeError("Name must be a string")
    if not name.strip():
        raise ValueError("Name cannot be empty")
    return f"Hello, {name}!"


def main() -> None:
    """Main entry point."""
    print(hello())


if __name__ == "__main__":
    main()
