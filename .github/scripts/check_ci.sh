#!/bin/bash
# CI Monitoring Script for GitHub Actions
# Usage: ./.github/scripts/check_ci.sh

set -e

REPO_FULL_NAME=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*@//')
REPO_OWNER=$(echo "$REPO_FULL_NAME" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_FULL_NAME" | cut -d'/' -f2)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "========================================="
echo "CI Monitoring for $REPO_FULL_NAME"
echo "Branch: $BRANCH"
echo "========================================="
echo

# Check if GitHub token is available
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN not set - limited API access"
    echo
fi

# Get latest workflow runs for current branch
echo "📊 Latest Workflow Runs:"
echo "------------------------"

API_URL="https://api.github.com/repos/$REPO_FULL_NAME/actions/runs"
CURL_OPTS="-s"

if [ -n "$GITHUB_TOKEN" ]; then
    CURL_OPTS="$CURL_OPTS -H \"Authorization: token $GITHUB_TOKEN\""
fi

RUNS=$(eval curl $CURL_OPTS "$API_URL?branch=$BRANCH&per_page=5")

# Check if we got valid JSON
if ! echo "$RUNS" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "❌ Failed to retrieve CI status from GitHub API"
    exit 1
fi

TOTAL_COUNT=$(echo "$RUNS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total_count', 0))")

if [ "$TOTAL_COUNT" -eq 0 ]; then
    echo "ℹ️  No CI runs found for branch '$BRANCH'"
    echo "   This could mean:"
    echo "   - No workflows have run yet on this branch"
    echo "   - Workflows are not configured"
    echo "   - Branch hasn't been pushed to remote"
    echo
    exit 0
fi

echo "$RUNS" | python3 << 'PYTHON_SCRIPT'
import sys, json
from datetime import datetime

data = json.load(sys.stdin)
runs = data.get('workflow_runs', [])

if not runs:
    print("No recent runs found")
    sys.exit(0)

all_success = True

for i, run in enumerate(runs[:5], 1):
    name = run['name']
    status = run['status']
    conclusion = run.get('conclusion', 'N/A')
    created = run['created_at']
    html_url = run['html_url']

    # Determine icon based on status/conclusion
    if status == 'completed':
        if conclusion == 'success':
            icon = "✅"
        elif conclusion == 'failure':
            icon = "❌"
            all_success = False
        elif conclusion == 'cancelled':
            icon = "⚪"
        else:
            icon = "⚠️"
            all_success = False
    elif status == 'in_progress':
        icon = "🔄"
    else:
        icon = "⏸️"

    print(f"{i}. {icon} {name}")
    print(f"   Status: {status} | Conclusion: {conclusion}")
    print(f"   Created: {created}")
    print(f"   URL: {html_url}")
    print()

# Overall status
print("="*40)
if all_success:
    print("✅ All recent CI checks passed!")
    sys.exit(0)
else:
    print("❌ Some CI checks failed or are incomplete")
    sys.exit(1)

PYTHON_SCRIPT
