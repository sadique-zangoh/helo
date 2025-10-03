# Contributing Guidelines

## Development Workflow

### Branch Strategy

- **Main Branch**: Protected branch that requires pull requests
- **Feature Branches**: All development work must be done in feature branches

### Creating a Pull Request

1. **Create a feature branch from main**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes and commit**:
   ```bash
   git add .
   git commit -m "feat: your descriptive commit message"
   ```

3. **Push your feature branch**:
   ```bash
   git push -u origin feature/your-feature-name
   ```

4. **Create a pull request**:
   - Use GitHub CLI: `gh pr create --title "Your PR Title" --body "Description"`
   - Or use GitHub web interface

### Important Rules

- ❌ **Never create PRs directly from the main branch**
- ✅ **Always use feature branches for development**
- ✅ **Ensure all tests pass before creating a PR**
- ✅ **Run pre-commit hooks before pushing**

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality:

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

### Development Tools

- **uv**: Fast Python package manager
- **ruff**: Python linter
- **black**: Code formatter
- **mypy**: Type checker
- **pytest**: Testing framework

### Setting Up Development Environment

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Sync dependencies
uv sync

# Run tests
uv run pytest

# Run with coverage
uv run pytest --cov=src --cov-report=term-missing
```
