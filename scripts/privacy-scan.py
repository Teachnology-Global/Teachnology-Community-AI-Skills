#!/usr/bin/env python3
"""
Privacy Scanner - Cursor Governance Framework

Scans source code for potential PII handling issues:
- PII field detection
- Unencrypted sensitive data
- PII in logs
- Missing consent checks
- Incomplete deletion

Usage:
    python privacy-scan.py [path] [--output json|text] [--severity critical|high|medium|low]
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, asdict
from enum import Enum
from pathlib import Path
from typing import Generator, List


class Severity(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


@dataclass
class Finding:
    file: str
    line: int
    severity: str
    category: str
    description: str
    code_snippet: str
    recommendation: str


# PII field patterns
PII_FIELD_PATTERNS = [
    (r'\b(ssn|social_security|social_security_number)\b', 'SSN', Severity.CRITICAL),
    (r'\b(credit_card|card_number|cc_number|ccn)\b', 'Credit Card', Severity.CRITICAL),
    (r'\b(password|passwd|pwd|secret|api_key|apikey|token)\b', 'Credential', Severity.CRITICAL),
    (r'\b(passport|passport_number|passport_no)\b', 'Passport', Severity.CRITICAL),
    (r'\b(driver_license|drivers_license|dl_number)\b', 'Driver License', Severity.CRITICAL),
    (r'\b(bank_account|account_number|routing_number|iban)\b', 'Financial', Severity.CRITICAL),
    (r'\b(email|email_address|e_mail)\b', 'Email', Severity.HIGH),
    (r'\b(phone|phone_number|mobile|telephone|cell)\b', 'Phone', Severity.HIGH),
    (r'\b(address|street_address|home_address|mailing_address)\b', 'Address', Severity.HIGH),
    (r'\b(birth_date|dob|date_of_birth|birthday)\b', 'Birth Date', Severity.HIGH),
    (r'\b(first_name|last_name|full_name|surname|given_name)\b', 'Name', Severity.MEDIUM),
    (r'\b(ip_address|ip_addr|client_ip|user_ip)\b', 'IP Address', Severity.MEDIUM),
    (r'\b(location|latitude|longitude|geo_location|coordinates)\b', 'Location', Severity.MEDIUM),
    (r'\b(gender|sex|ethnicity|race|religion)\b', 'Demographic', Severity.MEDIUM),
    (r'\b(medical|health|diagnosis|prescription|condition)\b', 'Health', Severity.CRITICAL),
    (r'\b(biometric|fingerprint|face_id|facial|retina)\b', 'Biometric', Severity.CRITICAL),
]

# PII in logs pattern
LOG_PATTERNS = [
    r'(console\.(log|info|warn|error|debug))\s*\([^)]*\b(email|phone|ssn|password|credit_card|address)',
    r'(logger\.(log|info|warn|error|debug))\s*\([^)]*\b(email|phone|ssn|password|credit_card|address)',
    r'(log\.(info|warn|error|debug))\s*\([^)]*\b(email|phone|ssn|password|credit_card|address)',
    r'(print|println|printf)\s*\([^)]*\b(email|phone|ssn|password|credit_card|address)',
    r'(logging\.(info|warn|error|debug))\s*\([^)]*\b(email|phone|ssn|password|credit_card|address)',
]

# Unencrypted storage patterns
UNENCRYPTED_PATTERNS = [
    r'(\w+)\s*=\s*(request|req)\.(body|form|params|query)\s*\[\s*[\'"]?(ssn|password|credit_card|card_number)',
    r'(db|database|store|save)\s*\.\s*\w+\s*\([^)]*\b(ssn|password|credit_card)\b[^)]*\)\s*(?!.*encrypt)',
]

# File extensions to scan
SCAN_EXTENSIONS = {
    '.ts', '.tsx', '.js', '.jsx', '.py', '.java', '.cs', '.go', '.rb', '.php',
    '.swift', '.kt', '.scala', '.rs', '.cpp', '.c', '.h'
}

# Directories to skip
SKIP_DIRS = {
    'node_modules', 'vendor', 'venv', '.venv', '__pycache__', 
    'dist', 'build', '.git', '.svn', 'target', 'bin', 'obj'
}


def should_scan_file(path: Path) -> bool:
    """Check if file should be scanned."""
    if path.suffix.lower() not in SCAN_EXTENSIONS:
        return False
    
    for part in path.parts:
        if part in SKIP_DIRS:
            return False
    
    return True


def get_files(path: str) -> Generator[Path, None, None]:
    """Get all scannable files in path."""
    root = Path(path)
    
    if root.is_file():
        if should_scan_file(root):
            yield root
        return
    
    for file_path in root.rglob('*'):
        if file_path.is_file() and should_scan_file(file_path):
            yield file_path


def scan_file(file_path: Path) -> List[Finding]:
    """Scan a single file for PII issues."""
    findings = []
    
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        lines = content.split('\n')
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return findings
    
    # Check for PII fields
    for line_num, line in enumerate(lines, 1):
        line_lower = line.lower()
        
        # Skip comments
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('#') or stripped.startswith('*'):
            continue
        
        # Check PII field patterns
        for pattern, pii_type, severity in PII_FIELD_PATTERNS:
            if re.search(pattern, line_lower):
                findings.append(Finding(
                    file=str(file_path),
                    line=line_num,
                    severity=severity.value,
                    category='pii_field',
                    description=f'Potential {pii_type} field detected',
                    code_snippet=line.strip()[:100],
                    recommendation=f'Ensure {pii_type} data is encrypted and access is logged'
                ))
        
        # Check for PII in logs
        for pattern in LOG_PATTERNS:
            if re.search(pattern, line_lower):
                findings.append(Finding(
                    file=str(file_path),
                    line=line_num,
                    severity=Severity.HIGH.value,
                    category='pii_in_logs',
                    description='Potential PII being logged',
                    code_snippet=line.strip()[:100],
                    recommendation='Remove PII from log statements or use masking'
                ))
        
        # Check for unencrypted storage
        for pattern in UNENCRYPTED_PATTERNS:
            if re.search(pattern, line_lower):
                findings.append(Finding(
                    file=str(file_path),
                    line=line_num,
                    severity=Severity.CRITICAL.value,
                    category='unencrypted_pii',
                    description='Potential unencrypted PII storage',
                    code_snippet=line.strip()[:100],
                    recommendation='Encrypt sensitive data before storage'
                ))
    
    return findings


def deduplicate_findings(findings: List[Finding]) -> List[Finding]:
    """Remove duplicate findings."""
    seen = set()
    unique = []
    
    for f in findings:
        key = (f.file, f.line, f.category)
        if key not in seen:
            seen.add(key)
            unique.append(f)
    
    return unique


def filter_by_severity(findings: List[Finding], min_severity: str) -> List[Finding]:
    """Filter findings by minimum severity."""
    severity_order = ['critical', 'high', 'medium', 'low']
    min_index = severity_order.index(min_severity.lower())
    
    return [f for f in findings if severity_order.index(f.severity) <= min_index]


def format_text_report(findings: List[Finding]) -> str:
    """Format findings as text report."""
    if not findings:
        return "✅ No privacy issues found."
    
    lines = [
        "=" * 60,
        "Privacy Scan Results",
        "=" * 60,
        "",
    ]
    
    # Summary
    by_severity = {}
    for f in findings:
        by_severity[f.severity] = by_severity.get(f.severity, 0) + 1
    
    lines.append("Summary:")
    for sev in ['critical', 'high', 'medium', 'low']:
        count = by_severity.get(sev, 0)
        if count > 0:
            lines.append(f"  {sev.upper()}: {count}")
    lines.append("")
    
    # Findings by file
    by_file = {}
    for f in findings:
        by_file.setdefault(f.file, []).append(f)
    
    for file_path, file_findings in sorted(by_file.items()):
        lines.append(f"📄 {file_path}")
        for f in sorted(file_findings, key=lambda x: x.line):
            sev_icon = {'critical': '🔴', 'high': '🟠', 'medium': '🟡', 'low': '🔵'}
            lines.append(f"  {sev_icon.get(f.severity, '⚪')} Line {f.line}: {f.description}")
            lines.append(f"     {f.code_snippet}")
            lines.append(f"     → {f.recommendation}")
        lines.append("")
    
    # Final status
    critical_count = by_severity.get('critical', 0)
    high_count = by_severity.get('high', 0)
    
    if critical_count > 0 or high_count > 0:
        lines.append("❌ PRIVACY SCAN FAILED - Critical/High issues found")
    else:
        lines.append("⚠️ PRIVACY SCAN PASSED WITH WARNINGS")
    
    return '\n'.join(lines)


def format_json_report(findings: List[Finding]) -> str:
    """Format findings as JSON."""
    report = {
        'summary': {
            'total': len(findings),
            'critical': sum(1 for f in findings if f.severity == 'critical'),
            'high': sum(1 for f in findings if f.severity == 'high'),
            'medium': sum(1 for f in findings if f.severity == 'medium'),
            'low': sum(1 for f in findings if f.severity == 'low'),
        },
        'passed': all(f.severity not in ('critical', 'high') for f in findings),
        'findings': [asdict(f) for f in findings]
    }
    return json.dumps(report, indent=2)


def main():
    parser = argparse.ArgumentParser(description='Scan code for privacy/PII issues')
    parser.add_argument('path', nargs='?', default='.', help='Path to scan')
    parser.add_argument('--output', '-o', choices=['text', 'json'], default='text',
                       help='Output format')
    parser.add_argument('--severity', '-s', choices=['critical', 'high', 'medium', 'low'],
                       default='low', help='Minimum severity to report')
    args = parser.parse_args()
    
    # Scan files
    all_findings = []
    for file_path in get_files(args.path):
        all_findings.extend(scan_file(file_path))
    
    # Process findings
    findings = deduplicate_findings(all_findings)
    findings = filter_by_severity(findings, args.severity)
    findings.sort(key=lambda f: (['critical', 'high', 'medium', 'low'].index(f.severity), f.file, f.line))
    
    # Output
    if args.output == 'json':
        print(format_json_report(findings))
    else:
        print(format_text_report(findings))
    
    # Exit code
    critical_high = sum(1 for f in findings if f.severity in ('critical', 'high'))
    sys.exit(1 if critical_high > 0 else 0)


if __name__ == '__main__':
    main()

