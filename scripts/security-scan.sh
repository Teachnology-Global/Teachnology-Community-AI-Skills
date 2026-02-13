#!/bin/bash
#
# Unified Security Scan Script
# Part of Cursor Governance Skills
#
# Usage: ./security-scan.sh [path] [--sast-only|--sca-only|--secrets-only]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default path
SCAN_PATH="${1:-.}"
SCAN_TYPE="${2:-all}"

# Results tracking
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
SECRETS_COUNT=0

echo "================================================"
echo "  Cursor Governance - Security Gate"
echo "================================================"
echo ""
echo "Scan Path: $SCAN_PATH"
echo "Scan Type: $SCAN_TYPE"
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 not found. Skipping.${NC}"
        return 1
    fi
    return 0
}

# SAST Scan
run_sast() {
    echo "----------------------------------------"
    echo "Running SAST (Static Analysis)..."
    echo "----------------------------------------"
    
    if check_tool semgrep; then
        semgrep --config=auto \
            --severity ERROR --severity WARNING \
            --json "$SCAN_PATH" > /tmp/sast-results.json 2>/dev/null || true
        
        if [ -f /tmp/sast-results.json ]; then
            SAST_ERRORS=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' /tmp/sast-results.json 2>/dev/null || echo "0")
            SAST_WARNINGS=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' /tmp/sast-results.json 2>/dev/null || echo "0")
            
            CRITICAL_COUNT=$((CRITICAL_COUNT + SAST_ERRORS))
            HIGH_COUNT=$((HIGH_COUNT + SAST_WARNINGS))
            
            echo -e "SAST Results: ${RED}$SAST_ERRORS critical${NC}, ${YELLOW}$SAST_WARNINGS high${NC}"
        fi
    fi
}

# SCA Scan
run_sca() {
    echo "----------------------------------------"
    echo "Running SCA (Dependency Scan)..."
    echo "----------------------------------------"
    
    if check_tool trivy; then
        trivy fs --severity CRITICAL,HIGH \
            --format json "$SCAN_PATH" > /tmp/sca-results.json 2>/dev/null || true
        
        if [ -f /tmp/sca-results.json ]; then
            SCA_CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' /tmp/sca-results.json 2>/dev/null || echo "0")
            SCA_HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' /tmp/sca-results.json 2>/dev/null || echo "0")
            
            CRITICAL_COUNT=$((CRITICAL_COUNT + SCA_CRITICAL))
            HIGH_COUNT=$((HIGH_COUNT + SCA_HIGH))
            
            echo -e "SCA Results: ${RED}$SCA_CRITICAL critical${NC}, ${YELLOW}$SCA_HIGH high${NC}"
        fi
    fi
}

# Secrets Scan
run_secrets() {
    echo "----------------------------------------"
    echo "Running Secret Detection..."
    echo "----------------------------------------"
    
    if check_tool gitleaks; then
        gitleaks detect --source="$SCAN_PATH" \
            --report-format json \
            --report-path /tmp/secrets-results.json 2>/dev/null || true
        
        if [ -f /tmp/secrets-results.json ]; then
            SECRETS_COUNT=$(jq 'length' /tmp/secrets-results.json 2>/dev/null || echo "0")
            
            if [ "$SECRETS_COUNT" -gt 0 ]; then
                echo -e "${RED}SECRETS DETECTED: $SECRETS_COUNT${NC}"
                CRITICAL_COUNT=$((CRITICAL_COUNT + SECRETS_COUNT))
            else
                echo -e "${GREEN}No secrets detected${NC}"
            fi
        fi
    fi
}

# Run scans based on type
case $SCAN_TYPE in
    --sast-only)
        run_sast
        ;;
    --sca-only)
        run_sca
        ;;
    --secrets-only)
        run_secrets
        ;;
    *)
        run_sast
        run_sca
        run_secrets
        ;;
esac

# Summary
echo ""
echo "================================================"
echo "  Security Gate Summary"
echo "================================================"
echo ""
echo "Critical: $CRITICAL_COUNT"
echo "High:     $HIGH_COUNT"
echo "Medium:   $MEDIUM_COUNT"
echo "Low:      $LOW_COUNT"
echo ""

# Gate decision
if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
    echo -e "${RED}❌ GATE FAILED - Deployment blocked${NC}"
    echo ""
    echo "Fix critical and high findings before deploying."
    exit 1
else
    echo -e "${GREEN}✅ GATE PASSED - Deployment allowed${NC}"
    exit 0
fi

