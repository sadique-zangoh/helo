# workspace

A Python project with comprehensive development tooling and CI/CD enforcement.

## Features

- Modern Python tooling (uv, ruff, black, mypy, pytest)
- Pre-commit hooks for code quality
- 100% test coverage
- Type checking with mypy
- Automated linting and formatting

## Development

Install dependencies:
```bash
uv sync
```

Run tests:
```bash
uv run pytest --cov=src
```

Run linting:
```bash
uv run ruff check .
uv run black .
uv run mypy src
```
