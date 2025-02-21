#!/usr/bin/env bash

# This script performs a sparse checkout to pull only specific folders
# from the github repo.

set -e 

REPO_URL=${1:-"https://github.com/NeddieSeagoon/slog.git"}
BRANCH_NAME=${2:-"master"}

echo "Repository URL: $REPO_URL"
echo "Branch Name:    $BRANCH_NAME"


mkdir -p slog
cd slog

git init

git remote add origin "$REPO_URL"

git config core.sparseCheckout true

echo "server/*" >> .git/info/sparse-checkout
echo "scripts/*" >> .git/info/sparse-checkout

git fetch origin "$BRANCH_NAME"

git checkout -b "$BRANCH_NAME" --track "origin/$BRANCH_NAME"
echo "Sparse checkout complete. Pulled server/ and scripts/ dirs."
