#!/bin/bash
#
# wfrun_cleanup.sh
# Deletes all GitHub Actions workflow runs with conclusion "success" or "failure".
# Requires the GitHub CLI (gh) to be installed and authenticated.
#

set -euo pipefail

echo "Fetching workflow runs with conclusion 'failure'..."
failure_ids=$(gh run list --limit 999 --json databaseId,conclusion \
  --jq '[.[] | select(.conclusion == "failure")] | .[].databaseId')

echo "Fetching workflow runs with conclusion 'success'..."
success_ids=$(gh run list --limit 999 --json databaseId,conclusion \
  --jq '[.[] | select(.conclusion == "success")] | .[].databaseId')

all_ids=$(echo -e "${failure_ids}\n${success_ids}" | sed '/^$/d' | sort -u)

if [ -z "$all_ids" ]; then
  echo "No completed (success/failure) workflow runs found. Nothing to delete."
  exit 0
fi

failure_count=$(echo "$failure_ids" | sed '/^$/d' | wc -l | tr -d ' ')
success_count=$(echo "$success_ids" | sed '/^$/d' | wc -l | tr -d ' ')
total_count=$(echo "$all_ids" | wc -l | tr -d ' ')

echo ""
echo "Found workflow runs to delete:"
echo "  Failure: $failure_count"
echo "  Success: $success_count"
echo "  Total:   $total_count"
echo ""
read -r -p "Delete all $total_count workflow runs? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
deleted=0
for id in $all_ids; do
  echo "Deleting run $id..."
  if gh run delete "$id" 2>/dev/null; then
    deleted=$((deleted + 1))
  else
    echo "  Warning: failed to delete run $id (may already be deleted)"
  fi
done

echo ""
echo "Done. Deleted $deleted workflow run(s)."
