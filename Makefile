.PHONY: sync test coverage lint format typecheck all clean

# Environment setup
sync:
	uv sync

# Testing
test:
	uv run pytest

coverage:
	uv run pytest --cov=src --cov-fail-under=90

# Code quality
lint:
	uv run ruff check src tests

format:
	uv run black src tests
	uv run isort src tests

typecheck:
	uv run mypy src

# Combined commands
all: format lint typecheck coverage

clean:
	rm -rf .venv
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	rm -rf build
	rm -rf dist
	rm -rf *.egg-info
