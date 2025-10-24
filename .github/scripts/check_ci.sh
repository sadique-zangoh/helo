#!/bin/bash
# CI Monitoring Script for GitHub Actions
# Usage: ./.github/scripts/check_ci.sh [--verbose|--debug] [--json]
#
# Options:
#   --verbose, -v    Enable verbose logging (INFO level)
#   --debug, -d      Enable debug logging (DEBUG level)
#   --json           Output results in JSON format
#   --help, -h       Show this help message

set -euo pipefail

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

# Log levels: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
LOG_LEVEL=2  # Default: WARN
OUTPUT_JSON=false
SCRIPT_START_TIME=$(date +%s)

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_debug() {
    if [ "$LOG_LEVEL" -le 0 ]; then
        echo -e "${GRAY}[DEBUG]${NC} $*" >&2
    fi
}

log_info() {
    if [ "$LOG_LEVEL" -le 1 ]; then
        echo -e "${BLUE}[INFO]${NC} $*" >&2
    fi
}

log_warn() {
    if [ "$LOG_LEVEL" -le 2 ]; then
        echo -e "${YELLOW}[WARN]${NC} $*" >&2
    fi
}

log_error() {
    if [ "$LOG_LEVEL" -le 3 ]; then
        echo -e "${RED}[ERROR]${NC} $*" >&2
    fi
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Global error tracking
ERRORS=()
WARNINGS=()

# Track error with context
add_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    ERRORS+=("$error_msg (code: $error_code)")
    log_error "$error_msg"
}

# Track warning with context
add_warning() {
    local warn_msg="$1"
    WARNINGS+=("$warn_msg")
    log_warn "$warn_msg"
}

# Error handler for unexpected failures
error_handler() {
    local line_no=$1
    local bash_lineno=$2
    local command="$3"
    add_error "Unexpected error at line $line_no: command '$command' failed" "$?"
    cleanup_and_exit 1
}

# Set error trap
trap 'error_handler ${LINENO} ${BASH_LINENO} "$BASH_COMMAND"' ERR

# ============================================================================
# CLEANUP AND EXIT
# ============================================================================

cleanup_and_exit() {
    local exit_code=${1:-0}
    local script_end_time=$(date +%s)
    local duration=$((script_end_time - SCRIPT_START_TIME))

    log_debug "Script execution time: ${duration}s"

    if [ ${#ERRORS[@]} -gt 0 ]; then
        log_error "Script completed with ${#ERRORS[@]} error(s) and ${#WARNINGS[@]} warning(s)"
    elif [ ${#WARNINGS[@]} -gt 0 ]; then
        log_warn "Script completed with ${#WARNINGS[@]} warning(s)"
    else
        log_debug "Script completed successfully"
    fi

    exit "$exit_code"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

show_help() {
    cat << EOF
CI Monitoring Script for GitHub Actions

Usage: $0 [OPTIONS]

Options:
    -v, --verbose       Enable verbose logging (INFO level)
    -d, --debug         Enable debug logging (DEBUG level)
    -j, --json          Output results in JSON format
    -h, --help          Show this help message

Examples:
    $0                  # Run with default settings (WARN level)
    $0 --verbose        # Run with INFO level logging
    $0 --debug          # Run with DEBUG level logging
    $0 --json           # Output results as JSON

Environment Variables:
    GITHUB_TOKEN        GitHub API token for authenticated requests
    LOG_LEVEL          Override log level (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR)

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            LOG_LEVEL=1
            log_info "Verbose logging enabled"
            shift
            ;;
        -d|--debug)
            LOG_LEVEL=0
            log_debug "Debug logging enabled"
            shift
            ;;
        -j|--json)
            OUTPUT_JSON=true
            log_debug "JSON output enabled"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            add_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# ============================================================================
# ENVIRONMENT VALIDATION
# ============================================================================

log_debug "Starting CI monitoring script"
log_debug "Working directory: $(pwd)"
log_debug "User: $(whoami)"
log_debug "Shell: $SHELL"

# Check required commands
REQUIRED_COMMANDS=("git" "curl" "python3")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        add_error "Required command '$cmd' not found in PATH"
        cleanup_and_exit 1
    else
        log_debug "Found command: $cmd at $(command -v "$cmd")"
    fi
done

# Validate git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    add_error "Not in a git repository"
    cleanup_and_exit 1
fi

log_debug "Git repository validated"

# ============================================================================
# REPOSITORY INFORMATION EXTRACTION
# ============================================================================

log_info "Extracting repository information..."

# Extract repository information with error handling
if ! REMOTE_URL=$(git config --get remote.origin.url 2>&1); then
    add_error "Failed to get git remote URL: $REMOTE_URL"
    cleanup_and_exit 1
fi

log_debug "Remote URL: $REMOTE_URL"

# Parse repository full name
REPO_FULL_NAME=$(echo "$REMOTE_URL" | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*@//' | sed 's/https:\/\///' | sed 's/http:\/\///')

if [ -z "$REPO_FULL_NAME" ] || [[ ! "$REPO_FULL_NAME" =~ ^[^/]+/[^/]+$ ]]; then
    add_error "Failed to parse repository name from URL: $REMOTE_URL"
    cleanup_and_exit 1
fi

log_debug "Repository full name: $REPO_FULL_NAME"

REPO_OWNER=$(echo "$REPO_FULL_NAME" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_FULL_NAME" | cut -d'/' -f2)

log_debug "Repository owner: $REPO_OWNER"
log_debug "Repository name: $REPO_NAME"

# Get current branch with error handling
if ! BRANCH=$(git rev-parse --abbrev-ref HEAD 2>&1); then
    add_error "Failed to get current branch: $BRANCH"
    cleanup_and_exit 1
fi

log_debug "Current branch: $BRANCH"

# Get commit SHA
COMMIT_SHA=$(git rev-parse HEAD 2>&1) || {
    add_warning "Failed to get commit SHA: $COMMIT_SHA"
    COMMIT_SHA="unknown"
}

log_debug "Current commit: $COMMIT_SHA"

# ============================================================================
# DISPLAY HEADER (unless JSON output)
# ============================================================================

if [ "$OUTPUT_JSON" = "false" ]; then
    echo "========================================="
    echo "CI Monitoring for $REPO_FULL_NAME"
    echo "Branch: $BRANCH"
    echo "Commit: ${COMMIT_SHA:0:8}"
    echo "========================================="
    echo
fi

# ============================================================================
# GITHUB API AUTHENTICATION
# ============================================================================

log_info "Checking GitHub API authentication..."

if [ -z "${GITHUB_TOKEN:-}" ]; then
    add_warning "GITHUB_TOKEN not set - using unauthenticated API access (rate limited)"
    if [ "$OUTPUT_JSON" = "false" ]; then
        echo "⚠️  GITHUB_TOKEN not set - limited API access"
        echo
    fi
    AUTH_HEADER=""
else
    log_debug "GitHub token found (length: ${#GITHUB_TOKEN})"
    AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
    log_info "Using authenticated GitHub API access"
fi

# ============================================================================
# GITHUB API REQUEST
# ============================================================================

log_info "Fetching CI status from GitHub API..."

API_URL="https://api.github.com/repos/$REPO_FULL_NAME/actions/runs"
QUERY_PARAMS="branch=$BRANCH&per_page=5"
FULL_URL="$API_URL?$QUERY_PARAMS"

log_debug "API URL: $FULL_URL"

# Execute API request with error handling
if [ -n "$AUTH_HEADER" ]; then
    HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -H "$AUTH_HEADER" "$FULL_URL" 2>&1) || {
        add_error "curl command failed: $HTTP_RESPONSE"
        cleanup_and_exit 1
    }
else
    HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" "$FULL_URL" 2>&1) || {
        add_error "curl command failed: $HTTP_RESPONSE"
        cleanup_and_exit 1
    }
fi

log_debug "Curl request completed"

# Split response into body and status code
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)

log_debug "HTTP Status Code: $HTTP_CODE"
log_debug "Response body length: ${#HTTP_BODY} bytes"

# Validate HTTP status code
if [ "$HTTP_CODE" -ne 200 ]; then
    case "$HTTP_CODE" in
        401)
            add_error "GitHub API authentication failed (401 Unauthorized)"
            add_error "Check your GITHUB_TOKEN"
            ;;
        403)
            add_error "GitHub API forbidden (403 Forbidden)"
            add_error "Token may lack required permissions or rate limit exceeded"
            ;;
        404)
            add_error "Repository not found (404 Not Found)"
            add_error "Check repository name: $REPO_FULL_NAME"
            ;;
        *)
            add_error "GitHub API request failed with HTTP $HTTP_CODE"
            ;;
    esac

    log_debug "Response body: $HTTP_BODY"
    cleanup_and_exit 1
fi

log_info "Successfully retrieved data from GitHub API"

# ============================================================================
# JSON VALIDATION
# ============================================================================

log_info "Validating API response..."

if ! echo "$HTTP_BODY" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    add_error "Invalid JSON response from GitHub API"
    log_debug "Response: $HTTP_BODY"
    cleanup_and_exit 1
fi

log_debug "JSON response validated"

# ============================================================================
# PARSE AND DISPLAY RESULTS
# ============================================================================

log_info "Parsing workflow runs..."

# Create temporary Python script
TEMP_PY=$(mktemp /tmp/check_ci_XXXXXX.py)
cat > "$TEMP_PY" << 'PYTHON_SCRIPT'
import sys
import json
from datetime import datetime

# Read configuration from command line arguments
output_json = sys.argv[1].lower() == 'true' if len(sys.argv) > 1 else False
log_level = int(sys.argv[2]) if len(sys.argv) > 2 else 2

def log_debug(msg):
    if log_level <= 0:
        print(f"[DEBUG] {msg}", file=sys.stderr)

def log_info(msg):
    if log_level <= 1:
        print(f"[INFO] {msg}", file=sys.stderr)

try:
    data = json.load(sys.stdin)
    log_debug(f"Loaded JSON data with {len(data)} top-level keys")
except json.JSONDecodeError as e:
    print(json.dumps({"error": f"JSON decode error: {str(e)}"}))
    sys.exit(1)

total_count = data.get('total_count', 0)
runs = data.get('workflow_runs', [])

log_info(f"Total workflow runs: {total_count}")
log_info(f"Runs in response: {len(runs)}")

result = {
    "total_count": total_count,
    "runs": [],
    "summary": {
        "all_success": True,
        "completed": 0,
        "in_progress": 0,
        "failed": 0,
        "cancelled": 0
    }
}

if total_count == 0:
    result["message"] = "No CI runs found"
    if not output_json:
        print("📊 Latest Workflow Runs:")
        print("------------------------")
        print("ℹ️  No CI runs found for this branch")
        print("   This could mean:")
        print("   - No workflows have run yet on this branch")
        print("   - Workflows are not configured")
        print("   - Branch hasn't been pushed to remote")
        print()
    else:
        print(json.dumps(result, indent=2))
    sys.exit(0)

if not output_json:
    print("📊 Latest Workflow Runs:")
    print("------------------------")
    print()

for i, run in enumerate(runs[:5], 1):
    name = run.get('name', 'Unknown')
    status = run.get('status', 'unknown')
    conclusion = run.get('conclusion', 'N/A')
    created = run.get('created_at', 'unknown')
    updated = run.get('updated_at', 'unknown')
    html_url = run.get('html_url', '')
    run_number = run.get('run_number', 0)
    event = run.get('event', 'unknown')

    log_debug(f"Processing run #{run_number}: {name} ({status}/{conclusion})")

    # Determine icon and status
    if status == 'completed':
        result["summary"]["completed"] += 1
        if conclusion == 'success':
            icon = "✅"
        elif conclusion == 'failure':
            icon = "❌"
            result["summary"]["failed"] += 1
            result["summary"]["all_success"] = False
        elif conclusion == 'cancelled':
            icon = "⚪"
            result["summary"]["cancelled"] += 1
        else:
            icon = "⚠️"
            result["summary"]["all_success"] = False
    elif status == 'in_progress':
        icon = "🔄"
        result["summary"]["in_progress"] += 1
    else:
        icon = "⏸️"

    run_info = {
        "number": run_number,
        "name": name,
        "status": status,
        "conclusion": conclusion,
        "event": event,
        "created_at": created,
        "updated_at": updated,
        "url": html_url
    }

    result["runs"].append(run_info)

    if not output_json:
        print(f"{i}. {icon} {name} (#{run_number})")
        print(f"   Status: {status} | Conclusion: {conclusion}")
        print(f"   Event: {event}")
        print(f"   Created: {created}")
        print(f"   Updated: {updated}")
        print(f"   URL: {html_url}")
        print()

if not output_json:
    # Summary
    print("="*50)
    print(f"Summary: {result['summary']['completed']} completed, "
          f"{result['summary']['in_progress']} in progress, "
          f"{result['summary']['failed']} failed, "
          f"{result['summary']['cancelled']} cancelled")
    print("="*50)

    if result["summary"]["all_success"] and result["summary"]["completed"] > 0:
        print("✅ All recent CI checks passed!")
        exit_code = 0
    elif result["summary"]["in_progress"] > 0:
        print("🔄 CI checks in progress...")
        exit_code = 0
    else:
        print("❌ Some CI checks failed or are incomplete")
        exit_code = 1
else:
    print(json.dumps(result, indent=2))
    exit_code = 0 if result["summary"]["all_success"] else 1

sys.exit(exit_code)

PYTHON_SCRIPT

log_debug "Created temporary Python script: $TEMP_PY"

# Execute Python script with proper arguments
PYTHON_OUTPUT=$(echo "$HTTP_BODY" | python3 "$TEMP_PY" "$OUTPUT_JSON" "$LOG_LEVEL" 2>&1)
PYTHON_EXIT_CODE=$?

# Clean up temporary file
rm -f "$TEMP_PY"
log_debug "Removed temporary Python script"

# Output Python results
echo "$PYTHON_OUTPUT"

# ============================================================================
# FINAL STATUS AND CLEANUP
# ============================================================================

log_info "CI monitoring check complete"

if [ $PYTHON_EXIT_CODE -eq 0 ]; then
    log_success "CI status check successful"
    cleanup_and_exit 0
else
    add_error "CI status check detected failures"
    cleanup_and_exit 1
fi
