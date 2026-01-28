#!/usr/bin/env zsh
set -euo pipefail

# Get GitHub Copilot comments from a PR and format them for Claude
#
# PURPOSE:
#   Fetches all comments made by GitHub Copilot on a pull request and formats
#   them as Markdown so you can copy/paste them into Claude for review.
#
# USAGE:
#   1. Run the script with a PR number:
#      ❯ etc/get-copilot-pr-comments.zsh 1577
#
#   2. Copy the output to clipboard (on Mac OS):
#      ❯ etc/get-copilot-pr-comments.zsh 1577 | pbcopy
#      Then paste directly into Claude in VS Code
#
#      TODO see if this works with xclip in a dev container.
#
#   3. Or save to a file:
#      ❯ etc/get-copilot-pr-comments.zsh 1577 > copilot-comments.md
#
# REQUIREMENTS:
#   - GitHub CLI (gh) must be installed: brew install gh
#   - Must be authenticated: gh auth login
#
# WHAT IT DOES:
#   - Fetches both review comments (on specific lines) and general comments
#   - Filters for comments from github-copilot[bot]
#   - Formats them with file paths, line numbers, and timestamps
#   - Outputs Markdown ready to paste into Claude

REPO_OWNER="dexcom-inc"
REPO_NAME="sre"

usage() {
    cat << EOF
Usage: $(basename "$0") PR_NUMBER

Get all GitHub Copilot comments from a PR and format them for Claude in VS Code.

Arguments:
  PR_NUMBER    The pull request number

Examples:
  ❯ $(basename "$0") 1577
  ❯ $(basename "$0") 1577 | pbcopy  # Copy to clipboard on macOS
  ❯ $(basename "$0") 1577 | xclip -selection clipboard  # Copy to clipboard on Linux

Environment:
  GH_TOKEN or GITHUB_TOKEN must be set for authentication
EOF
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

PR_NUMBER="$1"

# Check for gh CLI first
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed. Install with: brew install gh" >&2
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub. Run: gh auth login" >&2
    exit 1
fi

echo "Fetching comments from PR #${PR_NUMBER}..." >&2
echo "" >&2

# Fetch PR details
pr_title=$(gh pr view "$PR_NUMBER" --repo "${REPO_OWNER}/${REPO_NAME}" --json title -q '.title')
pr_url=$(gh pr view "$PR_NUMBER" --repo "${REPO_OWNER}/${REPO_NAME}" --json url -q '.url')

# Fetch all comments (review comments + issue comments)
# Write directly to temp files to avoid shell variable escaping issues
temp_file=$(mktemp)
temp_review=$(mktemp)
temp_issue=$(mktemp)
trap "rm -f '$temp_file' '$temp_review' '$temp_issue'" EXIT

gh api \
    "/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}/comments" \
    --paginate \
    --jq '.[] | select(.user.login == "github-copilot[bot]" or .user.login == "copilot" or .user.login == "Copilot" or .user.login == "copilot-pull-request-reviewer") | {
        type: "review",
        author: .user.login,
        path: .path,
        line: .line,
        body: .body,
        created_at: .created_at
    }' > "$temp_review"

gh api \
    "/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" \
    --paginate \
    --jq '.[] | select(.user.login == "github-copilot[bot]" or .user.login == "copilot" or .user.login == "Copilot" or .user.login == "copilot-pull-request-reviewer") | {
        type: "general",
        author: .user.login,
        body: .body,
        created_at: .created_at
    }' > "$temp_issue"

# Combine results - use jq -s to slurp each file into array, then concatenate
jq -s '.' "$temp_review" > "${temp_file}.1"
jq -s '.' "$temp_issue" > "${temp_file}.2"
jq -s 'add' "${temp_file}.1" "${temp_file}.2" > "$temp_file"
rm "${temp_file}.1" "${temp_file}.2"

comment_count=$(jq 'length' < "$temp_file")

if [[ "$comment_count" -eq 0 ]]; then
    echo "No GitHub Copilot comments found on PR #${PR_NUMBER}" >&2
    exit 0
fi

echo "Found ${comment_count} Copilot comment(s)" >&2
echo "" >&2
echo "Output below (copy and paste to Claude):" >&2
printf '=%.0s' {1..80} >&2
echo "" >&2

# Output formatted for Claude
cat << EOF
# GitHub Copilot Comments from PR #${PR_NUMBER}

**PR Title**: ${pr_title}
**PR URL**: ${pr_url}

---

EOF

jq -r '.[] |
if .type == "review" then
    "## Review Comment on \(.path)\n\n**Line**: \(.line // "N/A")\n**Date**: \(.created_at)\n\n\(.body)\n\n---\n"
else
    "## General Comment\n\n**Date**: \(.created_at)\n\n\(.body)\n\n---\n"
end' < "$temp_file"

echo "" >&2
printf '=%.0s' {1..80} >&2
echo "" >&2
echo "✓ Done! Copy the output above and paste into Claude." >&2
