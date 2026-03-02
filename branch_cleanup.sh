#!/bin/bash
#
# branch_cleanup.sh
# Deletes all branches (local and remote) except 'main'.
# Must be run from the repository root while on the 'main' branch.
#

set -euo pipefail

KEEP_BRANCH="main"
REMOTE="origin"

# Ensure we're on the branch we want to keep
current=$(git branch --show-current)
if [ "$current" != "$KEEP_BRANCH" ]; then
  echo "ERROR: You must be on the '$KEEP_BRANCH' branch to run this script."
  echo "  Currently on: $current"
  exit 1
fi

# --- Delete local branches ---
local_branches=$(git branch --format='%(refname:short)' | grep -v "^${KEEP_BRANCH}$" || true)

if [ -n "$local_branches" ]; then
  echo "Local branches to delete:"
  echo "$local_branches" | sed 's/^/  /'
  echo ""
  read -r -p "Delete these local branches? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "$local_branches" | xargs git branch -D
    echo "Local branches deleted."
  else
    echo "Skipped local branch deletion."
  fi
else
  echo "No local branches to delete."
fi

echo ""

# --- Delete remote branches ---
remote_branches=$(git branch -r --format='%(refname:short)' \
  | grep "^${REMOTE}/" \
  | grep -v "^${REMOTE}/${KEEP_BRANCH}$" \
  | grep -v "^${REMOTE}/HEAD$" \
  | sed "s|^${REMOTE}/||" || true)

if [ -n "$remote_branches" ]; then
  echo "Remote branches to delete on '${REMOTE}':"
  echo "$remote_branches" | sed 's/^/  /'
  echo ""
  read -r -p "Delete these remote branches? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "$remote_branches" | xargs -I{} git push "$REMOTE" --delete "{}"
    echo "Remote branches deleted."
  else
    echo "Skipped remote branch deletion."
  fi
else
  echo "No remote branches to delete."
fi

echo ""
echo "Done. Pruning stale remote-tracking references..."
git remote prune "$REMOTE"
echo "Cleanup complete."
