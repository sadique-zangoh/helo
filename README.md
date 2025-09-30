# helo

Python project with modern development tooling and pre-push validation infrastructure.

## Features

- 🚀 Modern Python package structure
- ✅ Pre-commit hooks (ruff, black, isort, mypy)
- 📦 UV package management
- 🧪 Pytest test suite with coverage
- 🔍 Type checking with mypy
- 📝 Code formatting with black and isort

## Development

Install dependencies:
```bash
uv sync
```

Run tests:
```bash
uv run pytest
```

Run pre-commit checks:
```bash
uv run pre-commit run --all-files
```
