#!/bin/bash
set -euo pipefail

# Validation & Security Scanning Script
# Runs HCL format checks, Terraform validation, dependency graph validation,
# tflint analysis, and Trivy security scanning across all modules.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR="${1:-infrastructure/dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/$TARGET_DIR"

EXIT_CODE=0

info()    { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
fail()    { echo -e "${RED}✗ $1${NC}"; EXIT_CODE=1; }

header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# --- Dependency Check ---
header "Checking dependencies"

command -v terragrunt >/dev/null || { fail "terragrunt not found"; exit 1; }
command -v tflint >/dev/null && HAS_TFLINT=true || { warn "tflint not found — skipping lint"; HAS_TFLINT=false; }
command -v trivy >/dev/null && HAS_TRIVY=true || { warn "trivy not found — skipping security scan"; HAS_TRIVY=false; }

success "terragrunt $(terragrunt --version | head -n1)"
$HAS_TFLINT && success "tflint $(tflint --version 2>&1 | head -n1)"
$HAS_TRIVY && success "trivy $(trivy --version 2>&1 | head -n1)"

# --- HCL Format Check ---
header "HCL format check"

cd "$TARGET_DIR"
if terragrunt hcl fmt --check 2>/dev/null; then
    success "All HCL files are properly formatted"
else
    fail "HCL formatting issues found — run 'terragrunt hcl fmt' to fix"
fi

# --- Terraform Validation ---
header "Terraform validation"

cd "$TARGET_DIR"
if terragrunt run --all validate 2>&1; then
    success "All modules validated successfully"
else
    fail "Terraform validation failed"
fi

# --- Dependency Graph ---
header "Dependency graph validation"

cd "$TARGET_DIR"
if DAG_OUTPUT=$(terragrunt dag graph 2>&1); then
    success "Dependency graph is valid (no cycles)"
    echo "$DAG_OUTPUT"
else
    fail "Dependency graph validation failed"
fi

# --- TFLint ---
if $HAS_TFLINT; then
    header "TFLint analysis"

    TFLINT_FAILED=false
    for module_dir in "$PROJECT_ROOT"/infrastructure/modules/*/; do
        module_name=$(basename "$module_dir")
        cd "$module_dir"
        OUTPUT=$(tflint --config "$PROJECT_ROOT/infrastructure/modules/.tflint.hcl" 2>&1) || true
        if echo "$OUTPUT" | grep -q "Error:"; then
            echo "$OUTPUT"
            fail "$module_name — linting errors detected"
            TFLINT_FAILED=true
        elif echo "$OUTPUT" | grep -q "Warning:"; then
            echo "$OUTPUT"
            warn "$module_name — warnings (non-blocking)"
        else
            success "$module_name — no issues"
        fi
    done
    $TFLINT_FAILED || success "All modules passed linting"
fi

# --- Security Scan ---
if $HAS_TRIVY; then
    header "Security scan (Trivy)"

    cd "$PROJECT_ROOT/infrastructure/modules"
    if trivy config . --severity HIGH,CRITICAL --quiet 2>&1; then
        success "No high/critical security issues found"
    else
        fail "Security issues detected"
    fi
fi

# --- Summary ---
header "Summary"

if [ $EXIT_CODE -eq 0 ]; then
    success "All checks passed"
else
    fail "Some checks failed — review output above"
fi

exit $EXIT_CODE
