#!/bin/bash
# helm-template-all.sh - Comprehensive Helm template validation
# Validates all Helm charts in the repository (custom charts, values-only charts, and ApplicationSets)

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common library
# shellcheck source=lib/helm-common.sh
source "${SCRIPT_DIR}/lib/helm-common.sh"

# Check dependencies
check_dependencies helm yq || exit 1

# Find repository root
REPO_ROOT=$(find_repo_root) || exit 1

log_info "Starting comprehensive Helm validation"
log_info "Repository root: $REPO_ROOT"

# Track validation results
TOTAL_CHARTS=0
PASSED_CHARTS=0
FAILED_CHARTS=0
SKIPPED_CHARTS=0

# Validate all charts
log_info "Scanning for charts ..."

while IFS= read -r chart_dir; do
  TOTAL_CHARTS=$((TOTAL_CHARTS + 1))
  chart_name=$(basename "$chart_dir")

  # Determine chart type and validate accordingly
  if is_custom_chart "$chart_dir"; then
    # Custom chart with Chart.yaml
    if validate_custom_chart "$chart_dir"; then
      PASSED_CHARTS=$((PASSED_CHARTS + 1))
    else
      FAILED_CHARTS=$((FAILED_CHARTS + 1))
    fi

  elif is_values_only_chart "$chart_dir"; then
    # Skip git-based charts
    if is_git_chart "$CHART_NAME"; then
      log_warn "$chart_name: Skipping validation (git-based chart)"
      SKIPPED_CHARTS=$((SKIPPED_CHARTS + 1))
      continue
    fi

    # Validate values-only chart
    if validate_values_only_chart "${chart_dir}/values.yaml" "$CHART_NAME" "$REPO_URL" "$TARGET_REVISION"; then
      PASSED_CHARTS=$((PASSED_CHARTS + 1))
    else
      FAILED_CHARTS=$((FAILED_CHARTS + 1))
    fi

  else
    log_warn "$chart_name: Unknown chart type, skipping"
    SKIPPED_CHARTS=$((SKIPPED_CHARTS + 1))
  fi
done < <(get_chart_directories "$REPO_ROOT")

log_success "All validations passed!"
exit 0
