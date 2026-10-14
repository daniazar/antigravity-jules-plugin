#!/usr/bin/env bash
set -uo pipefail

WORKSPACE_PATH="${1:-$(pwd)}"

echo "=== Google Jules Preflight Check ==="

if ! command -v jules >/dev/null 2>&1; then
  echo "STATUS: MISSING_CLI"
  echo "MESSAGE: 'jules' CLI is not found on PATH. Install Google Jules CLI first."
  exit 2
fi

VERSION_OUT=$(jules version 2>&1 | tr '\n' ' ')
echo "CLI_VERSION: ${VERSION_OUT}"

GIT_ORIGIN=$(git -C "$WORKSPACE_PATH" remote get-url origin 2>/dev/null || true)
REPO_SLUG=$(echo "$GIT_ORIGIN" | sed -nE 's#.*github\.com[:/]([^/]+/[^/.]+)(\.git)?$#\1#p')
GIT_DIRTY=$(git -C "$WORKSPACE_PATH" status --porcelain 2>/dev/null || true)

echo "GIT_ORIGIN: ${GIT_ORIGIN}"
echo "DETECTED_REPO: ${REPO_SLUG}"
if [ -z "$GIT_DIRTY" ]; then
  echo "WORKING_TREE_CLEAN: True"
else
  echo "WORKING_TREE_CLEAN: False"
fi

REPOS_OUT=$(jules remote list --repo 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ] || echo "$REPOS_OUT" | grep -Eiq "unauthenticated|not logged in|login|token expired|oauth|unauthorized|error:.*auth"; then
  echo "STATUS: AUTH_REQUIRED"
  echo "MESSAGE: Google Jules CLI authentication is missing or expired. Please run 'jules login' in your terminal to authenticate."
  echo "RAW_OUTPUT: ${REPOS_OUT}"
  exit 3
fi

REPO_COUNT=$(echo "$REPOS_OUT" | grep -cve '^\s*$' || true)
echo "STATUS: AUTHENTICATED"
echo "CONNECTED_REPO_COUNT: ${REPO_COUNT}"

if [ -n "$REPO_SLUG" ]; then
  if echo "$REPOS_OUT" | grep -Fxqi "$REPO_SLUG"; then
    echo "CURRENT_REPO_CONNECTED: True (${REPO_SLUG})"
  else
    echo "CURRENT_REPO_CONNECTED: False (${REPO_SLUG} is NOT in 'jules remote list --repo')"
  fi
fi

echo ""
echo "=== Remote Sessions ==="
jules remote list --session 2>&1
exit 0
