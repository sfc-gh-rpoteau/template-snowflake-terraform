#!/usr/bin/env bash
#
# changed-deployments.sh
#
# Determines which <env_dir>/<deployment>/ directories are affected
# by a set of changed files. Handles both direct changes and transitive
# module dependencies.
#
# Usage:
#   ./changed-deployments.sh "file1 file2 file3" "environments/development"
#   echo "file1 file2" | ./changed-deployments.sh "" "environments/staging"
#
# Arguments:
#   $1 - Space-separated list of changed files (or "" to read from stdin)
#   $2 - Environment directory prefix (e.g. environments/development)
#
# Output: JSON array of affected deployment directories
#   e.g., ["environments/development/terraform_db","environments/development/e2e_ml_quickstart"]

set -euo pipefail

# Get changed files from first argument or stdin
if [[ $# -gt 0 && -n "$1" ]]; then
  CHANGED_FILES="$1"
else
  CHANGED_FILES=$(cat)
fi

# Environment directory (required)
ENV_DIR="${2:?Usage: $0 <changed_files> <env_dir>}"

# Exit early if no changed files
if [[ -z "${CHANGED_FILES}" ]]; then
  echo "[]"
  exit 0
fi

# Find the repository root (where environments/ and modules/ live)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Temporary files for module-to-deployment mapping
MODULE_MAP_FILE=$(mktemp)
AFFECTED_FILE=$(mktemp)
trap 'rm -f "$MODULE_MAP_FILE" "$AFFECTED_FILE"' EXIT

# Build a mapping of module names to deployments that use them
# by parsing source = "...modules/<name>" in each deployment's main.tf
for main_tf in "${REPO_ROOT}"/${ENV_DIR}/*/main.tf; do
  if [[ ! -f "$main_tf" ]]; then
    continue
  fi
  
  # Extract deployment directory path (relative)
  deployment_dir=$(dirname "$main_tf")
  deployment_dir=${deployment_dir#"${REPO_ROOT}/"}  # Remove repo root prefix
  
  # Find all module sources in this main.tf
  # Matches: source = "...modules/module_name"
  grep -oE 'source\s*=\s*"[^"]*modules/[^"]*"' "$main_tf" 2>/dev/null | while read -r line; do
    # Extract module name from source path like ../../../modules/terraform_db
    module_name=$(echo "$line" | sed -E 's/.*modules\/([^"]+)".*/\1/')
    if [[ -n "$module_name" ]]; then
      echo "${module_name}:${deployment_dir}" >> "$MODULE_MAP_FILE"
    fi
  done || true
done

# Process each changed file
for changed_file in $CHANGED_FILES; do
  # Case 1: File is in <env_dir>/<deployment>/
  if [[ "$changed_file" == ${ENV_DIR}/*/* ]]; then
    # Extract <env_dir>/<deployment>
    deployment_dir=$(echo "$changed_file" | awk -F/ '{print $1"/"$2"/"$3}')
    echo "$deployment_dir" >> "$AFFECTED_FILE"
  fi
  
  # Case 2: File is in modules/<module>/
  if [[ "$changed_file" == modules/*/* ]]; then
    # Extract module name (second path component)
    module_name=$(echo "$changed_file" | awk -F/ '{print $2}')
    
    # Find all deployments that reference this module
    if [[ -f "$MODULE_MAP_FILE" ]]; then
      grep "^${module_name}:" "$MODULE_MAP_FILE" 2>/dev/null | cut -d: -f2 >> "$AFFECTED_FILE" || true
    fi
  fi
done

# Output as JSON array
if [[ ! -s "$AFFECTED_FILE" ]]; then
  echo "[]"
else
  # Sort, dedupe, and format as JSON array
  sort -u "$AFFECTED_FILE" | jq -R -s -c 'split("\n") | map(select(length > 0))'
fi
