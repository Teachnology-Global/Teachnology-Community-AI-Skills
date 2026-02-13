#Requires -Version 5.1
<#
.SYNOPSIS
    Cursor Governance Framework - Project Initializer (Windows)

.DESCRIPTION
    Sets up the Cursor Governance Framework in your project.

.PARAMETER TargetPath
    Path to your project directory. Defaults to current directory.

.EXAMPLE
    .\init-project.ps1
    
.EXAMPLE
    .\init-project.ps1 -TargetPath "C:\Projects\MyApp"
#>

param(
    [string]$TargetPath = "."
)

$ErrorActionPreference = "Stop"

# Colors via Write-Host
function Write-Header {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║     Cursor Governance Framework - Project Setup           ║" -ForegroundColor Blue
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "Step $Step`: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ! $Message" -ForegroundColor Yellow
}

# Config
$RepoUrl = "https://github.com/ColossalCuck/Teachnology-Community-AI-Skills.git"
$TempDir = Join-Path $env:TEMP "governance-framework-$(Get-Random)"

Write-Header

# Resolve target path
$TargetPath = Resolve-Path $TargetPath -ErrorAction SilentlyContinue
if (-not $TargetPath) {
    Write-Host "Error: Directory does not exist" -ForegroundColor Red
    exit 1
}

Write-Host "Target directory: $TargetPath" -ForegroundColor Yellow
Write-Host ""

# Check for existing files
$SkillsPath = Join-Path $TargetPath ".cursor\skills"
if (Test-Path $SkillsPath) {
    Write-Host "Warning: .cursor\skills already exists." -ForegroundColor Yellow
    $response = Read-Host "Overwrite existing files? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Aborted."
        exit 0
    }
}

# Step 1: Clone framework
Write-Step "1/5" "Downloading framework..."
try {
    git clone --depth 1 $RepoUrl $TempDir 2>$null
    Write-Success "Downloaded framework"
}
catch {
    Write-Host "Failed to clone repository" -ForegroundColor Red
    exit 1
}

$FrameworkDir = Join-Path $TempDir "cursor-governance-skills"

# Step 2: Copy skills
Write-Step "2/5" "Copying skill files..."
$SkillsSource = Join-Path $FrameworkDir ".cursor\skills"
New-Item -ItemType Directory -Force -Path (Join-Path $TargetPath ".cursor\skills") | Out-Null
Copy-Item -Path "$SkillsSource\*" -Destination (Join-Path $TargetPath ".cursor\skills") -Force
Write-Success "Copied 14 governance skills"

# Step 3: Copy configuration
Write-Step "3/5" "Copying configuration..."
Copy-Item -Path (Join-Path $FrameworkDir ".cursorrules") -Destination $TargetPath -Force
Write-Success "Created .cursorrules"

$GovernanceYaml = Join-Path $TargetPath "governance.yaml"
if (-not (Test-Path $GovernanceYaml)) {
    Copy-Item -Path (Join-Path $FrameworkDir "governance.yaml") -Destination $TargetPath
    Write-Success "Created governance.yaml"
}
else {
    Write-Warning "governance.yaml already exists, skipping"
}

# Step 4: Copy scripts and templates
Write-Step "4/5" "Copying scripts and templates..."

$ScriptsDir = Join-Path $TargetPath "scripts\governance"
New-Item -ItemType Directory -Force -Path $ScriptsDir | Out-Null
Copy-Item -Path (Join-Path $FrameworkDir "scripts\*") -Destination $ScriptsDir -Force -ErrorAction SilentlyContinue
Write-Success "Copied governance scripts"

$TemplatesDir = Join-Path $TargetPath "docs\templates"
New-Item -ItemType Directory -Force -Path $TemplatesDir | Out-Null
Copy-Item -Path (Join-Path $FrameworkDir "templates\*") -Destination $TemplatesDir -Force -ErrorAction SilentlyContinue
Write-Success "Copied document templates"

$AdrDir = Join-Path $TargetPath "docs\adr"
New-Item -ItemType Directory -Force -Path $AdrDir | Out-Null
$AdrReadme = Join-Path $AdrDir "README.md"
if (-not (Test-Path $AdrReadme)) {
    @"
# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for this project.

## Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| | | | |

## Creating a New ADR

Use the template at ``../templates/adr.md`` or ask the AI:
```
"Create an ADR for [your decision]"
```
"@ | Out-File -FilePath $AdrReadme -Encoding UTF8
    Write-Success "Created docs\adr\README.md"
}

# Create CHANGELOG if doesn't exist
$ChangelogPath = Join-Path $TargetPath "CHANGELOG.md"
if (-not (Test-Path $ChangelogPath)) {
    @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Cursor Governance Framework integration

"@ | Out-File -FilePath $ChangelogPath -Encoding UTF8
    Write-Success "Created CHANGELOG.md"
}

# Step 5: Detect project type
Write-Step "5/5" "Detecting project type..."

$PackageJson = Join-Path $TargetPath "package.json"
if (Test-Path $PackageJson) {
    $content = Get-Content $PackageJson -Raw
    if ($content -match '"next"') {
        Write-Success "Detected Next.js project"
    }
    elseif ($content -match '"react"') {
        Write-Success "Detected React project"
    }
    elseif ($content -match '"vue"') {
        Write-Success "Detected Vue project"
    }
    else {
        Write-Success "Detected Node.js project"
    }
}
elseif ((Test-Path (Join-Path $TargetPath "requirements.txt")) -or (Test-Path (Join-Path $TargetPath "pyproject.toml"))) {
    Write-Success "Detected Python project"
}
elseif (Test-Path (Join-Path $TargetPath "go.mod")) {
    Write-Success "Detected Go project"
}

# Cleanup
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Done!
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Setup Complete! 🎉                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor White
Write-Host "  .cursor\skills\     - 14 governance skills" -ForegroundColor Blue
Write-Host "  .cursorrules        - Cursor AI rules" -ForegroundColor Blue
Write-Host "  governance.yaml     - Configuration" -ForegroundColor Blue
Write-Host "  scripts\governance\ - Scanning scripts" -ForegroundColor Blue
Write-Host "  docs\templates\     - Document templates" -ForegroundColor Blue
Write-Host "  docs\adr\           - ADR directory" -ForegroundColor Blue
Write-Host "  CHANGELOG.md        - Changelog" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review and customize governance.yaml"
Write-Host "  2. Open project in Cursor IDE"
Write-Host "  3. Start coding - skills activate automatically!"
Write-Host ""

