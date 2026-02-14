# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-14

### Added

- 14 governance skills for Cursor IDE
  - Security Gate - pre-deployment vulnerability scanning
  - Human Approval - pauses AI for significant decisions
  - Code Quality - enforces linting, complexity limits, formatting
  - Privacy Guard - GDPR/CCPA compliance checking
  - Accessibility - WCAG 2.1 Level AA enforcement
  - Documentation - ADR, changelog, and API doc generation
  - Testing Standards - coverage requirements and test quality
  - Licence Compliance - dependency licence validation
  - Pre-Release - unified go/no-go release gate
  - Test Plan - PRD-to-test-plan generation with traceability
  - Browser Testing - E2E testing with Cursor @Browser tools
  - Test Automation - Playwright/Cypress test suite generation
  - Dependency Scanning - vulnerability and supply chain checks
  - Secrets Management - credential leak prevention and rotation
- `.cursorrules` configuration for automatic governance activation
- `governance.yaml` project configuration template
- 7 scanning and setup scripts (Bash, PowerShell, Python, Node.js)
- 7 document templates (ADR, changelog, HITL decision, PRD, PIA, security exception, test plan)
- Next.js + Vercel + Neon setup guide
- Testing workflow guide
- GitHub Actions workflow template
