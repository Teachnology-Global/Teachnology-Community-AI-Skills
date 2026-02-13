#!/bin/bash
#
# Cursor Governance Framework - Project Initializer
# 
# Usage: 
#   curl -fsSL https://raw.githubusercontent.com/ColossalCuck/Teachnology-Community-AI-Skills/main/cursor-governance-skills/scripts/init-project.sh | bash
#
# Or locally:
#   ./init-project.sh /path/to/your/project
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Framework repo
REPO_URL="https://github.com/ColossalCuck/Teachnology-Community-AI-Skills.git"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Cursor Governance Framework - Project Setup           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Determine target directory
if [ -n "$1" ]; then
    TARGET_DIR="$1"
else
    TARGET_DIR="."
fi

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory $TARGET_DIR does not exist${NC}"
    exit 1
fi

cd "$TARGET_DIR"
TARGET_DIR=$(pwd)

echo -e "${YELLOW}Target directory: $TARGET_DIR${NC}"
echo ""

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Warning: Not a git repository. Some features may not work.${NC}"
fi

# Check for existing governance files
if [ -d ".cursor/skills" ]; then
    echo -e "${YELLOW}Warning: .cursor/skills already exists.${NC}"
    read -p "Overwrite existing files? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo -e "${BLUE}Step 1/5: Downloading framework...${NC}"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR/framework" 2>/dev/null || {
    echo -e "${RED}Failed to clone repository${NC}"
    exit 1
}

FRAMEWORK_DIR="$TEMP_DIR/framework/cursor-governance-skills"

echo -e "${BLUE}Step 2/5: Copying skill files...${NC}"
mkdir -p .cursor/skills
cp -r "$FRAMEWORK_DIR/.cursor/skills/"* .cursor/skills/
echo -e "${GREEN}  ✓ Copied 14 governance skills${NC}"

echo -e "${BLUE}Step 3/5: Copying configuration...${NC}"
cp "$FRAMEWORK_DIR/.cursorrules" .cursorrules
echo -e "${GREEN}  ✓ Created .cursorrules${NC}"

if [ ! -f "governance.yaml" ]; then
    cp "$FRAMEWORK_DIR/governance.yaml" governance.yaml
    echo -e "${GREEN}  ✓ Created governance.yaml${NC}"
else
    echo -e "${YELLOW}  ! governance.yaml already exists, skipping${NC}"
fi

echo -e "${BLUE}Step 4/5: Copying scripts and templates...${NC}"
mkdir -p scripts/governance
cp "$FRAMEWORK_DIR/scripts/"* scripts/governance/ 2>/dev/null || true
echo -e "${GREEN}  ✓ Copied governance scripts${NC}"

mkdir -p docs/templates
cp "$FRAMEWORK_DIR/templates/"* docs/templates/ 2>/dev/null || true
echo -e "${GREEN}  ✓ Copied document templates${NC}"

mkdir -p docs/adr
if [ ! -f "docs/adr/README.md" ]; then
    cat > docs/adr/README.md << 'EOF'
# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for this project.

## Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| | | | |

## Creating a New ADR

Use the template at `../templates/adr.md` or ask the AI:
```
"Create an ADR for [your decision]"
```
EOF
    echo -e "${GREEN}  ✓ Created docs/adr/README.md${NC}"
fi

# Create CHANGELOG if doesn't exist
if [ ! -f "CHANGELOG.md" ]; then
    cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Cursor Governance Framework integration

EOF
    echo -e "${GREEN}  ✓ Created CHANGELOG.md${NC}"
fi

echo -e "${BLUE}Step 5/5: Detecting project type...${NC}"

# Detect project type and customize governance.yaml
if [ -f "package.json" ]; then
    if grep -q '"next"' package.json 2>/dev/null; then
        echo -e "${GREEN}  ✓ Detected Next.js project${NC}"
        # Update project type in governance.yaml
        sed -i.bak 's/type: web/type: nextjs/' governance.yaml 2>/dev/null || true
    elif grep -q '"react"' package.json 2>/dev/null; then
        echo -e "${GREEN}  ✓ Detected React project${NC}"
    elif grep -q '"vue"' package.json 2>/dev/null; then
        echo -e "${GREEN}  ✓ Detected Vue project${NC}"
    else
        echo -e "${GREEN}  ✓ Detected Node.js project${NC}"
    fi
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo -e "${GREEN}  ✓ Detected Python project${NC}"
    sed -i.bak 's/type: web/type: python/' governance.yaml 2>/dev/null || true
elif [ -f "go.mod" ]; then
    echo -e "${GREEN}  ✓ Detected Go project${NC}"
    sed -i.bak 's/type: web/type: go/' governance.yaml 2>/dev/null || true
fi

# Cleanup
rm -rf "$TEMP_DIR"
rm -f governance.yaml.bak 2>/dev/null

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete! 🎉                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Files created:"
echo -e "  ${BLUE}.cursor/skills/${NC}     - 14 governance skills"
echo -e "  ${BLUE}.cursorrules${NC}        - Cursor AI rules"
echo -e "  ${BLUE}governance.yaml${NC}     - Configuration"
echo -e "  ${BLUE}scripts/governance/${NC} - Scanning scripts"
echo -e "  ${BLUE}docs/templates/${NC}     - Document templates"
echo -e "  ${BLUE}docs/adr/${NC}           - ADR directory"
echo -e "  ${BLUE}CHANGELOG.md${NC}        - Changelog"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review and customize governance.yaml"
echo "  2. Open project in Cursor IDE"
echo "  3. Start coding - skills activate automatically!"
echo ""
echo -e "For Next.js + Vercel + Neon setup, see:"
echo -e "  ${BLUE}docs/templates/nextjs-vercel-neon-setup.md${NC}"
echo ""

