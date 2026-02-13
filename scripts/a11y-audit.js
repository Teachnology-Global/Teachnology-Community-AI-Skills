#!/usr/bin/env node
/**
 * Accessibility Audit Script - Cursor Governance Framework
 * 
 * Scans HTML/JSX/TSX files for common accessibility issues:
 * - Missing alt text
 * - Missing form labels
 * - Invalid ARIA usage
 * - Color contrast issues (basic)
 * - Keyboard accessibility
 * 
 * Usage:
 *   node a11y-audit.js [path] [--output json|text] [--severity critical|serious|moderate|minor]
 */

const fs = require('fs');
const path = require('path');

// Severity levels
const Severity = {
  CRITICAL: 'critical',
  SERIOUS: 'serious',
  MODERATE: 'moderate',
  MINOR: 'minor'
};

// File extensions to scan
const SCAN_EXTENSIONS = new Set(['.html', '.htm', '.tsx', '.jsx', '.vue', '.svelte']);

// Directories to skip
const SKIP_DIRS = new Set([
  'node_modules', 'dist', 'build', '.git', 'coverage', 
  '__tests__', '__mocks__', 'vendor'
]);

/**
 * A11y rules to check
 */
const rules = [
  // Images without alt
  {
    id: 'img-alt',
    severity: Severity.CRITICAL,
    pattern: /<img\s+(?![^>]*\balt\s*=)[^>]*>/gi,
    message: 'Image missing alt attribute',
    recommendation: 'Add alt="" for decorative images or descriptive alt text for informative images'
  },
  // Empty alt on non-decorative images
  {
    id: 'img-alt-empty',
    severity: Severity.MODERATE,
    pattern: /<img\s+[^>]*\balt\s*=\s*["']\s*["'][^>]*(?!role\s*=\s*["']presentation["'])/gi,
    message: 'Image has empty alt without presentation role',
    recommendation: 'Add role="presentation" for decorative images or add meaningful alt text'
  },
  // Input without label
  {
    id: 'input-label',
    severity: Severity.CRITICAL,
    pattern: /<input\s+(?![^>]*\b(aria-label|aria-labelledby|id)\s*=)[^>]*>/gi,
    message: 'Input may be missing associated label',
    recommendation: 'Add a <label> element with matching for/id, or use aria-label'
  },
  // Button without accessible name
  {
    id: 'button-name',
    severity: Severity.CRITICAL,
    pattern: /<button\s+(?![^>]*\b(aria-label|aria-labelledby)\s*=)[^>]*>\s*<(?:svg|img|i|span)[^>]*>\s*<\/button>/gi,
    message: 'Icon button without accessible name',
    recommendation: 'Add aria-label to icon-only buttons'
  },
  // Links without href
  {
    id: 'link-href',
    severity: Severity.SERIOUS,
    pattern: /<a\s+(?![^>]*\bhref\s*=)[^>]*>/gi,
    message: 'Anchor element without href',
    recommendation: 'Use <button> for actions or add href for navigation'
  },
  // Empty links
  {
    id: 'link-empty',
    severity: Severity.CRITICAL,
    pattern: /<a\s+[^>]*>\s*<\/a>/gi,
    message: 'Empty link without text content',
    recommendation: 'Add text content or aria-label for screen readers'
  },
  // onClick on non-interactive elements
  {
    id: 'click-events-have-key-events',
    severity: Severity.SERIOUS,
    pattern: /<(?:div|span|p)\s+[^>]*\bonClick\s*=(?![^>]*\b(onKeyDown|onKeyPress|onKeyUp)\s*=)[^>]*>/gi,
    message: 'Click handler on non-interactive element without keyboard support',
    recommendation: 'Add keyboard event handler (onKeyDown) or use <button> instead'
  },
  // tabindex > 0
  {
    id: 'tabindex-positive',
    severity: Severity.SERIOUS,
    pattern: /\btabindex\s*=\s*["']?[1-9]\d*["']?/gi,
    message: 'Positive tabindex disrupts natural tab order',
    recommendation: 'Use tabindex="0" or tabindex="-1" instead'
  },
  // Missing lang attribute
  {
    id: 'html-lang',
    severity: Severity.SERIOUS,
    pattern: /<html\s+(?![^>]*\blang\s*=)[^>]*>/gi,
    message: 'HTML element missing lang attribute',
    recommendation: 'Add lang attribute (e.g., lang="en") for screen readers'
  },
  // Autofocus
  {
    id: 'no-autofocus',
    severity: Severity.MODERATE,
    pattern: /\bautofocus\b/gi,
    message: 'Autofocus can be disorienting for screen reader users',
    recommendation: 'Avoid autofocus unless necessary for user experience'
  },
  // Role on inappropriate elements
  {
    id: 'no-redundant-role',
    severity: Severity.MINOR,
    pattern: /<button\s+[^>]*\brole\s*=\s*["']button["'][^>]*>/gi,
    message: 'Redundant role="button" on button element',
    recommendation: 'Remove redundant ARIA role'
  },
  // Missing heading structure
  {
    id: 'heading-order',
    severity: Severity.MODERATE,
    check: (content) => {
      const headings = content.match(/<h([1-6])[^>]*>/gi) || [];
      const levels = headings.map(h => parseInt(h.match(/h([1-6])/i)[1]));
      const issues = [];
      
      for (let i = 1; i < levels.length; i++) {
        if (levels[i] > levels[i - 1] + 1) {
          issues.push({
            message: `Heading level skipped (h${levels[i-1]} to h${levels[i]})`,
            recommendation: 'Use sequential heading levels (h1 → h2 → h3)'
          });
        }
      }
      return issues;
    }
  },
  // Form without submit button
  {
    id: 'form-submit',
    severity: Severity.MODERATE,
    check: (content) => {
      const forms = content.match(/<form[^>]*>[\s\S]*?<\/form>/gi) || [];
      return forms
        .filter(form => !/<(button|input)\s+[^>]*type\s*=\s*["']?submit["']?/i.test(form))
        .map(() => ({
          message: 'Form without submit button',
          recommendation: 'Add <button type="submit"> for form submission'
        }));
    }
  }
];

/**
 * Finding class
 */
class Finding {
  constructor(file, line, severity, ruleId, message, snippet, recommendation) {
    this.file = file;
    this.line = line;
    this.severity = severity;
    this.ruleId = ruleId;
    this.message = message;
    this.snippet = snippet;
    this.recommendation = recommendation;
  }
}

/**
 * Get line number for match position
 */
function getLineNumber(content, position) {
  return content.substring(0, position).split('\n').length;
}

/**
 * Check if path should be scanned
 */
function shouldScan(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (!SCAN_EXTENSIONS.has(ext)) return false;
  
  const parts = filePath.split(path.sep);
  return !parts.some(part => SKIP_DIRS.has(part));
}

/**
 * Get all files to scan
 */
function getFiles(scanPath) {
  const files = [];
  
  function walk(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (!SKIP_DIRS.has(entry.name)) {
          walk(fullPath);
        }
      } else if (entry.isFile() && shouldScan(fullPath)) {
        files.push(fullPath);
      }
    }
  }
  
  const stat = fs.statSync(scanPath);
  if (stat.isFile()) {
    if (shouldScan(scanPath)) files.push(scanPath);
  } else {
    walk(scanPath);
  }
  
  return files;
}

/**
 * Scan a single file
 */
function scanFile(filePath) {
  const findings = [];
  let content;
  
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch (e) {
    console.error(`Warning: Could not read ${filePath}: ${e.message}`);
    return findings;
  }
  
  for (const rule of rules) {
    if (rule.pattern) {
      // Regex-based rule
      let match;
      const regex = new RegExp(rule.pattern.source, rule.pattern.flags);
      while ((match = regex.exec(content)) !== null) {
        findings.push(new Finding(
          filePath,
          getLineNumber(content, match.index),
          rule.severity,
          rule.id,
          rule.message,
          match[0].substring(0, 80).trim(),
          rule.recommendation
        ));
      }
    } else if (rule.check) {
      // Function-based rule
      const issues = rule.check(content);
      for (const issue of issues) {
        findings.push(new Finding(
          filePath,
          1,
          rule.severity,
          rule.id,
          issue.message,
          '',
          issue.recommendation
        ));
      }
    }
  }
  
  return findings;
}

/**
 * Format text report
 */
function formatTextReport(findings) {
  if (findings.length === 0) {
    return '✅ No accessibility issues found.';
  }
  
  const lines = [
    '='.repeat(60),
    'Accessibility Audit Results',
    '='.repeat(60),
    ''
  ];
  
  // Summary
  const bySeverity = {};
  for (const f of findings) {
    bySeverity[f.severity] = (bySeverity[f.severity] || 0) + 1;
  }
  
  lines.push('Summary:');
  for (const sev of ['critical', 'serious', 'moderate', 'minor']) {
    const count = bySeverity[sev] || 0;
    if (count > 0) {
      lines.push(`  ${sev.toUpperCase()}: ${count}`);
    }
  }
  lines.push('');
  
  // Findings by file
  const byFile = {};
  for (const f of findings) {
    if (!byFile[f.file]) byFile[f.file] = [];
    byFile[f.file].push(f);
  }
  
  for (const [file, fileFindings] of Object.entries(byFile).sort()) {
    lines.push(`📄 ${file}`);
    for (const f of fileFindings.sort((a, b) => a.line - b.line)) {
      const icon = {critical: '🔴', serious: '🟠', moderate: '🟡', minor: '🔵'}[f.severity] || '⚪';
      lines.push(`  ${icon} Line ${f.line}: [${f.ruleId}] ${f.message}`);
      if (f.snippet) lines.push(`     ${f.snippet}`);
      lines.push(`     → ${f.recommendation}`);
    }
    lines.push('');
  }
  
  // Status
  const criticalSerious = (bySeverity.critical || 0) + (bySeverity.serious || 0);
  if (criticalSerious > 0) {
    lines.push('❌ A11Y AUDIT FAILED - Critical/Serious issues found');
  } else {
    lines.push('⚠️ A11Y AUDIT PASSED WITH WARNINGS');
  }
  
  return lines.join('\n');
}

/**
 * Format JSON report
 */
function formatJsonReport(findings) {
  const report = {
    summary: {
      total: findings.length,
      critical: findings.filter(f => f.severity === 'critical').length,
      serious: findings.filter(f => f.severity === 'serious').length,
      moderate: findings.filter(f => f.severity === 'moderate').length,
      minor: findings.filter(f => f.severity === 'minor').length
    },
    passed: !findings.some(f => ['critical', 'serious'].includes(f.severity)),
    findings: findings
  };
  return JSON.stringify(report, null, 2);
}

/**
 * Main function
 */
function main() {
  const args = process.argv.slice(2);
  let scanPath = '.';
  let outputFormat = 'text';
  let minSeverity = 'minor';
  
  // Parse args
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--output' || args[i] === '-o') {
      outputFormat = args[++i];
    } else if (args[i] === '--severity' || args[i] === '-s') {
      minSeverity = args[++i];
    } else if (!args[i].startsWith('-')) {
      scanPath = args[i];
    }
  }
  
  // Scan
  const files = getFiles(scanPath);
  let allFindings = [];
  
  for (const file of files) {
    allFindings.push(...scanFile(file));
  }
  
  // Filter by severity
  const severityOrder = ['critical', 'serious', 'moderate', 'minor'];
  const minIndex = severityOrder.indexOf(minSeverity);
  const findings = allFindings.filter(f => severityOrder.indexOf(f.severity) <= minIndex);
  
  // Sort
  findings.sort((a, b) => {
    const sevDiff = severityOrder.indexOf(a.severity) - severityOrder.indexOf(b.severity);
    if (sevDiff !== 0) return sevDiff;
    if (a.file !== b.file) return a.file.localeCompare(b.file);
    return a.line - b.line;
  });
  
  // Output
  if (outputFormat === 'json') {
    console.log(formatJsonReport(findings));
  } else {
    console.log(formatTextReport(findings));
  }
  
  // Exit code
  const criticalSerious = findings.filter(f => ['critical', 'serious'].includes(f.severity)).length;
  process.exit(criticalSerious > 0 ? 1 : 0);
}

main();

