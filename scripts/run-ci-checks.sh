#!/bin/bash
set -e

echo "🚀 Running CI checks locally..."
echo ""

# Ensure UV is available
if ! command -v uv &> /dev/null; then
    echo "❌ UV is not installed. Please install it first."
    exit 1
fi

# Run linting
echo "🔍 Running ruff linting..."
uv run ruff check src/ tests/
echo "✅ Ruff linting passed"
echo ""

# Run ruff format check
echo "🔍 Running ruff format check..."
uv run ruff format --check src/ tests/
echo "✅ Ruff format check passed"
echo ""

# Run black formatting check
echo "🔍 Running black formatting check..."
uv run black --check src/ tests/
echo "✅ Black formatting passed"
echo ""

# Run isort check
echo "🔍 Running isort check..."
uv run isort --check-only src/ tests/
echo "✅ Isort check passed"
echo ""

# Run type checking
echo "🔍 Running mypy type checking..."
uv run mypy src/
echo "✅ Type checking passed"
echo ""

# Run tests with coverage
echo "🧪 Running tests with coverage..."
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=80
echo "✅ Tests passed with sufficient coverage"
echo ""

# Run pre-commit hooks
echo "🔍 Running pre-commit hooks..."
uv run pre-commit run --all-files
echo "✅ Pre-commit hooks passed"
echo ""

echo "🎉 All CI checks passed successfully!"
