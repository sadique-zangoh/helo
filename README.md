# helo

Python project with comprehensive development tooling and pre-push validation.

## Features

- **Code Quality**: Automated linting with ruff, black, isort, and mypy
- **Testing**: Pytest with coverage requirements
- **Pre-commit Hooks**: Automated validation before commits
- **CI/CD**: GitHub Actions workflow for continuous integration

## Development Setup

```bash
# Install UV package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Setup environment
uv sync

# Install pre-commit hooks
uv run pre-commit install
```

## Running Tests

```bash
uv run pytest --cov=src --cov-report=term-missing
```
