#!/bin/bash
#
# pr_cleanup.sh
# Closes all open pull requests in the current GitHub repo and deletes their branches.
# Note: GitHub does not support truly deleting PRs — they can only be closed.
# Requires the GitHub CLI (gh) to be installed and authenticated.
#

set -euo pipefail

echo "Fetching open pull requests..."
pr_numbers=$(gh pr list --state open --json number --jq '.[].number' --limit 999)

if [ -z "$pr_numbers" ]; then
  echo "No open pull requests found. Nothing to do."
  exit 0
fi

total=$(echo "$pr_numbers" | wc -l | tr -d ' ')

echo ""
echo "Open pull requests to close:"
gh pr list --state open --limit 999
echo ""
echo "Total: $total"
echo ""
read -r -p "Close all $total open pull request(s) and delete their branches? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
closed=0
for pr in $pr_numbers; do
  echo "Closing PR #${pr}..."
  if gh pr close "$pr" --delete-branch 2>/dev/null; then
    closed=$((closed + 1))
  elif gh pr close "$pr" 2>/dev/null; then
    # Retry without --delete-branch in case the branch is already gone
    closed=$((closed + 1))
  else
    echo "  Warning: failed to close PR #${pr}"
  fi
done

echo ""
echo "Done. Closed $closed pull request(s)."
